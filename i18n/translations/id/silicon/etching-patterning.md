# Etching Basah dan Kering

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Etching menghilangkan material secara selektif sehingga pola resist ditransfer
ke lapisan film di bawahnya. Dua angka menentukan apakah fitur bertahan:
selektivitas, yaitu laju etsing lapisan dibagi laju etsing mask, dan
anisotropi, yaitu perbandingan penghapusan vertikal terhadap horizontal.
Etching basah murah dan isotropik, sedangkan etching plasma kering berarah dan
presisi, jadi pilihannya mengikuti geometri, bukan kenyamanan.

## Prasyarat

- Fotolitografi dan Pembuatan Mask (pola resist dan pembuatan mask)
- Pelapisan Film Tipis untuk mask keras dan pelapis anti-reflektif
- Pembersihan wafer dan perekat mask yang andal pada permukaan
- Pembacaan tabel laju etsing dan selektivitas milik alat itu sendiri

## Bahan & Alat

- Meja basah: tang berpemanas, kendali suhu, dan pengering putar bilas
- Etchant: asam fluorhidat, asam nitrat, asam asetat, kalium hidroksida,
  tetrametilamonium hidroksida, dan etsa oksida berbuffer
- Etcher RIE atau ICP dengan generator RF 13.56 MHz, matchbox, dan pompa
- Gas proses: CF4, CHF3, SF6, Cl2, dan O2, dengan exhaust yang dibersihkan
- Ellipsometer, profilometer, dan mikroskop optik untuk pengukuran
- Wadah PTFE dan polietilena, pinset wafer, dan pelindung wajah

## Prosedur

### Merencanakan Selektivitas

1. Tetapkan kedalaman target dan dimensi kritis untuk lapisan tersebut.
2. Cari laju etsing film dan mask pada alat dan kimia Anda sendiri; laju yang
   dipublikasikan tidak berlaku sama sekali antar mesin.
3. Butuh selektivitas minimal 10:1 untuk film 100 nm di bawah resist 1 um, dan
   tambahkan mask keras bila resist tidak akan bertahan terhadap etsing.
4. Rencanakan efek loading: laju etsing diperkirakan turun seiring
   bertambahnya luas terbuka, jadi buat wafer uji yang memuat pola kecil
   sekaligus pola besar.

### Etching Basah

1. Bersihkan wafer, keringkan, lalu pasang resist atau mask keras.
2. Etching silikon dalam asam fluorhidat, nitrat, dan asetat pada 60-80 °C selama
   20-60 s, atau etsing dalam kalium hidroksida pada 80 °C untuk penghapusan
   anisotropik dengan selektivitas di atas 100:1 terhadap silika.
3. Bilas dengan air deionisasi dan keringkan dengan nitrogen.
4. Kompensasikan undercut dengan memperbesar mask sebesar kedalaman etsing di
   setiap sisi, dan pertahankan bidang (111) dengan menutup sudut memakai tab
   setidaknya 1.41 kali ukuran yang dimaksud.

### Etching Kering

1. Muat wafer ke dalam etcher, turunkan tekanan, dan siapkan chamber dengan
   pembersihan oksigen dan fluorokarbon.
2. Setel aliran gas, tekanan (sekitar 10-50 mTorr untuk RIE dan 1-10 mTorr untuk ICP), daya sumber (300-600 W untuk silikon), dan daya bias untuk film target.
3. Etching hingga kedalaman target dan berhenti pada sinyal akhir proses: akhir interferensi optik, atau penurunan pada garis emisi silikon.
4. Ukur kedalaman dan profil dinding samping pada wafer witness, periksa retakan pada dasar fitur yang lebar, dan catat laju serta selektivitas untuk run berikutnya.

## Catatan Keselamatan

- **Bahaya merah:** Asam fluorhidat mematikan lewat kontak kulit dan lewat
  penghirupan, dan ia menyerang tulang. Tangani hanya dengan pelatihan,
  pengawasan, dan perangkat yang sesuai, dengan gel kalsium glukonat di meja dan
  sistem berpasangan.
- **Bahaya merah:** Jangan pernah menyimpan atau mengangkut asam fluorhidat
  dalam kaca; ia menyerang kaca dan bocor menembusnya.
- Campuran asam fluorhidat, nitrat, dan asetat melepaskan nitrogen dioksida;
  bekerjalah di fume hood dan jangan pernah menghirup uapnya.
- Gas etching plasma beracun dan dapat membuat kekurangan oksigen: kimia
  klorin menghasilkan hidroklorida dan kimia fluorin menghasilkan hidrogen
  fluorida.
- Sumber radiofrekuensi dan plasma mematikan untuk disentuh; jaga interlok dan
  scrubber exhaust tetap berjalan selama gas mengalir.
- Bak etchant harus diberi label dengan komposisi dan tanggal, dan bak yang
  pernah kena silikon tidak boleh pernah dikembalikan ke pembersihan kaca.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- NIST Semiconductor Reference (domain publik)
