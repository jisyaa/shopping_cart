from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from db import redis_client

router = APIRouter()

class CartItem(BaseModel):
    user_id: int
    product_id: int
    quantity: int

def get_cart_key(user_id: int) -> str:
    return f"cart:user:{user_id}"

# Get cart
@router.get("/cart")
async def get_cart(user_id: int = Query(...)):
    key = get_cart_key(user_id)
    cart = await redis_client.hgetall(key)
    return cart

# Add to cart
@router.post("/cart")
async def add_to_cart(item: CartItem):
    key = get_cart_key(item.user_id)
    await redis_client.hincrby(key, item.product_id, item.quantity)
    return {"message": "Item ditambahkan ke keranjang"}

# Update item quantity
@router.put("/cart")
async def update_cart(item: CartItem):
    key = get_cart_key(item.user_id)
    if item.quantity <= 0:
        await redis_client.hdel(key, item.product_id)
        return {"message": "Item dihapus karena quantity <= 0"}
    await redis_client.hset(key, item.product_id, item.quantity)
    return {"message": "Jumlah item diperbarui"}

# Remove item
@router.delete("/cart/{product_id}")
async def remove_item(product_id: int, user_id: int = Query(...)):
    key = get_cart_key(user_id)
    await redis_client.hdel(key, product_id)
    return {"message": "Item dihapus dari keranjang"}

# Clear cart
@router.delete("/cart")
async def clear_cart(user_id: int = Query(...)):
    key = get_cart_key(user_id)
    await redis_client.delete(key)
    return {"message": "Keranjang dikosongkan"}
