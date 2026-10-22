# Mikrodalga Kontrol Elektroniği

> **Domain:** quantum | **Difficulty:** master | **Safety:** yellow

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Bir kübite verilen her şey biçimlendirilmiş bir mikrodalga darbesi olarak gelir.
Temel ilke şudur: bir darbe zarfı, fazı ve nanosaniye ölçeğinde zamanlamasıyla
tanımlanır; bu yüzden kontrol elektroniği, genlik yüz kat tarama sırasında fazı
ve frekansı sabit tutmalıdır. Elektronikteki her titreşim doğrudan kübitte bir
hata olarak görünür.

## Ön Koşullar

- Mikrodalga mühendisliği: yayılım, karıştırma ve empedans
- Dijital sinyal işleme ve IQ modülasyonu
- Saatleme, titreşim ve faz kilitli döngüler
- RF topraklama, kalkanlama ve güvenlik uygulamaları

## Malzemeler ve Aletler

- En az iki kanallı bir keyfi dalga formu üreteci
- IQ karıştırıcılar ve her kanal için bir alçak geçiren süzgeç seti
- Faz kilitli döngüsü ve düşük gürültülü referansı olan bir yerel osilatör
- Koaksiyel kablo, sönücüler ve DC ayırıcılar
- Seviyeleri ayarlamak için bir güç ölçer ve bir spektrum analizörü

## Uygulama

### Darbe Setini Planlayın

1. Cihazın ihtiyaç duyduğu her işlemi listeleyin: bir pi darbesi, bir okuma
   darbesi, bir Ramsey eko, bir sanal Z rotasyonu ve sıfırlama tonu.
2. Her darbe için genliği, Rabi salınım frekansından ve darbe uzunluğundan
   hesaplayın; pi radyanlık bir darbe alanının tam çevrimi verdiği kuralını
   kullanın.
3. Darbe uzunluğunu sürüş döngülerinin tam sayı katı olacak biçimde seçin ki zarf
   sonda artık ayarlama bırakmasın; her darbe için kalibrasyon sayılarını yazın
   ve deneyle birlikte saklayın.

### Sinyal Yolunu Kurun

1. Temel bant zarfını, bu zarfın en yüksek frekans bileşeninin en az iki katı bir
   örnekleme hızında üretin.
2. Onu kübit frekansında bir yerel osilatörle karıştırarak tek yan bant sinyali
   oluşturun.
3. İstenmeyen yan bantı ve taşıyıcı sızıntısını gidermek için her kanalı
   süzün ve analizörde bastırma oranını ölçün.
4. Seviyeyi kübitte kalibre edilmiş bir sönücüyle ayarlayın; tipik olarak 10
   mikrowatt ile 1 miliwatt arasında olur ve ölçümü üreteçte değil kübitte alın.
5. Kabloları kısa tutun, zamanlamanın önemli olduğu yerde faz eşleştirilmiş kablo
   kullanın ve her kablonun koşular arasında hareket etmeyecek biçimde
   sabitlenmesini sağlayın.

### Eşitleyin ve Doğrulayın

1. Her kanalı tek bir ana referans saatten türetin ve o referansı her koşuyla
   birlikte veriye kaydedin.
2. Tetikleme yolunun titreşimini ölçün ve en kısa darbenin 1%'inin altında
   tutun.
3. Yerel osilatörün faz gürültüsünü karakterize edin ve onu kübitte görülen
   faz kaymasıyla ilişkilendirin.
4. Her çalışma oturumunun başında bir Rabi taraması ve bir Ramsey dizisi
   çalıştırın, frekansı ve genliği kayıtla karşılaştırın, sonra ham zarf
   örneklerini sonuçların yanına kaydedin.

## Güvenlik Notları

- Bir mikrodalga yükselticisi, mikrowatt düzeyinde ölen bir cihaza onlarca
  miliwatt verebilir; bu yüzden her zaman en düşük çıkışla başlayın ve yansıyan
  gücü izlerken kademeli olarak artırın.
- 5 GHz'de yayılan güç yanma yol açar ve dokuyu içeriden ısıtır; asla anteni bir
  kişiye doğrultmayın ve çıkış konnektörünü canlı kabul edin.
- Gevşek bir konnektör ya da hasarlı bir kablo ark yapar ve yangın
  başlatabilir; bu yüzden tork sınırlı konnektörler kullanın ve her kablonu yük
  altında denetleyin.
- Bir topraklama hatası RF'yi kablo kalkanına koyar; kalkan sonra raf içinden bir
  yol bulur ve cihaza zarar verebilir.
- DC ayırıcılar ve bias tee'ler frekans için anma değerli olmalıdır; sıradan bir
  DC ayırıcı mikrodalga gücünde ark yapar.
- Güçlü bir yükselticinin üzerinde asla kablo değiştirmeyin; bazı yükselticiler
  başlamadan önce belirli bir sonlandırma ister.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- NIST Quantum Initiative Reference (kamu malı)
