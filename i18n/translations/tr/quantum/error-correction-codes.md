# Kuantum Hata Düzeltme

> **Domain:** quantum | **Difficulty:** master | **Safety:** green

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Kuantum hata düzeltme, anlamlı sürece kadar hesap yapabilen bir makineye giden
tek yoldur; çünkü tek başına faydalı bir algoritma çalıştıracak kadar iyi olan
fiziksel bir kübit yoktur. Temel ilke, yedekliliğin hata türüne uygun olması
gerektiğidir: klasik bir sendrom biti bir bit çevirmesini algılar, farklı bir
sendrom biti bir faz çevirmesini algılar ve ortak eşliği ölçen bir yardımcı
kübit ikisini birden algılar. Uzaklığı d olan bir kod floor((d-1)/2) hatayı
düzeltir ve d-1 hata algılar; eşik hata oranının altında ek kübitler fizikselin
altında bir mantıksal hata oranı satın alır.

## Ön Koşullar

- Kuantum kapıları, Pauli grubu ve stabilize edici biçimcilik
- Yoğunluk matrisleri, Bloch küresi ve gürültülü kanallar
- Kuantum kodların içinde kullanılan klasik kodlar için temel kodlama kuramı
- Çalışan bir klasik simülatör ve bir devre çizim aracı

## Malzemeler ve Aletler

- Küçük kodlar için bir durum vektörü simülatörü ve bir stabilize edici
  simülatör
- Tek bir tur için gürültü modelini çözecek bir yoğunluk matrisi çözücü
- İncelenen platform için rastgele kıyaslama verileri
- Asgari ağırlıklı tam eşleme çözücüsünün referans uygulaması
- Mantıksal hata oranının kod uzaklığı ve fiziksel hataya göre tabloları
- Fiziksel ve mantıksal hata bütçeleri için bir tablo ya da betik

## Uygulama

### Hatayı Sınıflandırın

1. Bit çevirme (X), faz çevirme (Z) ve birleşik (Y) hatalarını ayırın ve
   depolarize edici kanalın üçünü birden ürettiğini not edin.
2. Her kapıya bir gürültü modeli bağlayın ve tek kübit için 1e-3, iki kübit için
   1e-2 depolarize oranından başlayın; bu, süperiletken kübitler için gerçekçidir.
3. Modele ölçüm hatasını da katın; çünkü hatalı bir sendrom okuması, var olmayan
   bir veri hatası yaratabilir.

### Kodu Seçin

1. Hedef mantıksal hata oranını ve devre döngüsü sayısını sabitleyin; çarpımları
   bağımsız başarısızlık fırsatı sayısıdır.
2. Kod ailelerini karşılaştırın: dokuz kübitlik Shor kodu dokuz kübitle bir hata
   düzeltir, Steane kodu yedi kübitle bir hata düzeltir ve yüzey kodu çok daha fazla
   hata düzeltmek için çok daha fazla kübit harcar.
3. Singleton sınırını denetleyin: n - k >= 2(d-1); ve alt sistem kodunun mantıksal
   iki kübitlik bir kapı için en az iki kopya gerektiğini unutmayın.

### Çözücüyü Modelleyin ve Eşiği Bulun

1. Her stabilize edici turu için sendromu hesaplayın ve onu açıklayan asgari
   ağırlıklı hatayı bulun; yüzey kodu için asgari ağırlıklı tam eşleme
   çözücüsünü kullanın.
2. Çözücü gecikmesini sendrom tur süresinin altında tutun; süperiletken donanımda
   bu yaklaşık 1 mikrosaniyedir, aksi hâlde düzeltme bir sonraki hatayı önlemek
   için çok geç gelir.
3. d = 5, 9, 13 ve 17 olmak üzere bir uzaklık merdiveni tarayın ve mantıksal hata
   oranının düşmeyi bıraktığı kesişimi bulun; depolarize gürültü için yaklaşık %1,
   silme gürültüsü için yaklaşık %10 bekleyin.

### Fazlayı Bütçelendirin

1. Gereken fiziksel kübitleri tahmin edin; 1e-3 fiziksel hata oranı ve 1e-12 hedef
   mantıksal hata oranında mantıksal kübit başına kabaca 1e4 fiziksel kübit
   bekleyin.
2. Her stabilize edici için bir tane olmak üzere sendrom yardımcı kübitlerini
   ekleyin; böylece uzaklığı d olan bir yüzey kodu kabaca d kare veri kübiti ve
   d kare eksi bir yardımcı kübit gerektirir.
3. Kalanlar hesaplanırken boşta kalan kübitleri sayın ve sonuçla birlikte
   uzaklığı, fazlayı ve varsayılan fiziksel hata oranını kaydedin.

## Güvenlik Notları

- Bu bir analiz işidir, ama sayılar bir makineyi kurmaya değer olup olmadığına
  karar verir: gerçek donanımın gürültü modeli üzerinde ölçülmemiş bir mantıksal
  hata oranını asla kabul etmeyin.
- Sendrom turundan yavaş bir çözücü mantıksal hata oranını sessizce bozar; bu
  yüzden çözücü gecikmesini hedef makinede ölçün.
- Gürültüsüz bir simülasyondan gelen bir çözücüyü ya da donanım yapılandırmasını
  asla yeniden kullanmayın; hata bütçesi yalnızca gerçek gürültü modelinde
  geçerlidir.
- Klasik çözücüyü kriyojenik kademeden uzak tutun ve kontrol donanımını yalıtın;
  böylece çözücüdeki bir arıza kübit durumuna etki edemez.
- Hata bütçesini ve kod uzaklığını kalibrasyon verileriyle birlikte kaydedin;
  çünkü bütçe yeniden denetlenmeden kalibre edilen bir cihaz artık eşiğin
  altında olmayabilir.
- Ölçülmüş bir eşik olmadan yapılan hata toleransı iddialarını kanıtlanmamış
  sayın ve yazılı çalışmada bunu belirtin.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- NIST Quantum Initiative Reference (kamu malı)
