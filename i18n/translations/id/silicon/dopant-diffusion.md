# Difusi Dopan dan Implantasi Ion

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Pemberian dopan menciptakan daerah n-tipe dan p-tipe yang menjadi dasar setiap
sambungan dalam cip. Difusi memasukkan dopan dengan panas, sedangkan implantasi
menembakkannya dengan berkas ion. Prinsip kuncinya: kedalaman sambungan,
bukan sekadar dosisnya, yang menentukan seberapa cepat perangkat jadi
bekerja.

## Prasyarat

- Oksidasi Termal, karena oksida dan mask menentukan arah difusi
- Akses ke tungku difusi dan, untuk implantasi, ke mesin implantasi
- Analisis rangkaian sampai tingkat membaca kurva tegangan-arus dioda

## Bahan & Alat

- Tungku difusi dengan tabung kuars dan kendali zona
- Sumber dopan padat: wafer boron nitrit, atau wafer epitaksial doped
- Praporma kaca borosilikat untuk difusi sumber padat
- Mesin implantasi ion, 20 sampai 200 keV, atau akses ke salah satunya
- Prosesor termal cepat untuk aktivasi implantasi
- Probe titik empat untuk hambatan lembar dan pemantau resistivitas
- Instrumen analisis sudut (angle lane) atau SIMS untuk kedalaman sambungan
- Wafer teroksidasi, fotoresist, mask, dan aligner
- Pinset wafer, kaset, dan pemantau suhu

## Prosedur

### Merencanakan Pemberian Dopan

1. Tetapkan hambatan lembar target dan kedalaman sambungan target dari desain.
2. Pilih antara difusi prapenyapan, difusi pendorong, dan implantasi, lalu hitung dosis untuk kedalaman yang dipilih.
3. Siapkan oksida atau nitrida penahan, dan periksa ketebalan mask, karena mask tipis membiarkan dopan bocor ke samping.

### Mendifusikan Dopan

1. Setel sumber padat pada suhu kendalinya dan stabilkan selama 30 menit, lalu masukkan wafer ke zona sumber selama waktu prapenyapan.
2. Untuk pendorong, beralih ke atmosfer inert dan naikkan suhu ke 1,000 sampai 1,100 derajat C selama 30 sampai 60 menit, lalu dinginkan wafer di atmosfer yang sama.
3. Ukur hambatan lembar pada wafer monitor dari run yang sama, dan lakukan uji coba seluruh resep pada wafer uji sebelum menyentuh wafer produksi.

### Mengimplantasi Dopan

1. Pilih spesies ion, energi, dosis, dan kemiringan berkas sekitar 7 derajat untuk menghindari channeling.
2. Sapu berkas melintasi wafer agar arus tetap rendah dan wafer di bawah 100 derajat C, dan setel dosis untuk energi dan spesies yang dipilih.
3. Konfirmasikan keselarasan berkas dengan pemeriksaan interlock, lalu aktifkan dopan dengan anil termal cepat pada 900 sampai 1,050 derajat C selama 10 sampai 30 detik.

### Memverifikasi Sambungan

1. Ukur hambatan lembar dengan probe titik empat.
2. Ukur kedalaman sambungan dengan analisis sudut (angle lane) atau dengan SIMS,
   dan periksa bahwa profilnya cocok dengan bentuk kotak atau Gauss yang diharapkan.
3. Ukur arus bocor balik dioda uji, dan catat energi implantasi, dosis, kemiringan, dan anil untuk setiap lot.

## Catatan Keselamatan

- Mesin implantasi dan anil bekerja pada tegangan mematikan dan energi berkas tegangan tinggi; bekerjalah padanya hanya dengan pelatihan, pengawasan, dan perangkat yang sesuai.
- Beberapa implantasi membuat wafer radioaktif, jadi ikuti aturan pemantauan dan penanganan setempat.
- Sumber fosfor dan boron beracun dan harus ditangani di dalam fume hood.
- Tabung tungku berjalan di atas 1,000 derajat C, jadi pakai tang dan pelindung wajah.
- Prekursor dopan yang menguap dan gas beracun membutuhkan exhaust yang dibersihkan.
- Kesalahan keselarasan berkas dapat memberi dosis kepada orang di luar chamber,
  jadi anggap setiap interlok sebagai hal nyata dan jangan pernah melewatinya.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- NIST Semiconductor Reference (domain publik)
