from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from db import redis_client, mysql, mysql_cursor
import datetime
from typing import List

router = APIRouter()

class CheckoutRequest(BaseModel):
    user_id: int
    product_ids: List[int]

# Checkout endpoint
@router.post("/checkout")
async def checkout(data: CheckoutRequest):
    cart_key = f"cart:user:{data.user_id}"
    cart = await redis_client.hgetall(cart_key)

    if not cart:
        raise HTTPException(status_code=400, detail="Keranjang kosong")

    total_price = 0
    order_items = []

    for product_id in data.product_ids:
        product_id_str = str(product_id)
        if product_id_str not in cart:
            raise HTTPException(
                status_code=400, 
                detail=f"Produk ID {product_id} tidak ada di keranjang"
            )

        quantity = int(cart[product_id_str])

        mysql_cursor.execute("SELECT * FROM products WHERE id = %s", (product_id,))
        product = mysql_cursor.fetchone()
        if not product or product['stock'] < quantity:
            raise HTTPException(status_code=400, detail=f"Stok tidak cukup untuk produk ID {product_id}")

        subtotal = product['price'] * quantity
        total_price += subtotal
        order_items.append((product_id, quantity, subtotal))

    mysql_cursor.execute(
        "INSERT INTO orders (user_id, total_price) VALUES (%s, %s)",
        (data.user_id, total_price)
    )
    mysql.commit()
    order_id = mysql_cursor.lastrowid

    for product_id, quantity, subtotal in order_items:
        mysql_cursor.execute(
            "INSERT INTO order_items (order_id, product_id, quantity, subtotal) VALUES (%s, %s, %s, %s)",
            (order_id, product_id, quantity, subtotal)
        )
        mysql_cursor.execute(
            "UPDATE products SET stock = stock - %s WHERE id = %s",
            (quantity, product_id)
        )

    mysql.commit()

    # Hapus item yang dibeli saja dari keranjang
    await redis_client.hdel(cart_key, *map(str, data.product_ids))

    return {
        "message": "Checkout berhasil",
        "order_id": order_id,
        "items_checked_out": data.product_ids
    }

# # Get all orders by user
# @router.get("/orders")
# def get_orders(user_id: int = Query(...)):
#     mysql_cursor.execute("SELECT * FROM orders JOIN order_details  WHERE user_id = %s", (user_id,))
#     return mysql_cursor.fetchall()

@router.get("/orders")
def get_orders(user_id: int = Query(...)):
    mysql_cursor.execute("""
        SELECT 
            o.id AS order_id,
            o.user_id,
            o.total_price,
            o.status,
            p.id AS product_id,
            p.name AS product_name,
            p.image_url,
            oi.quantity,
            oi.subtotal
        FROM orders o
        JOIN order_items oi ON o.id = oi.order_id
        JOIN products p ON oi.product_id = p.id
        WHERE o.user_id = %s
        ORDER BY o.id DESC
    """, (user_id,))
    
    rows = mysql_cursor.fetchall()

    # Struktur hasil: {order_id: {..., items: [...]}}
    orders = {}
    for row in rows:
        oid = row["order_id"]
        if oid not in orders:
            orders[oid] = {
                "order_id": oid,
                "user_id": row["user_id"],
                "total_price": row["total_price"],
                "status": row["status"],
                "items": []
            }

        orders[oid]["items"].append({
            "product_id": row["product_id"],
            "product_name": row["product_name"],
            "image_url": row["image_url"],
            "quantity": row["quantity"],
            "subtotal": row["subtotal"],
        })

    return list(orders.values())


# Get order details
@router.get("/orders/{order_id}")
def get_order_detail(order_id: int):
    # Ambil order + items sekaligus lewat JOIN
    mysql_cursor.execute("""
        SELECT 
            o.id            AS order_id,
            o.user_id       AS user_id,
            o.total_price   AS total_price,
            o.status        AS status,
            p.id            AS product_id,
            p.name          AS product_name,
            p.image_url     AS image_url,
            oi.quantity     AS quantity,
            oi.subtotal     AS subtotal
        FROM orders o
        JOIN order_items oi ON o.id = oi.order_id
        JOIN products p    ON oi.product_id = p.id
        WHERE o.id = %s
    """, (order_id,))

    rows = mysql_cursor.fetchall()
    if not rows:
        raise HTTPException(status_code=404, detail="Pesanan tidak ditemukan")

    # Bangun struktur detail pesanan
    final_order = {
        "order_id":    rows[0]["order_id"],
        "user_id":     rows[0]["user_id"],
        "total_price": rows[0]["total_price"],
        "status":      rows[0]["status"],
        "items":       []
    }

    for row in rows:
        final_order["items"].append({
            "product_id":   row["product_id"],
            "product_name": row["product_name"],
            "image_url":    row["image_url"],
            "quantity":     row["quantity"],
            "subtotal":     row["subtotal"],
        })

    return final_order
