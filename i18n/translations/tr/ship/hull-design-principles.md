# Gövde Tasarımı İlkeleri

> **Domain:** ship | **Difficulty:** apprentice | **Safety:** green

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Bir gövde, taşıması gereken hacim ile suda yarattığı direnç ve engebeli bir
denizdeki davranışı arasındaki bir uzlaşmadır. Temel ilke, tasarımın uzunluktan
değil ağırlıktan başladığıdır: yer değiştirme hacmi geminin ağırlığı neyse
odur, sualtı gövdenin biçimi ise bu ağırlığı hareket ettirmenin maliyetini
belirler. Dolgunluk ve genişlik kararlılık ile yük hacmi satın alır ve bunu
dirençle öder; dolayısıyla her seçim sayılması gereken bir ödünleşmedir.

## Ön Koşullar

- Arhimedes ve yer değiştirmenin anlamı
- Form katsayıları ve ofsetler için temel trigonometri
- Ölçekli bir çizimi okuma ve pergel ile eğri kullanma
- Denizin sözlüğü: draft, serbest bordür, genişlik ve baş-kıç eğimi

## Malzemeler ve Aletler

- Ölçekli çizim kâğıdı, çizim masası, pergel ve eğri cetveli
- Planimetre ya da çizim üzerinde alan ölçmek için bir ızgara yöntemi
- 1025 kg/m3'te deniz suyu ve 1000 kg/m3'te tatlı su için hidrolik veriler
- Blok, prizmatik ve su düzlemi katsayıları için referans tabloları
- Direnç verileri ve bir pervane devri tahmin edicisi
- Ağırlık ve moment düzeni ile draft işaretleme şablonu

## Uygulama

### Gereksinimleri Belirleyin

1. Yükü, mürettebatı, yakıtı ve yedeği listeleyin; bunların toplamı ölü yüktür.
2. Yapı, makine ve donanım için boş gemi ağırlığını ekleyin, sonra toplamı su
   yoğunluğuna bölerek gövdenin sualtında yer değiştirmesi gereken hacmi bulun.
3. Yükten toplam boyu ve yer değiştirmeyi seçin ve genel amaçlı tekneler için
   boy/genişlik oranını 4:1 ile 6:1 arasında tutun.

### Formu Seçin

1. Blok katsayısını, yer değiştirme hacmi L x B x T'ye bölerek hesaplayın; T
   draft'tır. Bir deplasman gövdesi için 0.4 ila 0.6 hedefleyin.
2. Prizmatik katsayı için 0.55 ila 0.75, su düzlemi katsayısı için 0.6 ila 0.8
   hedefleyin; yaklaşık 0.8'e kadar daha dolgun formun daha fazla yük
   taşıdığını ama daha fazla direnç yarattığını unutmayın.
3. Ödünleşmeyi tartın: daha genişlik ve daha dolgunluk ilk düzelme momentini ve
   yük hacmini artırır, ama direnç ve denizde hareketle bedelini öder.

### Kesitleri Çizin

1. Sırt çizgilerini, yani enine kesitleri, gövde uzunluğu başına yaklaşık dört
   istasyonda çizin ve su çizgilerini tasarım draft'ında, yüklü draft'ta ve
   bunların ikisi üstünde çizin.
2. Taban çizgisini, omurgayı, baş ve stern direklerini, güverte kenarını ve
   bordür eğriliğini uçlar için 10-90-10 kuralıyla belirleyin; dikme çizgilerinin
   önü ve arkasında boyun 10%'u, aralarında 90%'u.
3. Kesitleri eğri cetveliyle düzleştirin ve her çizginin eğriliğinin sürekli
   olduğunu, kesitlerin birbirine göre düzgün gittiğini denetleyin.

### Gücü Tahmin Edin

1. Sürtünme direncini 0.5 x rho x V^2 x S x C_f olarak tahmin edin; pürüzsüz bir
   gövdede, 1e7 üzerindeki Reynolds sayısında C_f, (log10(L) - 2)'nin karesine
   bölünmüş 0.075 değeridir.
2. Artık direnci ekleyin; orta hızda deplasman gövdesi için toplamın 15% ila 40%'ını
   ayırarak hesaplayın.
3. Mil gücünü direncin hıza bölünmesiyle tahmin edin ve genel verimle çarpın; bir
   pervane takılı küçük bir dizel için 0.35 ila 0.50, ardından bunu dakikadaki
   pervane devrine çevirin.

## Güvenlik Notları

- Bu bir masa başı çalışmasıdır, ama ürettiği sayılar yüzme yeteneğini belirler:
  kararlılığı ve serbest bordürü, boş gemi koşuluyla değil, yüklüyken denetleyin.
- Yüzen bir gövde üzerinde asla yalnız çalışmayın; merdiven ve emniyet kemeri
  kullanın ve can yeceğini elinizin uzunluğunda tutun.
- Soğuk su ve boğulma gemideki gerçek tehlikelerdir ve dar bir mekânda devrilme
  çabuk sona erer.
- Serbest bordürü, arkadan gelen bir denizde güverte kenarı kuru kalacak kadar
  yüksek tutun.
- Ağırlık değişikliğinden sonra, mürettebat ya da erzak değişikliği dahil,
  kararlılığı yeniden denetleyin.
- Yer değiştirmeyi ya da draft'ı pay olmadan onaylamayın; deniz suyunun yoğunluğu
  sıcaklık ve tuzlulukla değişir.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- US Navy Hull Design Principles (kamu malı)
