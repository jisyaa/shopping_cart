import redis.asyncio as redis
import mysql.connector

# Redis connection
redis_client = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

# MySQL connection
mysql = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database="shopping_cart"
)

# Cursor bisa digunakan dalam setiap route jika perlu
mysql_cursor = mysql.cursor(dictionary=True)
