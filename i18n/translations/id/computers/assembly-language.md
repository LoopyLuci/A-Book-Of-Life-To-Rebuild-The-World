# Bahasa Assembly dan Model Mesin

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Assembly adalah bentuk teks dari apa yang sebenarnya dieksekusi
prosesor. Assembly menunjukkan bagaimana mesin memindahkan data antara register
dan memori, bagaimana ia bercabang, dan bagaimana stack digunakan, yang
membuatnya alat yang tepat untuk bagian sistem yang tidak boleh membuang waktu
atau memori. Prinsip kuncinya: arsitektur adalah sebuah kontrak — pengodean
instruksi, himpunan register, dan konvensi pemanggilan semuanya tetap,
sehingga kode yang mematuhi mereka tetap benar di berbagai compiler, pustaka,
dan revisi mendatang.

## Prasyarat

- Pemrograman C Embedded
- Sistem bilangan biner dan heksadesimal
- Logika Boolean dan komplemen dua
- Membaca peta memori dan datasheet perangkat

## Bahan & Alat

- Papan Cortex-M dengan probe debug, atau mesin host dengan disassembler
- Toolchain ARM GCC, termasuk utilitas objdump dan nm
- Manual referensi untuk set instruksi dan peta memori
- Editor teks dengan tampilan heksadesimal
- Analisis logika untuk mengamati waktu pin dan bus
- Skrip uji atau program terminal yang memberikan masukan yang diketahui

## Prosedur

### Mempelajari Set Instruksi

1. Daftar himpunan register arsitektur itu: 13 register umum dari R0 sampai R12,
   ditambah penunjuk stack, register link, dan pencacah program, serta flag
   yang menyimpan negatif, nol, carry, dan overflow.
2. Catat mode pengalamatan, dari register dan immediat sampai offset register
   dan register tak langsung hingga push dan pop stack, masing-masing dengan
   satu contoh satu baris.
3. Catat pengodeannya: instruksi 16-bit dalam pengodean dasar, instruksi 32-bit
   dalam pengodean lebar, dan bahwa instruksi 32-bit harus berada pada batas
   4-byte.

### Membaca Disassembly

1. Kompilasikan fungsi C kecil dengan informasi debug dan bongkar dengan
   utilitas objdump, lalu cocokkan setiap baris C dengan instruksinya.
2. Kenali prolog yang menyimpan register, badan fungsi, dan epilog yang
   memulihkannya dan kembali melalui register link.
3. Temukan ukuran stack frame pada listing dan pastikan cocok dengan yang
   dilaporkan compiler untuk fungsi yang sama.

### Menulis Rutin

1. Tulis sebuah fungsi dalam assembly yang mengambil dua argumen pada dua
   register pertama dan mengembalikan hasil pada register pertama, mengikuti
   standar pemanggilan prosedur.
2. Jaga penunjuk stack tetap sejajar 8-byte pada setiap batas pemanggilan dan
   periksa keselarasan sebelum kembali.
3. Uji rutin itu terhadap implementasi C pada banyak masukan dan bandingkan
   hasilnya nilai demi nilai.

### Mencampur dengan C dan Melakukan Profil

1. Tandai sebuah rutin sebagai naked hanya di tempat yang diperlukan, dan
   biarkan compiler mengelola register di sekitar pemanggilan di tempat lain.
2. Ukur jumlah siklus dengan penghitung siklus inti dan bandingkan dengan
   pekerjaan yang sama yang ditulis dalam C pada setiap tingkat pengoptimalan.
3. Baca file peta linker untuk melihat berapa banyak flash dan RAM yang
   dihemat oleh assembly, dan simpan hanya bila penghematannya sepadan dengan
   biaya pemeliharaan.

## Catatan Keselamatan

- Rutin dalam assembly dapat menggerakkan pin keluaran ke keadaan mana pun
  begitu ia berjalan, dan perulangan tak hingga di dalam penangan interupsi
  akan memicu watchdog atau menggantungkan mesin. Buktikan kode baru dengan
  aktuator yang terputus.
- Menulis ke alamat yang salah dalam assembly merusak memori dan register
  periferi tanpa peringatan. Periksa setiap alamat terhadap peta memori sebelum
  menuliskannya, dan pastikan wilayah itu dapat dieksekusi serta tidak
  terlindungi.
- Hormati aturan keselarasan inti; akses 32-bit yang tidak selaras
  menyebabkan kesalahan pada sebagian perangkat dan diam-diam memakan siklus
  pada yang lain.
- Menjalankan langkah demi langkah mengubah waktu program, jadi jangan
  meng-debug loop kendali dengan menelusuri langkah demi langkah. Gunakan
  buffer trace atau analisis logika.
- Sediakan reset perangkat keras, bootloader, atau citra pemulihan, dan uji
  jalur pemulihan sebelum Anda bergantung padanya.
- Perlakukan assembly sebagai hal yang tidak dapat dipelihara secara bawaan:
  pertahankan kecil, beri komentar pemakaian register, dan lindungi dengan uji
  referensi C.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- Arm Cortex-M Documentation (domain publik)
