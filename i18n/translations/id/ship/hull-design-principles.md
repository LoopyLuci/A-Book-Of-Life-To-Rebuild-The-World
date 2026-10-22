# Prinsip Desain Badan Kapal

> **Domain:** ship | **Difficulty:** apprentice | **Safety:** green

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Badan kapal adalah kompromi antara volume yang harus diangkut, hambatan yang
dihasilkannya di air, dan cara ia berperilaku di laut yang bergelombang.
Prinsip kuncinya: desain dimulai dari berat, bukan dari panjang; displacement
adalah sebesar apa pun kapal itu berbobot, dan bentuk badan bawah air
kemudian menentukan berapa mahal berat itu untuk digerakkan. Volume penuh dan
lebar kapal memberi kestabilan dan ruang muatan, tetapi harus dibayar dengan
hambatan, sehingga setiap pilihan adalah trade-off yang harus dihitung.

## Prasyarat

- Archimedes dan makna displacement
- Trigonometri dasar untuk koefisien bentuk dan offset
- Membaca gambar skala dan memakai jangka serta spline
- Kosakata laut: draf, freeboard, lebar, dan trim

## Bahan & Alat

- Kertas gambar skala, papan gambar, jangka, dan spline
- Planimeter, atau metode kisi untuk mengukur luas pada gambar
- Data hidrostatik untuk air laut pada 1025 kg/m3 dan air tawar pada 1000 kg/m3
- Tabel acuan untuk koefisien balok, prisma, dan bidang air
- Data hambatan dan alat pemeriksa putaran propulsi
- Jadwal berat dan momen, serta templat penandaan draf

## Prosedur

### Menetapkan Kebutuhan

1. Daftar muatan muatan, awak kapal, bahan bakar, dan cadangan; jumlah semua itu
   adalah deadweight.
2. Tambahkan berat kapal kosong untuk struktur, mesin, dan perlengkapan, lalu bagi
   total itu dengan kepadatan air untuk memperoleh volume yang harus digeser
   badan kapal di bawah garis air.
3. Pilih panjang keseluruhan dan displacement dari muatan, dan jaga rasio
   panjang terhadap lebar antara 4:1 dan 6:1 untuk kapal serbaguna.

### Memilih Bentuk

1. Hitung koefisien balok sebagai volume yang digeser dibagi L x B x T, dengan T
   adalah draf, dan bidik 0.4 sampai 0.6 untuk kapal displacement.
2. Bidik koefisien prisma 0.55 sampai 0.75 dan koefisien bidang air 0.6 sampai
   0.8, dan ingat bahwa bentuk yang lebih penuh, sampai sekitar 0.8, mengangkut
   lebih banyak tetapi menghasilkan lebih banyak hambatan.
3. Timbang untung ruginya: lebar dan volume penuh yang lebih besar menaikkan
   momen pemulih dan ruang muatan, tetapi harus dibayar dengan hambatan dan
   gerak di laut bergelombang.

### Menata Garis

1. Gambar buttocks dan penampang melintang pada sekitar empat station per
   panjang badan kapal, dan gambar garis air pada draf desain, draf beban, dan
   dua garis air di atasnya.
2. Tetapkan garis dasar, keel, tiang halu dan buritan, tepi dek, dan sheer
   (kelengkungan dek), memakai aturan 10-90-10 untuk kedua ujung, dengan 10% panjang di depan dan
   belakang tegak lurus dan 90% di antaranya.
3. Haluskan penampang dengan spline dan periksa bahwa kelengkungan tiap garis
   kontinu dan penampangnya saling selaras.

### Memperkirakan Daya

1. Estimasi hambatan gesek sebagai 0.5 x rho x V^2 x S x C_f, dengan C_f
   sebesar 0.075 dibagi kuadrat (log10(L) - 2) untuk badan kapal halus pada
   bilangan Reynolds di atas 1e7.
2. Tambahkan hambatan sisa, dengan menyediakan 15% sampai 40% dari total untuk
   kapal displacement pada kecepatan sedang.
3. Estimasi daya poros sebagai hambatan kali kecepatan dibagi efisiensi
   keseluruhan, 0.35 sampai 0.50 untuk mesin diesel kecil dengan propulsi, lalu
   ubah menjadi putaran propulsi per menit.

## Catatan Keselamatan

- Ini latihan di meja, tetapi angka yang dihasilkan menentukan daya apung:
  periksa kestabilan dan freeboard dengan muatan di atas kapal, bukan dalam
  kondisi kapal kosong.
- Jangan pernah bekerja sendirian pada kapal yang masih mengapung; gunakan tangga
  dan pelindung jatuh, dan siapkan lifejacket dalam jangkauan.
- Air dingin dan tenggelam adalah bahaya yang sebenarnya di kapal, dan kapal
  terbalik di ruang tertutup berakhir dengan cepat.
- Jaga freeboard cukup tinggi agar tepi dek tetap kering ketika gelombang
  mengepung dari belakang.
- Periksa ulang kestabilan setiap kali berat berubah, termasuk perubahan awak
  kapal atau persediaan.
- Jangan menyetujui displacement atau draf tanpa margin; kepadatan air laut
  berubah dengan suhu dan salinitas.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- US Navy Hull Design Principles (domain publik)
