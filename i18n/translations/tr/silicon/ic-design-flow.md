# Entegre Devre Tasarım Akışı

> **Domain:** silicon | **Difficulty:** master | **Safety:** yellow

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Bir entegre devre, yazılı bir şartnameden bir dökümhanenin maskeleyebileceği bir
GDSII yerleşimine doğru ilerler. Temel ilke şudur: her aşama bir doğrulama
kapısıdır; önceki aşama kanıtlanmadan hiçbir şey ilerlemez, çünkü bir kusurun
maliyeti her adımda, yeniden derlemeden tüm çipin yeniden üretilmesine kadar
sert biçimde artar. Tasarım bu yüzden esas olarak kanıtlar üzerine bir argümandır
ve hayatta kalan şey, neyin, ne zaman ve hangi araç sürümüyle denetlendiğinin
arşividir.

## Ön Koşullar

- Dijital tasarım ve Boole mantığı
- Zamanlama analizi: kurulum, bekleme, saat kayması ve kritik yol
- Verilog ya da VHDL ve aşağıda adı geçen simülatör ile sentez araçları
- Bir teknoloji tasarım kiti: standart hücreler, LEF ve GDEF, GDSII katmanları ve
  Liberty zamanlama
- Dallanma ve hakemli inceleme destekli sürüm denetimi

## Malzemeler ve Aletler

- Şartname ve doğrulama planı belgeleri
- RTL kaynakları, bir testbench ve dalga formu görüntüleyicili bir simülatör
- Standart hücre kitaplığı ve Liberty zamanlama dosyası olan bir sentez aracı
- Tasarım kitiyle yerleştirme ve yönlendirme aracı, ayrıca statik zamanlama
  analizi
- Signoff araçları: lint, CDC, DRC, LVS ve IR düşümü ile elektromigrasyon
  denetimleri
- Git deposu, bir sorun izleyici ve wafer maliyeti, die alanı, wafer başına die
  sayısı ile tek seferlik maske ve tasarım maliyetini kapsayan bir maliyet modeli

## Uygulama

### Şartname yazın ve RTL yazın

1. Şartnameyi yazın: arayüz, saat, verim, gecikme bütçesi, güç tavanı, die alanı
   tavanı ve maliyet tavanı.
2. RTL'den önce doğrulama planını yazın; iddiaları, köşe durumları ve kapsam
   hedeflerini kapsasın.
3. Şartnameyi dondurup kaydedin; böylece sonraki bir değişiklik kayma değil bir
   değişiklik olarak görünür.
4. RTL'yi yazın, testbench'i geçen bir regresyona kadar simüle edin ve genişlik
   uyuşmazlıkları, eksik atamalar ve çoklu sürücüler için lint çalıştırın.

### Sentezleyin ve Yerleştirin

1. Saat kısıtlarını, periyodu ve belirsizliği belirleyip sentezi hedef alan ve
   zamanlamaya göre çalıştırın.
2. Kritik yol raporunu ve güç tahminini okuyun: dinamik güç kabaca C x V^2 x f
   artı sızıntıdır.
3. Yerleşim planını aracın yapmasından önce siz yapın: bellekleri, analog blokları
   ve G/Ç halkasını yerleştirin ve güç şebkesi için yer bırakın.
4. Yerleştirmeyi, sonra saat ağacı eklemeyi, sonra yönlendirmeyi çalıştırın ve
   her aşamadan sonra kaymayı ve yönlendirme tıkanıklığını denetleyin.

### Signoff yapın ve maskeye gönderin

1. Kurulum ve bekleme için yavaş ve hızlı köşelerde statik zamanlama çalıştırın.
2. Boşluk, yoğunluk ve anten kuralları için DRC, şematikle LVS ve IR düşümü ile
   elektromigrasyon denetimlerini çalıştırın.
3. Her ihlali kapatın, sonra nadir zamanlama hatalarını ortaya çıkarmak için çok
   köşeli bir Monte Carlo çalıştırın.
4. GDSII'yi dışa aktarın, maske setini üretin, onu bir sağlama toplamı ve
   kullanılan araç sürümleriyle arşivleyin ve takvimi dengelemek için siparişi
   iki dökümhaneye bölün.

## Güvenlik Notları

- Buradaki tehlikeler proje tehlikeleridir: hakemli incelenmemiş bir maske
  gönderimi tüm maske setini ve onun arkasındaki parayı harcar.
- Kaynağı ve üçüncü taraf fikri mülkiyeti kilitleyin ve tasarım dosyalarını
  erişimi denetlenen bir depoda tutun; onlara ihracat kontrol kuralları uygulanır.
- Tekrarlanabilir derlemeler kullanın: araç sürümlerini, betikleri ve lisans
  durumunu kaydedin ki arşiv tam olarak yeniden kurulabilsin.
- Üçüncü taraf IP'yi kullanmadan önce doğrulayın; çünkü bir sert makrodaki ince
  bir hata pahalıdır ve bulunması zordur.
- Sipariş verilmeden önce signoff kontrol listesini şartnameye karşı ikinci bir
  kişinin denetlemesini sağlayın.
- GDSII'yi ve maske setini arşivleyin; kaybetmek maskeyi yeniden ödemek demektir.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- NIST Semiconductor Reference (kamu malı)
