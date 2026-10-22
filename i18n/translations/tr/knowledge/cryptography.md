# Kriptografi

> **Domain:** knowledge | **Difficulty:** journeyman | **Safety:** green

*Yalnızca referans materyalidir. Bu bilgileri uygulamadan önce birincil
kaynaklarla ve yetkin uzmanlarla karşılaştırarak doğrulayın. Bu kayıt bilginin
tek başına kaynağı değildir.*

## Genel Bakış

Kriptografi, kanallar güvenli olmadığında mesajları ve kimliği korur. Tek
kullanımlık pad'ler kırılamaz gizlilik sağlar; özet değerler bütünlüğü doğrular.

## Ön Koşullar

- Yok

## Malzemeler ve Aletler

- Tek kullanımlık pad tabloları
- Kalem ve kâğıt
- Sağlama toplamı tabloları

## Uygulama

### Tek Kullanımlık Pad

1. Mesajla aynı uzunlukta gerçekten rastgele ana malzeme üretin.
2. Şifrelemek için anahtarı açık metne mod 26 ekleyin; çözmek için çıkarın.
3. Her anahtarı bir kez kullandıktan sonra imha edin.

### Bütünlük

1. Kurcalamayı algılamak için metnin sonuna bir özet veya sağlama toplamı
   ekleyin.
2. Mümkünse paylaşılan bir sırla doğrulayın.

## Güvenlik Notları

- Bir tek kullanımlık pad'i asla yeniden kullanmayın; yeniden kullanım onu
  kırılabilir hâle getirir.
- Anahtarları mesaj kadar özenle koruyun.

## Doğrulama

- **Durum:** draft
- **Test eden:** —
- **Tarih:** —

## Kaynaklar

- Public-domain cryptography primers (kamu malı)
- NIST cryptographic guidelines (kamu malı)
