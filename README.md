# Chinook Data Warehouse

Perancangan data warehouse dan data mart **Chinook Store** menggunakan Pentaho dan PostgreSQL untuk menganalisis penjualan musik global.

Proyek ini dikerjakan sebagai Mini Project Studi Independen (Celerates) oleh Kelompok 7, di bawah bimbingan mentor personal Ryan Firmansyah.

## Tim

Kelompok 7, S1 Sains Data:

- Muhammad Ramadhan Albaary Putra
- Muslim Fazlur Rohman
- Naufal Muzaki
- Eka Aliya
- Maria Agatha Metri Tetrajati

## Latar Belakang

Dataset Chinook Store dipilih karena menggambarkan sistem operasional toko musik digital yang lengkap: transaksi, pelanggan, staf, dan katalog lagu. Relasi antar tabelnya cocok untuk latihan pemodelan *star schema*, yaitu tabel-tabel yang awalnya terpisah digabung dan didenormalisasi menjadi tabel dimensi dan satu tabel fakta.

Pertanyaan bisnis yang ingin dijawab:

> Genre apa yang paling menghasilkan pendapatan, di negara mana, dan bagaimana perkembangannya dari tahun ke tahun?

## Tools

| Kebutuhan | Tools |
|---|---|
| ETL | Pentaho Data Integration (Spoon) |
| Database | PostgreSQL |
| Query dan pengecekan | DBeaver |
| Desain star schema | Draw.io |

## Alur Pengerjaan

![Pipeline alur pengerjaan proyek](<Team 7_Kak Ryan_Mini Project_Celerates_files/image1.jpg>)

1. **Eksplorasi data mentah.** Cek struktur 11 tabel, jumlah baris, nilai kosong, dan duplikasi.
2. **Staging.** Salinan tabel operasional dimuat otomatis ke database `staging_chinook`.
3. **Dimension.** Tabel dimensi dibentuk dan disimpan ke `dwh_chinook` pada schema `dimension`.
4. **Fact.** Tabel `fact_sales` dibangun dengan mengambil *surrogate key* dari tiap dimensi, lalu disimpan pada schema `fact_table`.
5. **Data mart.** Fakta digabung dengan dimensi dan diagregasi menjadi `dm_sales_genre_country`, lalu diekspor ke CSV.

## Struktur Database

| Database | Schema | Isi |
|---|---|---|
| `chinook` (sumber) | `public` | 11 tabel operasional Chinook |
| `staging_chinook` | `staging` | Salinan tabel operasional |
| `staging_chinook` | `log` | `staging_log` dan `log_table_entry` untuk mencatat pemrosesan |
| `dwh_chinook` | `dimension` | `dim_track`, `dim_customer`, `dim_date`, `dim_employee` |
| `dwh_chinook` | `fact_table` | `fact_sales` |
| `dwh_chinook` | `datamart` | `dm_sales_genre_country` |

## Struktur Folder

```
.
├── staging/        # job dan transformasi staging
├── dimension/      # transformasi tabel dimensi
├── fact_table/     # transformasi fact_sales
├── datamart/       # transformasi data mart dan hasil CSV
├── docs/           # laporan dan gambar pendukung
└── README.md
```

## Detail Implementasi

### Staging

- `tf_list_table.ktr` membaca daftar tabel sumber dari `information_schema.tables` (schema `public`), membandingkannya dengan `log.log_table_entry` lewat *Full Outer Join*, sehingga tabel yang sudah diproses dilewati otomatis.
- `tf_read_data.ktr` memindahkan data ke staging dengan *truncate table* dan *batch insert* (commit setiap 1.000 baris), sekaligus mencatat jumlah baris sumber ke `log.staging_log`.
- `execute_data.kjb` menjalankan pemuatan per tabel, menghitung jumlah baris target, lalu membandingkannya dengan sumber. Jika sama, status diisi `succes` (sesuai penulisan pada konfigurasi), jika beda diisi `to be evaluated`.
- `tf_tabel_masuk.ktr` mencatat tabel yang selesai ke `log.log_table_entry`.
- `main_staging.kjb` adalah job utama yang menjalankan `execute_data` untuk setiap tabel hasil `tf_list_table`.

### Star Schema

![Rancangan star schema](<Team 7_Kak Ryan_Mini Project_Celerates_files/image10.jpg>)

| Tabel | Keterangan | Penanganan perubahan |
|---|---|---|
| `dim_track` | Gabungan track, album, artist, genre, media_type. Durasi dikelompokkan menjadi Pendek (kurang dari 3 menit), Standar (3 sampai 5 menit), dan Epik (lebih dari 5 menit) | SCD Type 1 (Insert/Update, kunci `track_id`) |
| `dim_customer` | Profil pelanggan, nama digabung, `company` kosong diisi `No Company`, kode wilayah distandarkan | SCD Type 2 (Dimension Lookup/Update dengan `version`, `date_from`, `date_to`) |
| `dim_date` | Diturunkan dari `invoice_date`, berisi year, quarter, month, day, dan `day_type` (Weekday/Weekend). `sk_date` berformat YYYYMMDD | Tanggal unik dengan `SELECT DISTINCT` |
| `dim_employee` | Staf penjual, nama digabung menjadi `employee_name` | Table Output |
| `fact_sales` | `sk_track`, `sk_customer`, `sk_date`, `sk_employee`, `unit_price`, `quantity`, `amount`, dan `transaksi_id` | Truncate lalu load ulang |

### Data Mart

Tabel `dm_sales_genre_country` berisi agregasi per tahun, negara, dan genre.

| Kolom | Tipe | Isi |
|---|---|---|
| `year` | Integer | Tahun transaksi |
| `country` | Teks | Negara pelanggan |
| `genre_name` | Teks | Nama genre |
| `total_revenue` | Numerik | Total pendapatan |
| `total_units_sold` | Integer | Jumlah item terjual |
| `customer_count` | Integer | Jumlah pelanggan unik pada kombinasi tahun, negara, dan genre |
| `pct_of_country_revenue` | Numerik | Persentase genre dalam negara dan tahun yang sama |
| `revenue_rank` | Integer | Peringkat genre dalam negara dan tahun yang sama |

## Hasil dan Insight

Data mart berisi **432 baris** yang mencakup 24 negara, 24 genre, dan 59 pelanggan pada periode 2021 sampai 2025. Total pendapatan **2.328,60** dari **2.240 item** terjual, sama persis dengan data sumber, jadi tidak ada data yang hilang atau terhitung ganda.

- **Rock mendominasi.** Rock, Latin, Metal, dan Alternative & Punk menyumbang sekitar 73,5% pendapatan. Rock menjadi genre nomor satu (atau sama kuat) di 22 dari 24 negara.
- **Pendapatan ditentukan jumlah pelanggan.** Belanja per pelanggan relatif merata (sekitar 37 sampai 47), jadi AS dan Kanada unggul karena pelanggannya lebih banyak.
- **Konten video bernilai tinggi per unit.** TV Shows menghasilkan sekitar 1,99 per item, sekitar dua kali lipat genre musik.
- **Pendapatan stagnan.** Pendapatan tahunan bergerak di kisaran 450 sampai 481 tanpa tren naik yang jelas.

Rekomendasi bisnis: pertahankan katalog inti, perbesar katalog TV Shows dan konten video, fokus menambah pelanggan, dan kurangi ketergantungan pada AS dan Kanada.

## Keterbatasan

- Data kecil (59 pelanggan), dan 15 negara hanya punya satu pelanggan, sehingga insight per negara sebaiknya dibaca sebagai indikasi.
- Nama genre belum distandarkan sepenuhnya (misalnya "Alternative" terpisah dari "Alternative & Punk").
- `customer_count` dihitung per kombinasi tahun, negara, dan genre, jadi tidak boleh dijumlahkan antar baris.
- `fact_sales` tidak memuat `invoice_id`, sehingga jumlah transaksi tidak bisa dihitung. Ukuran volume yang dipakai adalah jumlah item terjual.

## Cara Menjalankan

1. Pasang PostgreSQL dan Pentaho Data Integration, lalu restore database sumber Chinook.
2. Buat database `staging_chinook` (schema `staging` dan `log`) serta `dwh_chinook` (schema `dimension`, `fact_table`, dan `datamart`).
3. Buka Pentaho dan atur koneksi `chinook_oltp`, `chinook_staging`, dan koneksi ke `dwh_chinook` dengan **kredensial milikmu sendiri**. Password tidak disertakan di repo ini.
4. Jalankan `staging/main_staging.kjb`.
5. Jalankan transformasi dimensi, lalu transformasi `fact_sales`.
6. Jalankan transformasi data mart. Hasilnya tersimpan di tabel `dm_sales_genre_country` dan file CSV.
7. Cek hasil di DBeaver. Pastikan editor terhubung ke database `dwh_chinook`, bukan `postgres`. Jumlah baris harus 432 dengan total pendapatan 2.328,60.

## Pelajaran yang Didapat

- Error sering datang dari hal kecil, jadi baca bagian `Caused by:` di log sebelum menebak.
- Pastikan database yang dilihat benar, karena Pentaho dan DBeaver bisa terhubung ke database berbeda.
- Selalu rekonsiliasi angka antara data mart, tabel fakta, dan data sumber.
- Hop *Copy* dan *Distribute* berbeda. Untuk satu sumber dengan dua tujuan, gunakan *Copy data to next steps*.
- SCD Type 1 efisien untuk data statis, sedangkan SCD Type 2 penting untuk menjaga akurasi analisis historis.
