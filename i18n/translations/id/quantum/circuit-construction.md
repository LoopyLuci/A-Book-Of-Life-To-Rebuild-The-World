# Penyusunan Sirkuit Kuantum

> **Domain:** quantum | **Difficulty:** apprentice | **Safety:** green

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Sirkuit kuantum adalah resep tertulis: daftar gerbang pada daftar qubit,
diikuti pengukuran. Prinsip kuncinya adalah sirkuit yang Anda tulis bukan
sirkuit yang dijalankan, karena kompilator harus lebih dahulu memetakannya ke
gerbang dan koneksi yang benar-benar dimiliki perangkat kerasnya. Kemampuan
membaca penerjemahan itu, dan menjaga kedua sirkuit tetap berdekatan, adalah
keterampilan praktisnya.

## Prasyarat

- Vektor kompleks dan perkalian matriks
- Bola Bloch dan gerbang qubit tunggal
- Dasar Python atau bahasa skrip lain
- Aturan sirkuit kuantum: tidak ada cloning, dan pengukuran menghapus

## Bahan & Alat

- SDK kuantum seperti Qiskit, Cirq, atau Braket
- Simulator vektor keadaan untuk sirkuit kecil, sampai sekitar 20 qubit
- Backend perangkat keras dan data kalibrasi yang dipublikasikan
- Buku catatan atau berkas yang memuat sirkuit dan keluaran yang diharapkan
- Salinan lokal model derau untuk perangkat target

## Prosedur

### Menulis Sirkuit

1. Nyatakan pertanyaan yang dijawab sirkuit sebelum menulis satu gerbang pun.
2. Bangun sirkuit berlapis, satu gerbang pada satu waktu, dan gambar untuk
   memeriksa bahwa kawat-kawatnya adalah qubit yang Anda maksud.
3. Jaga jumlah gerbang tetap sedikit, dan lebih baik satu pasangan terjerat
   daripada beberapa yang saling tumpang tindih.
4. Tambahkan pengukuran paling akhir, dan ingat bahwa mengukur terlalu awal
   menghapus keadaan untuk sisa sirkuit.

### Mengompilasinya

1. Kirim sirkuit melalui transpiler untuk backend target dan biarkan ia memilih
   basis native serta pemetaannya.
2. Lihat tata letak yang dipilih kompilator: pada konektivitas kisi atau
   heavy-hex, qubit yang jauh dihubungkan dengan gerbang swap yang menambah
   galat.
3. Pilih tata letak awal sendiri bila sirkuit punya geometri alami, dan
   bandingkan jumlah gerbang dari kedua pilihan.
4. Setel tingkat pengoptimalan ke 1 atau 2, catat tingkat mana yang menghasilkan
   run yang Anda simpan, dan periksa waktu denyut yang dijadwalkan, karena
   kompilator dapat menyisipkan waktu menganggur saat qubit hanyut.

### Menjalankan dan Membaca Hasil

1. Jalankan sirkuit berkali-kali dan hitung keluarannya; satu eksekusi memberi
   Anda hampir tidak ada informasi.
2. Bandingkan histogram dengan simulasi ideal dan nyatakan perbedaannya sebagai
   angka, bukan sebagai kesan.
3. Periksa metadata pekerjaan untuk tanggal kalibrasi perangkat, dan tolak
   melaporkan angka dari perangkat yang belum dikalibrasi.
4. Simpan sirkuit, versi terkompilasi, benih, dan hitungan bersama-sama, jalankan
   ulang dengan benih berbeda, dan pastikan statistiknya cocok sebelum
   menyimpulkan apa pun.

## Catatan Keselamatan

- Simulator dapat menghabiskan memori mesin: vektor keadaan memerlukan 16 bytes
  per qubit, sehingga 30 qubit memerlukan 16 terabyte, dan metode stabilizer atau
  matriks kepadatan sebaiknya dipakai sebagai gantinya.
- Jangan pernah mengirim sirkuit yang menyimpan kunci rahasia pada gerbangnya ke
  perangkat bersama tanpa pemeriksaan, karena sirkuit memberi petunjuk sangat
  banyak tentang data yang menjadi dasarnya.
- Menjalankan pada perangkat keras memakan waktu antrean dan mendinginkan mesin,
  jadi kelompokkan sirkuit dan biarkan perangkat bebas untuk orang lain.
- Pengukuran bersifat merusak, dan sirkuit yang mengukur terlalu awal lalu
  memakai kembali qubit itu memberi jawaban salah, bukan pesan galat.
- Jangan melaporkan hasil perangkat keras tanpa nama perangkat, tanggal
  kalibrasi, dan jumlah eksekusi, karena tak satu pun bisa dipulihkan kemudian.
- Simulator tanpa derau dengan senang hati menampilkan hasil sempurna untuk
  sirkuit yang tidak bisa dijalankan, jadi selalu nyatakan yang menghasilkan
  angka itu.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- NIST Quantum Initiative Reference (domain publik)
