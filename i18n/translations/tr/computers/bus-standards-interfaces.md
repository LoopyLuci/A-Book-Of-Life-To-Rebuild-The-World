# Veri Yolu Standartları ve Sinyal Arayüzleri

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Bir veri yolu, teller üzerinde bir anlaşmadır: bir mantık düzeyinin ne anlama
geldiği, hattı kimlerin sürülebileceği ve alıcının bir bit'in geçerli olduğunu
nasıl anlayacağı. Temel ilke şudur: her veri yolu standardı aynı üç sorunu
çözer — sürüş gücü, saatleme ve arbitraj — ve bunlardan birini yok sayan bir
cihaz temiz bir şekilde değil, aralıklı olarak arızalanır. Aşağıdaki üç arayüz,
bir atölyenin bağlamak zorunda olduğu şeylerin çoğunu kapsar.

## Ön Koşullar

- Dijital mantık: it-çek, açık drenaj, yukarı çekme dirençleri ve mantık
  düzeyleri
- Veri sayfası pin tablosu ve zamanlama diyagramı okuma
- Seri çerçeveleme: baud hızı, veri bitleri, eşlik ve durdurma bitleri
- Temel lehimleme ve multimetre ya da mantık analizörü kullanımı

## Malzemeler ve Aletler

- UART, I2C ve SPI çözebilen bir mantık analizörü
- Bir mikrodenetleyici geliştirme kartı ve birkaç breakout kart
- Yukarı çekme direnç paketleri; 400 kHz'de I2C için 2 kOhm ile 10 kOhm
- Uzun hatlar için 22 ila 33 Ohm seri dirençler ve 120 Ohm sonlandırmalar
- Masa tipi güç kaynağı, multimetre ve osiloskop

## Uygulama

### UART

1. Önce çerçeveyi üzerinde anlaşın: 8 veri biti, eşlik yok ve 1 durdurma biti;
   bu, her bayt için hat üzerinde 10 bit demektir.
2. Her iki ucu aynı baud hızına ayarlayın ve yüzde 2'lik hatanın genellikle
   tolere edilebilir, yüzde 5'lik hatanın ise edilemez olduğunu unutmayın.
3. Göndermeyi alıma ve alımayı göndermeye bağlayın ve toprakları birleştirin;
   ortak toprak en sık atlanan kısımdır.
4. Boşta durumun mantık 1 ve mantık 0'ın başlangıç bitini işaretlediğini
   doğrulayın, sonra veriye güvenmeden önce her iki uçtaki mantık düzeylerini
   denetleyin ve 5 V ile 3.3 V arasındaki hat için bir seviye dönüştürücü takın.

### I2C

1. SDA ve SCL'yi 2 kOhm ile 10 kOhm üzerinden beslemeye yukarı çekin ve saati
   yükseltmeden önce yükselme süresini veri yolu kapasitansine göre denetleyin.
2. Cihazları 7-bit adresle adresleyin ve birçok parçanın iki gerilim hattı için
   iki ayrı adres kullandığını unutmayın.
3. Adresi ve yazıç sırasını veri sayfasından okuyun, sonra diziye güvenmeden
   önce her ikisini analizörde doğrulayın.
4. Zamanlama diyagramında kurulum ve bekleme sürelerini denetleyin, ilk testte
   saati 100 kHz'in altında tutun ve takılı kalan veri yolunu SDA'yı aşağıda
   tutarak değil, dokuz saat darbesiyle sıfırlayın.

### SPI

1. Saati, ana girişi, ana çıkışı ve çip seçimini bağlayın ve her cihaza kendi
   seçim hattı verin.
2. Mod 0 ile başlayın: saat boşta düşük, veri yükselen kenarda örneklenir; sonra
   modu veri sayfasına göre doğrulayın.
3. İlk testte saati 1 MHz'in altında tutun, analizörde kenarlar yuvarlak
   görünüyorsa kabloları kısaltın ve halkalanmayı sönümlemek için saat ve veri
   hatlarına 22 ila 33 Ohm seri direnç takın.
4. Veri sayfasında tam çift yönlü zamanlamayı okuyun; çip seçimin etkinleşmesi
   ile ilk saat kenarı arasındaki gecikmeyi de kapsayın.

## Güvenlik Notları

- Mantık analizörleri ve pek çok geliştirme kartı toprağını ana bilgisayarın
  toprağına bağlar; bu yüzden yüksek gerilimli ya da şebeke devresine prob vurmak
  analizörü tahrip edip yangın çıkarabilir.
- Bir veri yolunu bağlamadan önce her iki ucun besleme hatlarını denetleyin; 3.3 V
  giriş süren bir 5 V çevre birimi denetleyiciyi tahrip edebilir.
- Canlı bir motor ya da ısıtma devresine, gerilim için uygun bir diferansiyel
  prob olmadan asla prob vurmayın.
- İki cihaz arasında ortak toprak bulundurun; yüzen toprak yanlış veri verir ve
  portlara zarar verebilir.
- I2C yukarı çekmelerini kablolamanın izin verdiği ölçüde kısa tutun; çünkü uzun
  ve sonlandırılmamış bir hat yayar ve aralıklı arızalar üretir.
- Kısa devre olmuş tek bir hat, veri yolundaki her cihazı düşürür; bu yüzden
  kablolamayı değiştirmeden önce o bölümün gücünü kesin.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- NXP and Analog Devices Interface Notes (kamu malı)
