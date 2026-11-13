Kalau belum punya database chinook, restore pakai file di folder Restore Database. Untuk database staging chinook
harus/lebih enak restore dari file yang kukasih, kalau ngga berarti sama aja kayak kamu garap staging area.

file transformation dan job juga udah ada.

database connection kalau mau buat manual, namanya harus sama kayak file yang kukirim.
chinook_oltp itu konek ke database oltp nya chinook
chinook_staging itu konek ke database stagingnya chinook.
kalau mau dari file yang kukirim, ya juga bisa, tapi pw postgre nya nanti diubah

semua file diatas harus di 1 folder yang sama dan tidak boleh terpisah sub folder lagi biar gk error(bisa bikin folder untuk diarahkan ke repo Mini project, bebas namanya terserah)