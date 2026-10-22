# Alur Desain Sirkuit Terintegrasi

> **Domain:** silicon | **Difficulty:** master | **Safety:** yellow

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Sebuah sirkuit terintegrasi berjalan dari spesifikasi tertulis sampai tata
letak GDSII yang bisa dimask oleh sebuah foundry. Prinsip kuncinya: setiap
tahap adalah gerbang verifikasi; tidak ada yang maju sebelum tahap sebelumnya
terbukti, karena biaya cacat melonjak tajam

## Prasyarat
- Desain digital dan logika Boolean
- Analisis pewaktu: setup, hold, clock skew, dan jalur kritis
- Verilog atau VHDL, beserta simulator dan alat sintesis yang disebutkan di bawah
- Toolkit desain teknologi: sel standar, LEF dan GDEF, lapisan GDSII, dan pewaktu Liberty
- Kontrol versi dengan percabangan dan tinjauan rekan sejawat

## Bahan & Alat

- Dokumen spesifikasi dan rencana verifikasi
- Sumber RTL, testbench, dan simulator dengan penampil gelombang
- Alat sintesis dengan pustaka sel standar dan berkas pewaktu Liberty
- Alat place-and-route dengan toolkit desain, ditambah analisis pewaktu statis
- Alat signoff: lint, CDC, DRC, LVS, serta pemeriksaan drop IR dan electromigration
- Repositori Git, pelacak isu, dan model biaya yang mencakup biaya wafer, luas die, die per wafer, serta biaya sekali pakai mask dan desain

## Prosedur

### Menulis Spesifikasi dan RTL

1. Tulis spesifikasi: antarmuka, jam, throughput, anggaran latensi, batas daya, batas luas die, dan batas biaya.
2. Tulis rencana verifikasi sebelum RTL, mencakup assertion, kasus sudut, dan target cakupan.
3. Bekukan spesifikasi dan catat, sehingga perubahan berikutnya terlihat sebagai perubahan, bukan sebagai pergeseran.
4. Tulis RTL, simulasikan testbench sampai regresi lolos, dan jalankan lint untuk ketidakcocokan lebar, assignment yang tidak lengkap, dan beberapa driver.

### Mensintesis dan Meletakkan

1. Setel batasan jam, dengan periode dan ketidakpastiannya, dan jalankan sintesis terhadap target luas dan pewaktu.
2. Baca laporan jalur kritis dan estimasi daya: daya dinamis kira-kira C x V^2 x f ditambah kebocoran.
3. Rencanakan floorplan sebelum alat melakukannya, menempatkan memori, blok analog, dan cincin I/O, serta menyisakan ruang untuk jaringan daya.
4. Jalankan penempatan, lalu penyisipan pohon jam, lalu perutean, dan periksa skew serta kemacetan perutean setelah setiap tahap.

### Menutup dengan Signoff dan Tape Out

1. Jalankan pewaktu statis di sudut lambat dan cepat, untuk setup dan untuk hold.
2. Jalankan DRC untuk aturan jarak, kepadatan, dan antena, LVS terhadap skematik, serta pemeriksaan drop IR dan electromigration.
3. Tutup setiap pelanggaran, lalu jalankan Monte Carlo multi-sudut untuk memunculkan kegagalan pewaktu yang jarang.
4. Ekspor GDSII, buat set mask, arsipkan bersama checksum dan versi alat yang
   dipakai, dan bagikan pesanan antara dua foundry untuk mengurangi risiko
   jadwal.

## Catatan Keselamatan

- Bahaya di sini adalah bahaya proyek: tape out yang belum ditinjau membuang seluruh set mask dan uang di belakangnya.
- Kunci sumber dan setiap kekayaan intelektual pihak ketiga, dan simpan berkas desain di penyimpanan dengan akses terkendali; aturan ekspor berlaku untuk berkas-berkas itu.

- Gunakan build yang dapat direproduksi: catat versi alat, skrip, dan status lisensi sehingga arsip dapat dibangun ulang secara persis.
- Verifikasi IP pihak ketiga sebelum memakainya, karena bug halus dalam hard macro mahal dan sulit ditemukan.
- Minta orang kedua memeriksa daftar signoff terhadap spesifikasi sebelum pesanan diletakkan.
- Arsipkan GDSII dan set mask; kehilangan keduanya berarti membayar lagi untuk mask.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- NIST Semiconductor Reference (domain publik)
