# Perbandingan Storage

| Storage | Kelebihan | Kekurangan | Cocok untuk |
|---|---|---|---|
| SharedPreferences | API sederhana untuk key-value kecil | Tidak memiliki query, sorting, relasi, atau transaksi catatan | Dark mode dan timestamp terakhir dibuka |
| Hive | Cepat dan praktis untuk object/cache | Query relasional dan migrasi perlu dikelola sendiri | Cache object sederhana |
| sqflite | SQLite, CRUD, `WHERE`, `ORDER BY`, transaksi, dan indeks | Mapping model serta migration ditulis manual | Catatan terstruktur dan dirty queue |
| Drift | Query type-safe, generated model, dan `watch()` reactive | Setup serta code generation lebih besar | Aplikasi SQLite yang berkembang besar |

## Keputusan Project

Project ini memakai SharedPreferences untuk `dark_mode` dan `last_opened_at` karena keduanya adalah preferensi kecil tanpa kebutuhan query.

Project memakai sqflite untuk notes karena membutuhkan CRUD, sorting `updated_at DESC`, filter `dirty = 1`, dan persistence lokal. Daftar catatan tidak disimpan di SharedPreferences karena setiap perubahan akan memaksa aplikasi membaca dan menulis ulang seluruh JSON.
