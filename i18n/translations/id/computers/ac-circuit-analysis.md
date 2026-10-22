# Analisis Rangkaian AC dan Impedansi

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Pada arus bolak-balik, tegangan dan arus tidak lagi naik dan turun
bersamaan, sehingga rasio tegangan terhadap arus tidak lagi menjadi angka
yang berguna. Prinsip kuncinya adalah mengganti setiap elemen dengan
impedansinya, yaitu bilangan kompleks dengan bagian resistansi dan bagian
reaktansi, lalu menyelesaikan persamaan rangkaian yang sama persis seperti
pada DC. Reaktansi ditentukan oleh frekuensi, itulah sebabnya rangkaian yang
berperilaku tertentu pada keadaan tunak bisa sangat berbeda pada 50 Hz.

## Prasyarat

- Analisis Rangkaian DC untuk hukum Kirchhoff dan aturan seri dan paralel
- Bilangan kompleks dalam bentuk persegi panjang dan polar
- Fungsi sinus dan kosinus, fase, dan beda fase
- Diferensiasi dan integrasi dasar, untuk elemen reaktif
- Hubungan antara nilai RMS, puncak, dan puncak-ke-puncak

## Bahan & Alat

- Function generator dan osiloskop
- Catu daya bench dan multimeter digital dengan rentang kapasitansi
- Resistor, kapasitor, dan induktor dari seri E12 dan E24
- Decade box, atau satu set nilai untuk pekerjaan resonansi dan filter
- Kawat tembaga dan former untuk membuat induktor uji
- Trafo isolasi untuk setiap pekerjaan yang terhubung ke listrik PLN

## Prosedur

### Mengubah Rangkaian menjadi Fazor

1. Ganti setiap resistansi dengan R dan setiap kapasitor serta induktor dengan
   reaktansinya: X_L = 2 x pi x f x L dan X_C = 1 / (2 x pi x f x C).
2. Tulis impedansi setiap elemen dalam bentuk persegi panjang: Z_R = R,
   Z_L = j X_L, dan Z_C = -j X_C.
3. Jumlahkan impedansi seri dan gabungkan cabang paralel dengan aturan yang
   sama seperti pada DC, dengan menyisakan suku j terpisah, lalu ubah hasilnya
   ke bentuk polar: besarnya adalah akar kuadrat dari R^2 ditambah X^2 dan
   sudutnya adalah arctangen dari X dibagi R.

### Menyelesaikan Jaringan AC

1. Terapkan hukum Kirchhoff pada jaringan impedansi dan selesaikan untuk arus
   serta tegangan fazor.
2. Ubah hasil fazor kembali ke domain waktu, ingat bahwa nilai RMS sebuah sinus
   adalah puncak dibagi 1.414.
3. Periksa hasilnya terhadap daya: daya nyata adalah P = V x I x cos(phi),
   daya reaktif adalah Q = V x I x sin(phi), dan daya tampak adalah S = V x I
   dalam volt-ampere.

### Menemukan Resonansi

1. Samakan reaktansi dan tentukan frekuensi resonansi
   f0 = 1 / (2 x pi x sqrt(L x C)).
2. Ukur frekuensi daya-setengah dan hitung faktor kualitas Q = f0 / (f2 - f1),
   lalu periksa terhadap rumus sqrt(L / C) dibagi resistansi seri.
3. Catat bahwa pada resonansi arus rangkaian berada pada maksimum dan tegangan
   pada kapasitor dapat menjadi Q kali tegangan sumber.

### Merancang Filter

1. Tetapkan frekuensi cutoff dari spesifikasi dan hitung resistansi untuk
   filter low-pass RC sederhana, R = 1 / (2 x pi x f x C), lalu bangun.
2. Ukur respons pada 0.1, 1, dan 10 kali frekuensi cutoff dan periksa bahwa
   output turun 20 dB per dekade.
3. Konfirmasikan pergeseran fase pada cutoff, yaitu 45 derajat untuk filter
   orde pertama, dan tambahkan tahap kedua bila redamannya tidak cukup curam.

## Catatan Keselamatan

- Tegangan listrik PLN mematikan. Perlakukan setiap rangkaian yang terhubung
  ke sumber sebagai mematikan, dan bekerjalah padanya hanya dengan pelatihan,
  pengawasan, serta perangkat yang sesuai, memakai trafo isolasi.
- Arus yang menghentikan jantung itu kecil: sekitar 0.5 mA adalah ambang
  persepsi, 10 mA adalah ambang lepas-tahan, 30 mA dapat menghentikan
  pernapasan, dan 50 mA dapat menyebabkan fibrilasi ventrikel.
- Kapasitor bermuatan menyimpan energinya setelah sumber dimatikan, karena
  impedansi meter jauh terlalu tinggi untuk mengosongkannya; gunakan resistor
  pengosong dan buktikan tegangannya dengan meter sebelum menyentuh simpul.
- Rangkaian resonan dapat menghasilkan tegangan tinggi pada kapasitor, dan
  flyback atau konverter boost dapat menempatkan ratusan volt pada simpul yang
  tampak bertegangan rendah.
- Jaga output function generator dan output catu daya bench tetap terisolasi
  satu sama lain, dan jangan pernah menyambungkan sumber sinyal melintasi
  output catu daya.
- Periksa rating tegangan dan arus ripple pada kapasitor, dan ingat bahwa
  tegangan pada kapasitor di rangkaian resonan bisa jauh lebih tinggi dari
  tegangan sumber.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- OpenStax University Physics (CC BY)
