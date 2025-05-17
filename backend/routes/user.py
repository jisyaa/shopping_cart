from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, EmailStr
from db import mysql, mysql_cursor
from typing import Optional

router = APIRouter()

class UserRegister(BaseModel):
    username: str
    email: EmailStr
    password: str
    full_name: str
    address: str
    phone: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserProfile(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None
    full_name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None

# Register
@router.post("/register")
def register(user: UserRegister):
    # Cek apakah email sudah terdaftar
    mysql_cursor.execute("SELECT * FROM users WHERE email=%s", (user.email,))
    if mysql_cursor.fetchone():
        raise HTTPException(status_code=400, detail="Email sudah terdaftar")

    # Insert user baru
    mysql_cursor.execute(
        """
        INSERT INTO users (username, email, password, full_name, address, phone)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (user.username, user.email, user.password, user.full_name, user.address, user.phone)
    )
    mysql.commit()

    return {"message": "Registrasi berhasil"}

# Login
# @router.post("/login")
# def login(user: UserLogin):
#     mysql_cursor.execute("SELECT * FROM users WHERE email=%s AND password=%s", (user.email, user.password))
#     user_data = mysql_cursor.fetchone()
#     if not user_data:
#         raise HTTPException(status_code=401, detail="Email atau password salah")
#     return {"message": "Login berhasil", "user": user_data}
@router.post("/login")
def login(user: UserLogin):
    mysql_cursor.execute(
        "SELECT * FROM users WHERE email=%s AND password=%s",
        (user.email, user.password)
    )
    user_data = mysql_cursor.fetchone()
    if not user_data:
        raise HTTPException(status_code=401, detail="Email atau password salah")
    
    return {
        "status": "success",
        "message": "Login berhasil",
        "user": user_data
    }

# Get Profile
@router.get("/profile")
def get_profile(user_id: int = Query(..., alias="id")):
    mysql_cursor.execute("SELECT * FROM users WHERE id=%s", (user_id,))
    user_data = mysql_cursor.fetchone()
    if not user_data:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    return user_data

# Update Profile
@router.put("/profile")
def update_profile(id: int = Query(...), profile: UserProfile = Depends()):
    fields = []
    values = []

    for key, value in profile.dict(exclude_none=True).items():
        fields.append(f"{key} = %s")
        values.append(value)

    if not fields:
        raise HTTPException(status_code=400, detail="Tidak ada data yang diubah")

    values.append(id)
    query = f"UPDATE users SET {', '.join(fields)} WHERE id = %s"
    mysql_cursor.execute(query, values)
    mysql.commit()

    return {"message": "Profil berhasil diperbarui"}
