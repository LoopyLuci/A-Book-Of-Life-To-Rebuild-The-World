# Akü Temelleri

> **Domain:** energy | **Difficulty:** journeyman | **Safety:** red

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Aküler elektrik enerjisini kimyasal olarak depolar. Kurulabilirliği en yüksek
kimya kurşun-asittir; lityum iyon daha yoğundur ancak sıfırdan üretilmesi daha
zorludur.

## Ön Koşullar

- [Metal Ergitme](../../../../domains/materials/metal-smelting.md)
- [Kimya](../../../../domains/materials/chemistry.md)

## Malzemeler ve Aletler

- Kurşun plakalar (ızgara + aktif madde)
- Sülfürik asit (30% H₂SO₄)
- Kabuk (plastik veya sert lastik)
- Ayırıcılar (gözenekli lastik, cam mat)
- Terminaller

## Uygulama

### Kurşun-Asit Hücre (hücre başına 2 V)

1. Kurşun ızgaraları dökün; kurşun oksitle (pozitif) ve sünger kurşunla
   (negatif) macunlayın.
2. Ayırıcılarla birlikte plakaları sırayla istifleyin.
3. Terminalleri kaynak bağlarıyla birleştirin.
4. 30% sülfürik asit ile doldurun.
5. **Biçimlendirme şarjı:** macunları dönüştürmek için 24 saat yavaş şarj
   yapın.

### 6 Hücre = 12 V Akü

- Seri bağlı 6 hücre → 12 V anma gerilimi.
- Kapasite: Ah = plaka alanı × plaka sayısı.

### Şarj

1. **Ana şarj:** sabit akımla 14.4 V'a kadar.
2. **Dengeleme:** akım kapasitenin 3% seviyesine düşene kadar 14.4 V sabit
   gerilimde.
3. **Saklama:** korumayı sürdürmek için 13.6 V.

### Bakım

- Ayda bir saf su ile seviyeyi tamamlayın.
- Her 1-3 ayda bir dengeleyin (15.5 V ile 2 saat).
- Asla 50% seviyesinin (12.1 V) altına boşalmayın.
- Terminalleri temiz tutun; greslendirin.

### Diğer Kimyalar

- **NiFe (Edison):** hücre başına 1.2 V; neredeyse yok edilemez; verim düşük.
- **NiCd:** hücre başına 1.2 V; kadmiyum zehirli.
- **LiFePO₄:** hücre başına 3.2 V; güvenli; BMS gerektirir.

## Güvenlik Notları

- **Kırmızı tehlike:** Sülfürik asit yakar. Kurşun nörotoksiktir. Eldiven,
  gözlük ve önlük giyin. Açık havada çalışın.
- Şarj sırasında **patlayıcı hidrojen** oluşur — havalandırın.
- Terminalleri asla kısa devre yapmayın; kutupları asla ters çevirmeyin.
- Kurşunu ve asidi doğru biçimde imha edin.

## Doğrulama

- **Durum:** peer-reviewed
- **Tarih:** 2026-05-01

## Kaynaklar

- US DOE Battery Handbook (kamu malı)
- US Army Battery Manual (kamu malı)
