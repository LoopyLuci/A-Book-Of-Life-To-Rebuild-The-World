# Derleyiciler, Bağlayıcılar ve Derleme Sistemleri

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Bir derleme, kaynağı genellikle gizli aşamalar üzerinden ikiliye dönüştürür: ön
işleme, assembly'ye derleme, assembly'den nesne dosyası üretimi ve nesnelerin
çalıştırılabilir dosyaya bağlanması. Her aşamayı bilmek, araç zincirini bir
gizemden bir araca dönüştürür; çünkü kafa karıştırıcı arızaların çoğu — eksik
bir sembol, boyutta ani bir artış, makineler arasında farklılaşan bir ikili —
bir aşamaya aittir ve tek bir düzeltmesi vardır. Temel ilke şudur: her aşama
okunabilir bir çıktı üretir, bu yüzden bir derleme her zaman kara kutu değil,
incelenebilir olmalıdır.

## Ön Koşullar

- C programlama ve ön işleyici
- Gömülü C Programlama
- Komut satırı kullanımı ve bir metin düzenleyici
- Dosyalar ve dizinler hakkında temel bilgi

## Malzemeler ve Aletler

- GNU araç zinciri: derleyici, assembler, bağlayıcı, arşivleyici, objdump, nm,
  size
- GNU Make ya da başka bir derleme sürücüsü
- Bir başlık, iki kaynak dosyası ve bir test programı olan küçük bir proje
- Nesne ve hex dosya görüntüleyicileri ve bir sürüm denetim sistemi
- Kaynak ağacından ayrı tutulan bir derleme dizini
- Derleyici sürümünü ve bayrakları sabitleyen bir manifest

## Uygulama

### Aşamaları İzleyin

1. Ön işleyiciyi tek başına çalıştırıp çıktısını okuyun, sonra assembly'ye
   derleyip onu okuyun; böylece bir arızanın hangi aşamadan geldiğini
   bilirsiniz.
2. Nesne dosyaları üretin ve bölüm başlıklarını inceleyin: text, data,
   salt-okunur data ve bss bölümleri ile birlikte sembol tablosu.
3. Nesneleri bir çalıştırılabilir dosyaya bağlayın ve giriş noktasını ve
   bağlayıcının neyi nereye yerleştirdiğinin haritasını inceleyin.

### Derlemeyi Denetleyin

1. Açık kurallar, sahte hedefler ve her kaynak dosya için bir bağımlılık dosyası
   içeren bir makefile yazın; böylece bir başlık değişikliği onu içeren her
   dosyayı yeniden derler.
2. Her çıktı için tek hedef tutun ve derleyici komutunu tek bir değişkende
   toplayın; böylece iki kural bayraklar hakkında anlaşamaz.
3. İşlev başına bölümleri ve kullanılmayan bölümleri atan bağlayıcı seçeneğini
   etkinleştirin, sonra harita dosyasındaki değişimi ölçün.

### Bilerek Bağlayın

1. Her bileşen için statik ya da dinamik bağlama seçin ve bir paylaşımlı
   kütüphanenin onu çalıştıran her makineye bir sürüm bağımlılığı eklediğini not
   edin.
2. Varsayılanları kabul etmek yerine giriş noktasını, başlangıç dosyalarını,
   yığını ve yığın havuzunu bağlayıcı betiğinde açıkça belirtin.
3. İkili dosyada kalan sembolleri listeleyin ve yalnızca hata ayıklama için
   gerekenleri yayınlamadan önce çıkarın.

### Derlemeyi Tekrarlanabilir Yapın

1. Araç zinciri sürümünü, bayrakları ve ortamı derlemenin okuduğu bir manifest
   dosyasında sabitleyin; böylece her makine aynı biçimde derler.
2. Kaynak yol yeniden eşleme bayrağıyla nesne dosyalarındaki mutlak yolları
   çıkarın ve kaynak tarih epoch değişkenini sabit bir değere ayarlayın.
3. Aynı commit'i iki farklı makinede iki kez derleyin ve çıktıların sağlama
   toplamlarını karşılaştırın; aynı olmalıdır.

## Güvenlik Notları

- Bir derleme betiği sizin izinlerinizle keyfi kod çalıştırır. Yalnızca okuduğunuz
  ve güvendiğiniz kaynaklardan derleyin ve yeni bir derleme dosyasını
  çalıştırmadan önce inceleyin.
- Dosya silen bir make kuralı, yanlış yazılmış bir hedef adıyla tetiklenebilir.
  Yıkıcı komutları kuralların dışında tutun ya da bir onay istemiyle koruyun ve
  asla güvenilmez bir makefile'ı yönetici olarak çalıştırmayın.
- Bir derlemenin geçmesi için yığın koruyucusunu, fortify kaynak denetimlerini
  ya da uyarıları kapatmayın; her biri gerçek bir hatayı yakalar.
- Yayımlanmış bir ikilideki hata ayıklama bilgileri ve sembol tabloları dosya
  yollarını, kullanıcı adlarını ve iç yapıyı ele verir. Sevk etmeden önce
  bunları çıkarın.
- Araç zinciri sürümünü sabitleyin ve derlemeyle birlikte kaydedin; çünkü bir
  derleyici yükseltmesi, kaynak kodunda hiçbir değişiklik olmadan kayan nokta
  sonuçlarını, struct düzenini ve iyileştirme çıktısını değiştirebilir.
- Disk alanını ve derleme süresini izleyin; kontrolsüz bir include ya da
  sınırsız bir bağımlılık döngüsü bir birimi doldurabilir ve hattı kilitleyebilir.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- GNU Toolchain Manual (kamu malı)
