# Kompilator, Linker, dan Sistem Build

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Sebuah build mengubah sumber menjadi biner melalui tahap-tahap yang biasanya
tersembunyi: praproses, kompilasi menjadi assembly, assembly menjadi object
file, dan penautan object file menjadi executable. Mengenal setiap tahap
mengubah toolchain dari misteri menjadi alat, karena sebagian besar kegagalan
yang membingungkan — simbol yang hilang, lonjakan ukuran yang tiba-tiba,
biner yang berbeda antar mesin — berasal dari satu tahap dan punya satu
perbaikan. Prinsip kuncinya: setiap tahap menghasilkan artefak yang bisa Anda
baca, sehingga sebuah build seharusnya selalu dapat diperiksa, bukan kotak
hitam.

## Prasyarat

- Pemrograman C dan praprosesor
- Pemrograman C Embedded
- Penggunaan command line dan editor teks
- Pengetahuan dasar tentang berkas dan direktori

## Bahan & Alat

- Toolchain GNU: compiler, assembler, linker, archiver, objdump, nm, size
- GNU Make, atau penggerak build lain
- Proyek kecil dengan sebuah header, dua berkas sumber, dan program uji
- Penampil object file dan hex file, serta sistem kontrol versi
- Direktori build yang dipisahkan dari pohon sumber
- Manifest yang mengunci versi compiler dan flag

## Prosedur

### Mengikuti Tahap-Tahapnya

1. Jalankan praprosesor saja dan baca keluarannya, lalu kompilasi menjadi
   assembly dan baca itu juga, sehingga Anda tahu asal sebuah kesalahan.
2. Hasilkan object file dan periksa header sektornya: seksi text, data, data
   baca-saja, dan bss, beserta tabel simbol.
3. Link object file menjadi executable dan periksa entry point serta peta yang
   menaruh apa di mana.

### Mengendalikan Build

1. Tulis makefile dengan aturan eksplisit, target phony, dan satu berkas
   dependensi per berkas sumber, sehingga perubahan header membangun ulang
   setiap berkas yang memakainya.
2. Pertahankan satu target per keluaran dan perintah kompilasi dalam satu
   variabel, sehingga tidak ada dua aturan yang berbeda pendapat soal flag.
3. Aktifkan seksi per fungsi dan opsi linker yang membuang seksi tak terpakai,
   lalu ukur perubahan pada file peta.

### Menaut dengan Sengaja

1. Pilih penautan statis atau dinamis untuk tiap komponen, dan perhatikan bahwa
   pustaka dinamis menambah dependensi versi pada setiap mesin yang
   menjalankannya.
2. Buat entry point, berkas startup, stack, dan heap eksplisit dalam linker
   script alih-alih menerima nilai bawaan.
3. Daftar simbol yang tertinggal dalam biner, lalu strip yang hanya diperlukan
   untuk debugging sebelum rilis.

### Membuat Build yang Dapat Direproduksi

1. Kunci versi toolchain, flag, dan lingkungan dalam sebuah manifest file yang
   dibaca build, sehingga setiap mesin mengompilasi dengan cara yang sama.
2. Buang path absolut dari object file dengan flag pemetaan ulang path sumber,
   dan tetapkan variabel source date epoch ke nilai tetap.
3. Bangun commit yang sama dua kali pada dua mesin berbeda dan bandingkan
   checksum keluarannya; keduanya harus identik.

## Catatan Keselamatan

- Skrip build menjalankan kode sembarang dengan izin Anda. Hanya bangun dari
  sumber yang sudah Anda baca dan percaya, dan tinjau setiap berkas build
  baru sebelum menjalankannya.
- Aturan make yang menghapus berkas dapat terpicu oleh nama target yang salah
  ketik. Jauhkan perintah destruktif dari aturan, atau lindungi dengan
  konfirmasi, dan jangan pernah menjalankan makefile tak tepercaya sebagai
  administrator.
- Jangan matikan stack protector, pemeriksaan fortify source, atau peringatan
  demi membuat build lolos; masing-masing menangkap cacat nyata.
- Informasi debug dan tabel simbol dalam biner rilis membocorkan path berkas,
  nama pengguna, dan struktur internal. Strip sebelum dikirim.
- Kunci versi toolchain dan catat bersama build, karena peningkatan compiler
  dapat mengubah hasil floating point, tata letak struct, dan keluaran
  pengoptimalan tanpa perubahan sumber.
- Perhatikan ruang disk dan waktu build; include yang liar atau siklus
  dependensi tanpa batas dapat mengisi volume dan menghambat pipeline.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- GNU Toolchain Manual (domain publik)
