# Assembly Dili ve Makine Modeli

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Assembly, işlemcinin gerçekte yürüttüğü şeyin metin biçimidir. Makinenin veriyi
yazmaçlar ile bellek arasında nasıl taşıdığını, nasıl dallandığını ve yığının
nasıl kullanıldığını gösterir; bu da zamanın ya da belleğin harcanamayacağı
sistem bölümleri için doğru araçtır. Temel ilke, mimarinin bir sözleşme
olmasıdır: komut kodlaması, yazmaç kümesi ve çağırma düzeni sabittir; bu
kurallara uyan kod, derleyiciler, kütüphaneler ve gelecek sürümler boyunca doğru
kalır.

## Ön Koşullar

- Gömülü C Programlama
- İkili ve onaltılık sayı sistemleri
- Boole mantığı ve ikiye tümleyen
- Bellek haritası ve işlemci veri sayfası okuma

## Malzemeler ve Aletler

- Hata ayıklama probu olan Cortex-M kartı ya da bir çözümleyicinin bulunduğu
  ana makine
- objdump ve nm araçlarını da içeren ARM GCC araç zinciri
- Komut kümesi ve bellek haritası için referans el kitabı
- Onaltılık görünümü olan metin düzenleyici
- Pin ve veri yolu zamanlamasını gözlemlemek için mantık analizörü
- Bilinen bir girdiyi süren bir test betiği ya da terminal programı

## Uygulama

### Komut Kümesini Öğrenin

1. Mimarinin yazmaç kümesini listeleyin: R0'dan R12'ye kadar 13 genel amaçlı
   yazmaç, ayrıca yığın işaretçisi, bağlantı yazmacı ve program sayacı ile
   negatif, sıfır, taşıma ve taşma bayrakları.
2. Adresleme kiplerini yazın: yazmaç ve doğrudan değerden başlayıp yazmaç ofseti
   ve yazmaç dolaylı üzerinden yığın yazma ve okuma kiplerine kadar, her biri
   için tek satırlık bir örnekle.
3. Kodlamaları not edin: temel kodlamada 16-bit komutlar, geniş kodlamada 32-bit
   komutlar ve bir 32-bit komutun 4 bayt sınırında durması gerektiği.

### Bir Çözümlemeyi Okuyun

1. Küçük bir C işlevini hata ayıklama bilgisiyle derleyin ve objdump aracıyla
   çözümleyin, sonra her C satırını kendi komutlarıyla eşleştirin.
2. Yazmaçları kaydeden prologu, gövdeyi ve onları geri yükleyip bağlantı
   yazmacı üzerinden dönen epilogu tanımlayın.
3. Çıktıda yığın çerçevesi boyutunu bulun ve derleyicinin aynı işlev için
   bildirdiği değerle eşleştiğini doğrulayın.

### Bir Yordam Yazın

1. İlk iki yazmaçta iki argüman alan ve sonucu ilk yazmaçta döndüren, çağırma
   standardına uyan bir işlevi assembly ile yazın.
2. Her çağrı sınırında yığın işaretçisini 8 bayt hizalı tutun ve dönmeden önce
   hizalamayı denetleyin.
3. Yordamı çok sayıda girdi üzerinde bir C uygulamasıyla karşılaştırıp test
   edin ve sonuçları değer değer karşılaştırın.

### C ile Karıştırın ve Profil Çıkarın

1. Bir yordamı naked olarak işaretleyin yalnızca gerçekten gereken yerde, başka
   her yerde yazmaçların çağrı çevresindeki yönetimini derleyiciye bırakın.
2. Çekirdeğin döngü sayacıyla döngü sayısını ölçün ve her iyileştirme düzeyinde
   aynı işin C ile yazılmış hâliyle karşılaştırın.
3. Assembly'nin ne kadar flash ve RAM tasarruf ettiğini görmek için bağlayıcının
   harita dosyasını okuyun ve yalnızca tasarrufun bakım maliyetine değdiği
   yerlerde tutun.

## Güvenlik Notları

- Assembly'de bir yordam, çalıştığı anda bir çıkış pinini herhangi bir duruma
  sürebilir ve bir kesme işleyicisindeki sonsuz döngü watchdog'u tetikler ya da
  makineyi kilitler. Yeni kodu aktüatörler bağlı değilken kanıtlayın.
- Assembly'de yanlış adrese yazmak, belleği ve çevresel yazmaçları uyarı
  vermeksizin bozar. Yazmadan önce her adresi bellek haritasıyla karşılaştırın
  ve bölgenin çalıştırılabilir, korumalı olmadığını doğrulayın.
- Çekirdeğin hizalama kurallarına uyun; hizalanmamış bir 32-bit erişim bazı
  cihazlarda hata üretir, diğerlerinde ise sessizce döngü maliyeti getirir.
- Tek tek adım atmak programın zamanlamasını değiştirir, bu yüzden bir kontrol
  döngüsünü adım adım izleyerek hata ayıklamayın. Bunun yerine bir izleme
  arabelleği ya da mantık analizörü kullanın.
- Bir donanım sıfırlaması, bir önyükleyici ya da bir kurtarma imajı elde hazır
  bulundurun ve ona bağımlı olmadan önce kurtarma yolunu test edin.
- Assembly'yi varsayılan olarak bakımı zor bir dil olarak değerlendirin: küçük
  tutun, yazmaç kullanımıyla açıklamalarla donatın ve C referans testiyle
  kapsayın.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- Arm Cortex-M Documentation (kamu malı)
