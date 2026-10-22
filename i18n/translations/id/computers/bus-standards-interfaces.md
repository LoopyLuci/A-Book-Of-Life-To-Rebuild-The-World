# Standar Bus dan Antarmuka Sinyal

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Bus adalah sebuah kesepakatan tentang kawat: apa arti sebuah level logika,
siapa yang boleh mengendalikan jalur itu, dan bagaimana penerima tahu bahwa
sebuah bit itu sah. Prinsip kuncinya: setiap standar bus menyelesaikan tiga
masalah yang sama, yaitu kekuatan penggerak, pewaktu, dan arbitrasi, dan
perangkat yang mengabaikan salah satunya akan gagal secara intermiten, bukan
gagal total. Tiga antarmuka di bawah ini mencakup sebagian besar yang perlu
dihubungkan di sebuah bengkel kerja.

## Prasyarat

- Logika digital: push-pull, open-drain, pull-up, dan level logika
- Membaca tabel pin datasheet dan diagram pewaktu
- Framing serial: baud rate, bit data, paritas, dan bit stop
- Soldering dasar serta penggunaan multimeter atau analisis logika

## Bahan & Alat

- Analisis logika yang mampu mendekode UART, I2C, dan SPI
- Papan pengembangan mikrokontroler dan beberapa papan breakout
- Paket resistor pull-up, 2 kOhm sampai 10 kOhm untuk I2C pada 400 kHz
- Resistor seri 22 sampai 33 Ohm dan terminasi 120 Ohm untuk jalur panjang
- Catu daya bench, multimeter, dan osiloskop

## Prosedur

### UART

1. Sepakati format frame lebih dulu: 8 bit data, tanpa paritas, dan 1 bit stop,
   yang menghasilkan 10 bit di kawat untuk setiap byte.
2. Setel kedua ujung pada baud rate yang sama, dan ingat bahwa galat 2 persen
   biasanya masih dapat diterima sementara 5 persen tidak.
3. Hubungkan TX ke RX dan RX ke TX, serta sambungkan tanah bersama; ground
   bersama adalah bagian yang paling sering terlupa.
4. Pastikan keadaan diam adalah logika 1 dan logika 0 menandai bit awal, lalu
   periksa level logika di kedua ujung sebelum mempercayai data, dan pasang
   level shifter untuk sambungan 5 V ke 3.3 V.

### I2C

1. Tarik SDA dan SCL ke arah catu daya melalui 2 kOhm sampai 10 kOhm, dan
   periksa waktu naik terhadap kapasitansi bus sebelum menaikkan clock.
2. Alokasikan perangkat dengan alamat 7-bit, dan ingat bahwa banyak komponen
   memakai dua alamat terpisah untuk dua rel catu dayanya.
3. Baca urutan alamat dan register dari datasheet, lalu konfirmasikan keduanya
   di analyzer sebelum mempercayai urutan tersebut.
4. Periksa waktu setup dan hold pada diagram pewaktu, jaga clock di bawah
   100 kHz untuk uji pertama, dan atur ulang bus yang macet dengan denyut
   sembilan clock, bukan dengan menahan SDA rendah.

### SPI

1. Hubungkan clock, input master, output master, dan chip select, dan berikan
   setiap perangkat jalur select-nya sendiri.
2. Mulailah pada mode 0, clock idle rendah, dengan data disampel pada sisi
   naik, lalu konfirmasikan mode tersebut terhadap datasheet.
3. Jaga clock di bawah 1 MHz untuk uji pertama, pendekkan kawat bila tepinya
   terlihat membulat di analyzer, dan pasang 22 sampai 33 Ohm seri pada jalur
   clock dan data untuk meredam resonansi.
4. Baca pewaktu full-duplex di datasheet, termasuk jeda antara chip select
   aktif dan tepi clock pertama.

## Catatan Keselamatan

- Analisis logika dan banyak papan pengembangan menghubungkan ground-nya ke
  tanah host, sehingga menyondong rangkaian bertegangan tinggi atau listrik PLN
  dapat menghancurkan analyzer dan memicu kebakaran.
- Periksa rel catu daya kedua ujung sebelum menyambungkan bus; periferal 5 V
  yang menggerakkan input 3.3 V dapat menghancurkan pengendali.
- Jangan pernah menyondong motor atau rangkaian pemanas yang menyala tanpa
  probe diferensial yang sesuai dengan tegangan tersebut.
- Jaga ground bersama antara kedua perangkat; ground yang melayang memberi
  data palsu dan dapat merusak port.
- Jaga pull-up I2C tetap pendek sejauh yang diizinkan jalur, karena jalur
  panjang tanpa terminasi memancarkan gelombang dan menimbulkan gangguan
  intermiten.
- Satu jalur yang hubung singkat mematikan semua perangkat pada bus, jadi
  matikan daya bagian tersebut sebelum menyuntik ulang kabelnya.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- NXP and Analog Devices Interface Notes (domain publik)
