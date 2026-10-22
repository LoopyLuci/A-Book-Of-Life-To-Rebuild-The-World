# Elektronika Kendali Gelombang Mikro

> **Domain:** quantum | **Difficulty:** master | **Safety:** yellow

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Segala yang diminta dari sebuah qubit tiba sebagai denyut gelombang mikro
yang dibentuk. Prinsip kuncinya: sebuah denyut ditentukan oleh amplopnya,
fasenya, dan waktunya sampai tingkat nanodetik, sehingga elektronik kendali
harus menjaga fase dan frekuensi tetap sementara amplitudo disapu naik seratus
kali lipat. Segala yang bergetar di dalam elektronik akan muncul langsung
sebagai galat pada qubit.

## Prasyarat

- Rekayasa gelombang mikro: perambatan, pencampuran, dan impedansi
- Pemrosesan sinyal digital dan modulasi IQ
- Pewaktu, jitter, dan phase-locked loop
- Pentanahan RF, perisai, dan praktik keselamatan

## Bahan & Alat

- Arbitrary waveform generator dengan minimal dua kanal
- Pencampur IQ dan set filter low-pass untuk setiap kanal
- Osilator lokal dengan phase-locked loop dan referensi derau rendah
- Kabel koaksial, atenuator, dan blok DC
- Power meter dan spektrum analyzer untuk menyetel level

## Prosedur

### Merencanakan Set Denyut

1. Daftar setiap operasi yang dibutuhkan perangkat: denyut pi, denyut readout,
   Ramsey echo, rotasi Z virtual, dan nada reset.
2. Hitung amplitudo setiap denyut dari frekuensi osilasi Rabi dan panjang
   denyut, memakai aturan bahwa luas denyut pi radian memberi inversi penuh.
3. Pilih panjang denyut yang merupakan bilangan bulat dari siklus penggerak
   sehingga amplopnya tidak meninggalkan detuning sisa di akhir, dan catat
   angka kalibrasi setiap denyut serta simpan bersama eksperimen.

### Membangun Jalur Sinyal

1. Hasilkan amplop baseband pada laju sampel minimal dua kali komponen
   frekuensi tertinggi di dalam amplop tersebut.
2. Campurkan dengan osilator lokal pada frekuensi qubit untuk membentuk sinyal
   sideband tunggal.
3. Filteri setiap kanal untuk menghilangkan sideband yang tidak diinginkan dan
   kebocoran pembawa, dan ukur penolakannya di analyzer.
4. Setel level di qubit dengan atenuator yang terkalibrasi, biasanya antara
   10 mikro watt dan 1 miliwatt, dan ukur di qubit, bukan di generator.
5. Jaga kabel tetap pendek, pakai kabel dengan fase yang sama bila waktunya
   penting, dan amankan setiap kabel agar tidak bergeser antar eksekusi.

### Menyinkronkan dan Memverifikasi

1. Turunkan setiap kanal dari satu jam acuan utama dan catat acuan itu dalam
   data setiap eksekusi.
2. Ukur jitter jalur pemicu dan jaga di bawah 1 persen denyut terpendek.
3. Karakterisasi derau fase osilator lokal dan hubungkan dengan dephasing yang
   terlihat pada qubit.
4. Jalankan sapuan Rabi dan urutan Ramsey di awal setiap sesi, lalu periksa
   frekuensi dan amplitudo terhadap log, dan simpan sampel amplop mentah di
   samping hasilnya.

## Catatan Keselamatan

- Penguat gelombang mikro dapat mengantarkan puluhan miliwatt ke perangkat
  yang mati pada satu mikro watt, jadi mulailah selalu dari keluaran terendah
  lalu naikkan sambil mengamati daya pantul.
- Daya pancar pada 5 GHz menyebabkan luka bakar dan memanaskan jaringan dari
  dalam; jangan pernah mengarahkan antena ke orang dan anggap konektor
  keluaran sebagai bertegangan.
- Konektor yang longgar atau kabel yang rusak dapat mengeluarkan busur dan
  memulai kebakaran, jadi gunakan konektor dengan batas torsi dan periksa
  setiap kabel dalam keadaan berbeban.
- Kesalahan pentanahan membuat RF berada pada pelindung kabel, yang kemudian
  mencari jalan melalui rak dan dapat merusak instrumen.
- Blok DC dan tee bias harus sesuai untuk frekuensinya; blok DC biasa akan
  mengeluarkan busur pada daya gelombang mikro.
- Jangan pernah mengganti kabel pada penguat yang sedang menyala; sebagian
  penguat memerlukan terminasi tertentu sebelum dapat dinyalakan.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- NIST Quantum Initiative Reference (domain publik)
