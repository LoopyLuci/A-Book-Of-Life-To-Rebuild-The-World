# Kode Koreksi Kesalahan Kuantum

> **Domain:** quantum | **Difficulty:** master | **Safety:** green

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Koreksi kesalahan kuantum adalah satu-satunya jalan menuju mesin yang
menghitung cukup lama untuk berarti, karena tidak ada qubit fisik yang cukup
bagus untuk menjalankan algoritma yang berguna sendirian. Prinsip kuncinya:
redundansi harus cocok dengan jenis kesalahannya; bit sindrom klasik
mendeteksi pembalikan bit, bit sindrom berbeda mendeteksi pembalikan fase, dan
ancilla yang mengukur paritas bersama mendeteksi keduanya. Kode dengan jarak d
memperbaiki ⌊(d-1)/2⌋ kesalahan dan mendeteksi d-1, dan di bawah ambang
laju galat, qubit tambahan memberi laju galat logis yang lebih rendah dari
fisiknya.

## Prasyarat

- Gerbang kuantum, grup Pauli, dan formalisme stabilizer
- Matriks kepadatan, bola Bloch, dan kanal bising
- Teori pengodean dasar untuk kode klasik yang dipakai di dalam kode kuantum
- Simulator klasik yang berfungsi dan alat penggambar sirkuit

## Bahan & Alat

- Simulator vektor keadaan dan simulator stabilizer untuk kode kecil
- Penyelesai matriks kepadatan untuk model derau satu putaran
- Data benchmarking acak untuk platform yang diteliti
- Implementasi referensi dekoder pencocokan sempurna bobot minimum
- Tabel laju galat logis terhadap jarak kode dan galat fisik
- Spreadsheet atau skrip untuk anggaran galat fisik dan logis

## Prosedur

### Mengklasifikasi Galat

1. Pisahkan galat pembalikan bit (X), pembalikan fase (Z), dan gabungan (Y), dan
   catat bahwa kanal depolarisasi menghasilkan ketiganya sekaligus.
2. Pasangkan model derau pada setiap gerbang, dan mulailah dari laju
   depolarisasi qubit tunggal 1e-3 dan laju dua qubit 1e-2, yang realistis
   untuk qubit superkonduktor.
3. Masukkan galat pengukuran ke dalam model, karena pembacaan sindrom yang
   keliru dapat menciptakan galat data yang sebelumnya tidak ada.

### Memilih Kode

1. Tetapkan laju galat logis target dan jumlah siklus sirkuit; hasil kali
   keduanya adalah jumlah peluang gagal yang saling bebas.
2. Bandingkan keluarga kode: kode Shor sembilan qubit memperbaiki satu galat
   dengan sembilan qubit, kode Steane memperbaiki satu galat dengan tujuh, dan
   kode permukaan menghabiskan jauh lebih banyak qubit untuk memperbaiki jauh
   lebih banyak galat.
3. Periksa batas Singleton, n - k >= 2(d-1), dan ingat bahwa kode subsistem
   memerlukan minimal dua salinan untuk gerbang logis dua qubit.

### Memodelkan Dekoder dan Menemukan Ambang

1. Hitung sindrom untuk setiap putaran stabilizer dan cari galat bobot minimum
   yang menjelaskannya, memakai dekoder pencocokan sempurna bobot minimum untuk
   kode permukaan.
2. Jaga latensi dekoder di bawah waktu putaran sindrom, sekitar 1 mikrodetik
   pada perangkat keras superkonduktor, atau koreksinya tiba terlalu lambat
   untuk mencegah galat berikutnya.
3. Sapu tangga jarak d = 5, 9, 13, dan 17, dan temukan titik peralihan saat laju
   galat logis berhenti turun; harap sekitar 1% untuk derau depolarisasi dan
   sekitar 10% untuk derau erasure.

### Menghitung Overhead

1. Estimasi jumlah qubit fisik yang dibutuhkan; pada laju galat fisik 1e-3 dan
   laju galat logis target 1e-12, harap sekitar 1e4 qubit fisik per qubit logis.
2. Tambahkan ancilla sindrom, satu per stabilizer, sehingga kode permukaan
   jarak-d membutuhkan sekitar d kuadrat qubit data dan d kuadrat dikurangi satu
   ancilla.
3. Hitung qubit yang menganggur sementara bagian lain menghitung, dan catat
   jarak, overhead, serta laju galat fisik yang diasumsikan bersama hasilnya.

## Catatan Keselamatan

- Ini adalah tugas analisis, tetapi angkanya menentukan apakah sebuah mesin
  layak dibangun: jangan pernah menerima laju galat logis yang diklaim tanpa
  diukur pada model derau perangkat keras yang sebenarnya.
- Dekoder yang lebih lambat dari putaran sindrom diam-diam menurunkan laju galat
  logis, jadi ukur latensi dekoder pada mesin target.
- Jangan pernah memakai ulang dekoder atau konfigurasi perangkat keras dari
  simulasi tanpa derau; anggaran galat hanya berlaku pada model derau yang
  sebenarnya.
- Jauhkan dekoder klasik dari tahap kriogenik dan isolasi perangkat keras
  kendali, agar gangguan pada dekoder tidak dapat bertindak terhadap keadaan
  qubit.
- Catat anggaran galat dan jarak kode bersama data kalibrasi, karena perangkat
  yang dikalibrasi ulang tanpa memeriksa ulang anggaran mungkin sudah tidak lagi
  di bawah ambang.
- Perlakukan setiap klaim ketahanan terhadap galat tanpa ambang terukur sebagai belum
  terbukti, dan nyatakan demikian dalam laporan.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- NIST Quantum Initiative Reference (domain publik)
