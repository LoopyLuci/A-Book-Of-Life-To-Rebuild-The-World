# AC Devre Analizi ve Empedans

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Alternatif akımda gerilim ve akım artık birlikte yükselip alçalmaz; bu yüzden
gerilimin akıma oranı artık anlamlı bir sayı değildir. Temel ilke, her elemanı
empedansıyla değiştirmektir: empedans, bir direnç kısmı ile bir reaktans
kısmından oluşan karmaşık bir sayıdır; ardından DC'de çözülen devre
denklemlerinin tam olarak aynısı çözülür. Reaktansı frekans belirler; bu
yüzden sürekli durumda bir davranış gösteren devre 50 Hz'de tamamen farklı
olabilir.

## Ön Koşullar

- Kirchhoff yasaları ile seri ve paralel kurallar için DC Devre Analizi
- Dik ve kutup biçiminde karmaşık sayılar
- Sinüs ve kosinüs fonksiyonları, faz ve faz farkı
- Reaktif elemanlar için temel türev ve integral alma
- RMS, tepe ve tepe-tepe değerler arasındaki ilişki

## Malzemeler ve Aletler

- Bir fonksiyon jeneratörü ve bir osiloskop
- Bir masa tipi güç kaynağı ve kapasite ölçüm aralığı olan dijital multimetre
- E12 ve E24 serisinden dirençler, kondansatörler ve bobinler
- Bir decade kutu ya da rezonans ve süzgeç çalışmaları için bir değer seti
- Bakır tel ve test bobini yapmak için bir makara
- Şebekeye bağlı her çalışma için bir izolasyon transformatörü

## Uygulama

### Devreyi Fazörlerle İfade Etme

1. Her direnci R ile, her kondansatör ve bobini ise reaktansıyla değiştirin:
   X_L = 2 x pi x f x L ve X_C = 1 / (2 x pi x f x C).
2. Her elemanın empedansını dik biçimde yazın: Z_R = R, Z_L = j X_L ve
   Z_C = -j X_C.
3. Empedansları seri bağlayın ve dalları DC'de kullanılan aynı kurallarla
   paralel birleştirin; j terimlerini ayrı tutarak sonucu kutup biçimine
   çevirin: büyüklük R^2 artı X^2'nin kare köküdür ve açı X'in R'ye oranının
   arktanjantıdır.

### AC Ağı Çözümü

1. Empedans ağına Kirchhoff yasalarını uygulayın ve fazör akım ve
   gerilimleri çözün.
2. Fazör sonuçları zaman domenine geri çevirin; bir sinüsün RMS değerinin
   tepe değerin 1.414'e bölümü olduğunu unutmayın.
3. Sonucu güç üzerinden doğrulayın: etkin güç P = V x I x cos(phi), reaktif
   güç Q = V x I x sin(phi) ve görünür güç volt-amper cinsinden S = V x I'dır.

### Rezonansın Bulunması

1. Reaktansları eşitleyin ve rezonans frekansını çözün:
   f0 = 1 / (2 x pi x sqrt(L x C)).
2. Yarı güç frekanslarını ölçün ve kalite faktörünü hesaplayın:
   Q = f0 / (f2 - f1); bunu seri dirence bölünmüş sqrt(L / C) ifadesiyle
   karşılaştırın.
3. Rezonansta devre akımının en büyük değere ulaştığını ve kondansatör
   uçlarındaki gerilimin besleme geriliminin Q katı olabileceğini not edin.

### Bir Süzgeç Tasarımı

1. Kesim frekansını şartnameden belirleyin ve basit bir RC alçak geçiren
   süzgeç için direnci hesaplayın: R = 1 / (2 x pi x f x C); ardından devreyi
   kurun.
2. Kesim frekansının 0.1, 1 ve 10 katında yanıtı ölçün ve çıkışın her on katta
   20 dB düştüğünü doğrulayın.
3. Kesim noktasındaki faz kaymasını doğrulayın; birinci dereceli bir süzgeçte
   bu 45 derecedir. Sönüm yeterince dik değilse ikinci bir kademe ekleyin.

## Güvenlik Notları

- Şebeke gerilimi öldürür. Beslemeye bağlı her devreyi ölümcül kabul edin ve
  yalnızca uygun eğitim, gözetim ve ekipmanla, izolasyon transformatörü
  kullanarak üzerinde çalışın.
- Kalbi durduran akım küçüktür: yaklaşık 0.5 mA algı eşiği, 10 mA bırakma
  eşiği, 30 mA solunumu durdurabilir ve 50 mA ventriküler fibrilasyona yol
  açabilir.
- Yüklü bir kondansatör, ölçüm cihazının empedansı çok yüksek olduğu için
  besleme kesildikten sonra da enerjisini korur; bir boşaltma direnci kullanın
  ve bir düğüme dokunmadan önce gerilimi ölçüm cihazıyla kanıtlayın.
- Bir rezonans devresi kondansatör uçlarında yüksek bir gerilim üretebilir;
  geri beslemeli ya da yükseltici bir dönüştürücü ise düşük gerilimli görünen
  bir düğüme yüzlerce volt yükleyebilir.
- Fonksiyon jeneratörü çıkışını ve masa tipi güç kaynağı çıkışlarını
  birbirinden yalıtın; bir sinyal kaynağını asla bir besleme çıkışının
  üzerine bağlamayın.
- Kondansatörlerin gerilim ve darbe akımı değerlerini denetleyin ve rezonans
  devresindeki bir kondansatörün uçlarındaki gerilimin besleme geriliminden
  çok daha yüksek olabileceğini unutmayın.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- OpenStax University Physics (CC BY)
