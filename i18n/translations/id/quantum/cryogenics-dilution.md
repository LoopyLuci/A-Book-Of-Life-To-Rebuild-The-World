# Kriogenik dan Refrigerasi Dilusi

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Refrigerator dilusi mendinginkan sampel sampai beberapa milikelvin dengan
mencampur helium superfluid dan helium biasa, dan ia mempertahankan suhu itu
hanya bila seluruh anggaran beban panas terpenuhi. Prinsip kuncinya: setiap
kabel, setiap kawat, dan setiap permukaan adalah kebocoran pada insulasi,
sehingga desainnya pada dasarnya soal menghitung panas dalam mikro watt lalu
menghapusnya. Sampel adalah bagian terkecil dari sistem; pipa, penyaringan, dan
perisai yang menentukan apakah pengukuran itu mungkin.

## Prasyarat

- Dasar rekayasa kriogenik dan diagram fase helium
- Superfluiditas dan pengenceran helium-3 dalam helium-4
- Rekayasa gelombang mikro dan desain rantai atenuator dan filter
- Praktik vakum, pemeriksaan kebocoran, dan penanganan kriogen yang aman

## Bahan & Alat

- Refrigerator dilusi dengan ruang pencampur dan still
- Jalur transfer kriogenik dan seperangkat pompa vakum dengan perangkap dingin
- Kabel koaksial untuk vakum, konektor SMA dan SMP, serta heat sink
- Rangkaian atenuator gelombang mikro dan filter low-pass untuk tiap jalur sinyal
- Magnet superkonduktor, set termometer, dan ruang terlindung

## Prosedur

### Merencanakan Beban Panas

1. Daftar setiap jalur yang melintasi dari suhu ruang turun ke ruang pencampur,
   lalu hitung jumlahnya.
2. Hitung kebocoran konduktif setiap kabel dari konduktivitas termal material,
   dengan Q = k A dT dibagi L, dan catat bahwa satu jalur koaksial tanpa
   atenuasi dapat membawa lebih dari satu miliwatt ke tahap 4 K.
3. Hitung beban radiasi melalui setiap perisai dengan
   Q = sigma A (T_hot dikuadratkan dikurangi T_cold dikuadratkan), dengan sigma
   5.67e-8 W per meter persegi per kelvin dikuadratkan.
4. Tambahkan pendinginan dari penguat, bandingkan totalnya dengan daya
   pendinginan di ruang pencampur, biasanya 10 sampai 100 mikro watt pada
   10 mK, dan sisakan margin setidaknya 30 persen.

### Menyiapkan Kabel

1. Akhiri setiap jalur koaksial dengan atenuator di tahap 50 K, tahap 4 K,
   still, dan ruang pencampur, sekitar 10 dB per tahap.
2. Tambahkan filter low-pass di tahap 4 K untuk setiap jalur sinyal, dengan
   frekuensi potong sekitar 5 GHz, dan frekuensi potong yang jauh lebih rendah
   yaitu 700 MHz atau kurang pada setiap jalur bias DC.
3. Kunci setiap jalur ke tahap dengan braid tembaga atau aluminium agar panas
   berhenti di situ.
4. Uji vakum seluruh jalur dan feedthrough-nya, dan jangan pernah menutup
   ruang vakum pada jalur dingin yang belum diperiksa kebocorannya.

### Mendinginkan dan Memverifikasi

1. Jalankan helium dan pompa vakum secara bergantian sesuai urutan yang
   ditentukan dan jangan pernah menghentikan pemanasan yang sudah menghasilkan
   vakum.
2. Perhatikan suhu setiap tahap dan level helium, lalu catat waktu pematangan
   dan suhu dasar akhirnya.
3. Tutup perisai radiasi hanya setelah suhu dasar stabil, lalu pindahkan sampel
   dan pastikan suhu pada tempat sampel cocok dengan termometer.
4. Catat suhu dasar, suhu setiap tahap, dan lantai derau gelombang mikro
   bersama-sama untuk setiap pendinginan.

## Catatan Keselamatan

- Helium cair mengembang luar biasa saat menghangat dan dapat merobek volume
  tertutup, sehingga setiap volume dingin memerlukan jalur pelepasan dan
  perangkat pelepasan tidak boleh pernah tersumbat atau tersegel.
- Helium cair dan nitrogen cair menyebabkan luka bakar dingin dan dapat
  menyingkirkan oksigen di dalam ruangan; bekerjalah di area berventilasi dengan
  monitor ruang dan jangan pernah bekerja sendirian dengan kriogen.
- Jalur transfer kriogenik yang pernah dibuka dapat menyuntikkan helium cair ke
  jalur vakum dan menyebabkan ledakan dalam; jangan pernah membuang udara dari
  jalur dingin ke atmosfer tanpa mengikuti prosedur yang benar.
- Oksigen yang mengembun pada permukaan dingin membuatnya rapuh dan setiap
  sambungan kriogenik menjadi bahaya serpihan; gunakan seal logam yang benar dan
  jangan pernah mengencangkan sambungan dingin.
- Magnet superkonduktor menyimpan energi dan dapat kehilangan sifat
  superkonduktor secara tiba-tiba, melepaskan medan besar dan merebus kriogen;
  tetapkan batas laju perubahan arus dan jangan pernah meninggalkannya berenergi
  tanpa pengawasan.
- Kegagalan vakum atau aliran balik oli pompa dapat mengontaminasi tahap dingin
  dan menghancurkan percobaan tanpa tanda peringatan yang terlihat.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- NIST Cryogenics Guidance (domain publik)
