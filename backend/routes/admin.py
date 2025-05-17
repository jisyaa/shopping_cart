from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel
from db import mysql, mysql_cursor
from typing import Optional

router = APIRouter()

class ProductInput(BaseModel):
    name: str
    description: str
    price: int
    stock: int
    category_id: str
    image_url: str

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    stock: Optional[int] = None
    category_id: Optional[int] = None
    image_url: Optional[str] = None

# Add product
@router.post("/products")
def add_product(product: ProductInput):
    mysql_cursor.execute(
        "INSERT INTO products (name, description, price, stock, category_id, image_url) VALUES (%s, %s, %s, %s, %s, %s)",
        (product.name, product.description, product.price, product.stock, product.category_id, product.image_url)
    )
    mysql.commit()
    return {"message": "Produk berhasil ditambahkan"}

# Update product
@router.put("/products/{product_id}")
def update_product(id: int = Query(...), profile: ProductUpdate = Depends()):
    fields = []
    values = []

    for key, value in profile.dict(exclude_none=True).items():
        fields.append(f"{key} = %s")
        values.append(value)

    if not fields:
        raise HTTPException(status_code=400, detail="Tidak ada data yang diubah")

    values.append(id)
    query = f"UPDATE products SET {', '.join(fields)} WHERE id = %s"
    mysql_cursor.execute(query, values)
    mysql.commit()

    return {"message": "Produk berhasil diperbarui"}


# Delete product
@router.delete("/products/{product_id}")
def delete_product(product_id: int):
    mysql_cursor.execute("DELETE FROM products WHERE id = %s", (product_id,))
    mysql.commit()
    return {"message": "Produk berhasil dihapus"}
