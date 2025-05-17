from fastapi import FastAPI
from routes import user, product, cart, order, admin

app = FastAPI(title="E-Commerce API - Elektronik")

app.include_router(user.router, tags=["User"])
app.include_router(product.router, tags=["Product"])
app.include_router(cart.router, tags=["Cart"])
app.include_router(order.router, tags=["Order"])
app.include_router(admin.router, tags=["Admin"])

@app.get("/")
def root():
    return {"message": "Selamat datang di API E-Commerce Elektronik"}
