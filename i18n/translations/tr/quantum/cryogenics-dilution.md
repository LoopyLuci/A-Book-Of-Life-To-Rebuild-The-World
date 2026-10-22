# Kriyojenik ve Seyreltmeli Soğutma

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Seyreltme buzdolabı, süperakışkan ve normal helyumu karıştırarak bir numuneyi
birkaç milikelvine kadar soğutur ve ancak ısı yükü bütçesinin tamamı karşılandığında
bu sıcaklığı tutar. Temel ilke şudur: her kablo, her tel ve her yüzey yalıtımda
bir kaçak noktasıdır; bu yüzden tasarım büyük ölçüde mikrowatt cinsinden ısı
sayıp onu uzaklaştırmaktır. Numune sistemin en küçük parçasıdır; borular,
filtreleme ve kalkanlama ölçümün mümkün olup olmadığını belirler.

## Ön Koşullar

- Kriyojenik mühendislik temelleri ve helyumun faz diyagramı
- Süperakışkanlık ve helyum-3'ün helyum-4 içindeki seyreltilmesi
- Mikrodalga mühendisliği ve sönücü ile süzgeç zincirlerinin tasarımı
- Vakum uygulamaları, sızdırma denetimi ve güvenli kriyojen elleçleme

## Malzemeler ve Aletler

- Karıştırma odası ve bir kazanı olan seyreltme buzdolabı
- Kriyojenik aktarım hattı ve soğuk tuzağı olan vakum pompa seti
- Vakuma dayanıklı koaksiyel kablo, SMA ve SMP konnektörler ve ısı emiciler
- Sönücülerden oluşan bir mikrodalga zinciri ve her sinyal hattı için bir alçak
  geçiren süzgeç
- Süperiletken mıknatıs, bir termometre seti ve kalkanlı oda

## Uygulama

### Isı Yükünün Planlanması

1. Oda sıcaklığından karıştırma odasına geçen her hattı listeleyin ve sayın.
2. Her kablonun iletkenlik sıcaklık kaybını malzemenin termal iletkenliğinden
   Q = k A dT / L ile hesaplayın ve atlanmamış (sönücüsüz) tek bir koaksiyel
   hattın 4 K kademesine bir miliwatt'tan fazla taşıyabileceğini not edin.
3. Her kalkanın ışınım yükünü Q = sigma A (T_hot dördüncü - T_cold dördüncü)
   ile hesaplayın; burada sigma, kelvin dördüncüsü başına metrekare başına
   5.67e-8 W'dır.
4. Yükselticilerin sürüş soğutmasını ekleyin, toplamı karıştırma odasındaki
   soğutma gücüyle karşılaştırın (10 mK'de tipik olarak 10 ila 100 mikrowatt) ve
   en az yüzde 30'luk pay bırakın.

### Kabloların Hazırlanması

1. Her koaksiyel hattı 50 K kademesinde, 4 K kademesinde, kazanda ve karıştırma
   odasında, kademe başına yaklaşık 10 dB olacak biçimde sönücüyle sonlandırın.
2. Her sinyal hattı için 4 K kademesinde kesim frekansı yaklaşık 5 GHz olan bir
   alçak geçiren süzgeç ekleyin ve her DC ötürme hattında çok daha düşük, 700 MHz
   ya da altında bir kesim kullanın.
3. Her hattı bakır ya da alüminyum örgüyle kademelere sabitleyin; böylece ısı
   orada durur.
4. Hattın ve geçişin tamamını vakumla test edin ve sızdırma denetimi yapılmamış
   soğuk bir hattın vakum alanını asla kapatmayın.

### Soğutma ve Doğrulama

1. Helyumu ve vakum pompalarını öngörülen sırayla darbelayın ve vakum sağlanmış
   bir ısıtmayı asla yarıda bırakmayın.
2. Kademe sıcaklıklarını ve helyum seviyesini izleyin; dengelenme süresini ve
   nihai taban sıcaklığı kaydedin.
3. Işınım kalkanlarını yalnızca taban sıcaklığı kararlı olduktan sonra kapatın,
   sonra numuneyi aktarın ve numune tutucusundaki sıcaklığın termometreyle
   eşleştiğini doğrulayın.
4. Her soğuma için taban sıcaklığını, kademe sıcaklıklarını ve mikrodalga gürültü
   tabanını birlikte kaydedin.

## Güvenlik Notları

- Sıvı helyum ısıtıldığında büyük ölçüde genleşir ve kapalı bir hacmi
  patlatabilir; bu yüzden her soğuk hacmin bir tahliye yolu olmalı ve tahliye
  cihazları asla tıkanmamalı ya da tıkaçlanmamalıdır.
- Sıvı helyum ve sıvı azot donma yanıklarına yol açar ve odadaki oksijeni
  yerinden edebilir; iyi havalandırılmış bir alanda oda monitörüyle çalışın ve
  bir kriyojenle asla yalnız çalışmayın.
- Açılmış bir kriyojenik aktarım hattı, vakum hattına sıvı helyum enjekte
  ederek patlamaya (implosyon) yol açabilir; soğuk bir hattı atmosfere
  boşaltmayı, ona ilişkin prosedürü izlemeden asla yapmayın.
- Soğuk bir yüzeyde yoğuşan oksijen onu kırılganlaştırır ve her kriyojenik
  bağlantıyı bir parça tehlikesi hâline getirir; doğru metal conta kullanın ve
  soğuk bir birleşimi asla sıkmayın.
- Süperiletken bir mıknatıs enerji depolar ve uyarı vermeden quench olabilir;
  büyük bir alan açığa çıkarır ve kriyojeni kaynatır. Rampa sınırlarını belirleyin
  ve asla gözetimsiz enerjilendirilmiş bırakmayın.
- Bir vakum arızası ya da pompa yağının geri akması, soğuk bir kademeyi
  kirletip deneyi görünür bir uyarı olmadan mahvedebilir.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- NIST Cryogenics Guidance (kamu malı)
