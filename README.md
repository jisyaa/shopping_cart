# API E-Commerce

Ini adalah API e-commerce yang dibangun menggunakan **Python**, **MySQL**, dan **Redis**. API ini menyimpan data produk dan pengguna di database MySQL, sementara data keranjang belanja disimpan di Redis untuk akses yang cepat dan efisien yang dimana python, mysql, dan redis berjalan di system windows.

## Fitur
- **Manajemen Produk**: Menyimpan dan mengelola detail produk di MySQL.
- **Manajemen Pengguna**: Menyimpan dan mengelola informasi pengguna di MySQL.
- **Keranjang Belanja**: Mengelola keranjang belanja pengguna menggunakan Redis untuk operasi baca/tulis yang cepat.
- **Checkout**: Memproses pembelian hanya pada produk tertentu yang dipilih dari keranjang Redis.
- **API RESTful**: Menyediakan endpoint untuk menambah/menghapus produk dari keranjang, mengambil data keranjang, dan mengosongkan keranjang.

## Teknologi yang Digunakan
- **Backend**: Python
- **Database**:
  - **MySQL**: Menyimpan data produk dan pengguna.
  - **Redis**: Menyimpan data keranjang belanja.
  - Pustaka Python standar lainnya (`fastapi`, `uvicorn`, `sqlalchemy`, `redis`, `pydantic`, `python-dotenv`, `mysql-connector-python`, `pydantic[email]`).

## Instalasi
1. **Kloning repositori**:
   ```bash
   git clone https://github.com/jisyaa/shopping_cart
   cd e-commerce
   ```

2. **Instal dependensi**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Jalankan server Redis**:
   ### Pastikan Redis berjalan di sistem:
   ```bash
   cd redis
   .\redis-server.exe
   ```

4. **Jalankan aplikasi**:
   ```bash
   uvicorn main:app --reload
   ```

4. **Buka API di browser**:
   - Klik link yang muncul saat menjalankan aplikasi 
   - Tambahkan /docs di belakang url 

## Kelompok
- Fitri Sakinah (2211081009)
- Iqlima Khairunnisa (2211082015)
- Jazila Valisya Luthfia (2211082016)
- Nurul Aulia (2211082023)
- Puti Hanifah Marsla (2211082024)
