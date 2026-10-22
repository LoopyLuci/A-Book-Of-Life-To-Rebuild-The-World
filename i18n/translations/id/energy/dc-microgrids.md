# Microgrid DC

> **Domain:** energy | **Difficulty:** journeyman | **Safety:** red

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Microgrid DC kecil menghubungkan panel surya, baterai, dan beban pada bus yang
sama, biasanya 12, 24, atau 48 V. Cara ini menghindari rugi-rugi mengubah ke
tegangan PLN untuk setiap lampu dan pengisi daya telepon, tetapi menuntut
ukuran kawat, sekring, dan pentanahan yang benar. Desain yang bersih menjaga
beban kritis tetap hidup dan memudahkan isolasi gangguan.

## Prasyarat

- Dasar pemasangan PV surya
- Keamanan listrik dan keterampilan multimeter
- Pengetahuan pengisian baterai

## Bahan & Alat

- Panel PV dan perangkat pemasangan
- Pengendali muatan yang sesuai untuk susunan panel
- Bank baterai dengan perlindungan arus lebih
- Busbar DC, sekring, dan pengaman (MCB)
- Kabel tembaga dan lug dengan ukuran tepat
- Batang pentanahan dan konduktor bonding
- Kotak distribusi dan label
- Multimeter, clamp meter, dan alat terisolasi

## Prosedur

### 1. Menentukan Beban dan Tegangan

1. Daftar setiap beban dengan watt, jam per hari, dan apakah itu kritis.
2. Jumlahkan watt-jam harian dan siapkan baterai untuk minimal dua hari mendung.
3. Pilih tegangan bus yang menjaga arus terkendali: tegangan lebih tinggi untuk
   jalur lebih panjang dan beban lebih besar.
4. Jaga beban kritis pada sirkuit terpisah dari beban pilihan.

### 2. Merancang Perlindungan

1. Pasang sekring pada setiap sumber dan setiap cabang pada atau di bawah daya
   kawat.
2. Gunakan pengaman dan sekring untuk DC; komponen AC dapat mengeluarkan busur
   dan gagal memutus DC.
3. Bonding bingkai peralatan dan terminal negatif baterai sesuai skema
   pentanahan yang dipilih.
4. Labeli setiap konduktor, sekring, dan sakelar dengan sumber dan tujuannya.

### 3. Memasang dan Menyalakan

1. Pasang panel dengan ruang untuk pendinginan dan akses.
2. Sambungkan pengendali muatan ke baterai terlebih dahulu, lalu ke susunan
   panel, mengikuti urutan dari produsen.
3. Kencangkan lug sesuai spesifikasi dan periksa drop tegangan di bawah beban.
4. Uji setiap sirkuit dengan multimeter sebelum menyambungkan beban; pastikan
   polaritas dan isolasi.

### 4. Mengoperasikan dan Merawat

1. Catat produksi harian, tegangan baterai, dan pemakaian beban.
2. Periksa terminal untuk panas, korosi, dan sambungan longgar setiap bulan.
3. Setimbangkan atau imbangkan baterai hanya sesuai izin produsen.
4. Putuskan susunan panel sebelum mengerjakan baterai atau pengendali.

## Catatan Keselamatan

- **Bahaya merah:** Baterai dapat memasok arus hubung singkat yang sangat besar
  dan melepaskan hidrogen. Pakai kacamata pengaman dan lepaskan perhiasan logam.
- Busur DC tidak memadamkan dirinya seperti busur AC; gunakan pengaman untuk DC.
- Jangan mencampur kimia, umur, atau kapasitas baterai dalam satu bank.
- Sistem yang terhubung ke jaringan atau generator memerlukan tukang listrik
  bersertifikat dan peralatan transfer yang disetujui.

## Verifikasi

- **Status:** draft

## Sumber

- NEC Article 712 DC Microgrids
- IEC 62548 Photovoltaic Array Design
- Sandia National Laboratories DC Microgrid Guidance
