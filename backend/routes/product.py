from fastapi import APIRouter, HTTPException, Query
from db import mysql_cursor

router = APIRouter()

# Get all products
@router.get("/products")
def get_all_products():
    mysql_cursor.execute("SELECT * FROM products")
    products = mysql_cursor.fetchall()
    return products

# Get product by ID
@router.get("/products/{product_id}")
def get_product(product_id: int):
    mysql_cursor.execute("SELECT * FROM products WHERE id = %s", (product_id,))
    product = mysql_cursor.fetchone()
    if not product:
        raise HTTPException(status_code=404, detail="Produk tidak ditemukan")
    return product

# Get all categories
@router.get("/categories")
def get_categories():
    mysql_cursor.execute("SELECT DISTINCT category_id FROM products")
    categories = [row['category_id'] for row in mysql_cursor.fetchall()]
    return categories

@router.get("/products/category/{category_id}")
def get_products_by_category(category_id: int):
    mysql_cursor.execute("SELECT * FROM products WHERE category_id = %s", (category_id,))
    result = mysql_cursor.fetchall()
    return result

# Search products by keyword
@router.get("/search")
def search_products(q: str = Query(..., min_length=1)):
    query = "SELECT * FROM products WHERE name LIKE %s"
    like_pattern = f"%{q}%"
    mysql_cursor.execute(query, (like_pattern,))
    results = mysql_cursor.fetchall()
    return results