# Kuantum Devre Kurulumu

> **Domain:** quantum | **Difficulty:** apprentice | **Safety:** green

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Kuantum devre yazılı bir tarifdir: bir kübit listesine uygulanan kapıların
listesi ve ardından ölçümler. Temel ilke, yazdığınız devrenin çalışan devre
olmadığıdır; çünkü derleyici önce onu donanımın gerçekte sahip olduğu kapılara
ve bağlantılara eşlemek zorundadır. Bu eşlemenin okunmasını ve iki devrenin
birbirine yakın tutulmasını öğrenmek pratik beceridir.

## Ön Koşullar

- Karmaşık vektörler ve matris çarpımı
- Bloch küresi ve tek kübit kapıları
- Temel Python veya başka bir betik dili
- Kuantum devrenin kuralları: kopyalama yoktur ve ölçüm yok eder

## Malzemeler ve Aletler

- Qiskit, Cirq veya Braket gibi bir kuantum SDK'sı
- Küçük devreler için, yaklaşık 20 kuite kadar durum vektörü simülatörü
- Bir donanım arka ucu ve yayımlanmış kalibrasyon verileri
- Devreyi ve beklenen çıktısını içeren bir defter veya dosya
- Hedef cihazın gürültü modelinin yerel bir kopyası

## Uygulama

### Devreyi Yazma

1. Tek bir kapı yazmadan önce devrenin yanıtladığı soruyu belirtin.
2. Devreyi katman katman, her seferinde bir kapı ekleyerek kurun ve tellerin
   kastettiğiniz kübitler olduğunu doğrulamak için çizin.
3. Kapı sayısını az tutun ve üst üste binen birkaç çift yerine tek bir dolanık
   çifti tercih edin.
4. Ölçümleri en sona ekleyin ve erken ölçüm yapmanın devrenin geri kalanı için
   durumu yok ettiğini unutmayın.

### Derleme

1. Devreyi hedef arka uç için transpiler'dan geçirin ve yerel tabanı ile
   eşlemeyi onun seçmesine izin verin.
2. Derleyicinin seçtiği yerleşime bakın: ızgara veya ağır-altıgen (heavy-hex)
   bağlantı düzeninde uzak kübitler, hata ekleyen swap kapılarıyla bağlanır.
3. Devrenin doğal bir geometrisi varsa başlangıç yerleşimini kendiniz seçin ve
   iki seçimin kapı sayılarını karşılaştırın.
4. En iyileştirme düzeyini 1 veya 2 olarak ayarlayın, sakladığınız koşuyu hangi
   düzeyin ürettiğini kaydedin ve zamanlanmış darbe sürelerini denetleyin;
   çünkü derleyici kübitin kaydığı boşluklar ekleyebilir.

### Çalıştırma ve Sonucun Okunması

1. Devreyi birçok kez çalıştırın ve sonuçları sayın; tek bir koşu size neredeyse
   hiçbir şey söylemez.
2. Histogramı ideal simülasyonla karşılaştırın ve farkı bir izlenim olarak
   değil, bir sayı olarak belirtin.
3. İş meta verisinde cihazın kalibrasyon tarihini denetleyin ve kalibre
   edilmemiş bir cihazdan sayı bildirmeyi reddedin.
4. Devreyi, derlenmiş sürümünü, tohum değerini ve sayımları birlikte kaydedin,
   farklı bir tohumla yeniden çalıştırın ve herhangi bir sonuca varmadan önce
   istatistiklerin örtüştüğünü doğrulayın.

## Güvenlik Notları

- Bir simülatör makinenin belleğini tüketebilir: bir durum vektörü kübit başına
  16 bayt gerektirir, dolayısıyla 30 kübit 16 terabayt demektir; bunun yerine
  kararlayıcı (stabilizer) veya yoğunluk matrisi yöntemleri kullanılmalıdır.
- Kapılarında gizli bir anahtar barındıran bir devreyi, gözden geçirmeden
  paylaşılan bir cihaza asla göndermeyin; çünkü bir devre, kendisinin kurulduğu
  veri hakkında çok fazla şey ele verir.
- Donanımda çalıştırmak sıra süresi harcar ve makineyi soğutur; bu yüzden
  devreleri toplu gönderin ve cihazı başkalarına bırakın.
- Ölçüm yıkıcıdır ve erken ölçüp ardından kübiti yeniden kullanan bir devre,
  hata mesajı yerine yanlış bir yanıt verir.
- Cihaz adı, kalibrasyon tarihi ve koşu sayısı olmadan donanım sonucunu
  bildirmeyin; hiçbiri sonradan elde edilemez.
- Gürültüsüz bir simülatör, çalışamayan bir devre için bile kusursuz bir sonuç
  göstermeyi memnuniyetle yapacaktır; bu yüzden sayıları hangisinin ürettiğini
  her zaman belirtin.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- NIST Quantum Initiative Reference (kamu malı)
