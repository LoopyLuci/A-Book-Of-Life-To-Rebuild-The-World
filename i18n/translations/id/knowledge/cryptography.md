# Kriptografi

> **Domain:** knowledge | **Difficulty:** journeyman | **Safety:** green

*Hanya materi referensi. Verifikasi informasi ini pada sumber primer dan
tenaga profesional yang berkualifikasi sebelum bertindak berdasarkannya. Entri
ini bukan satu-satunya sumber informasi.*

## Ikhtisar

Kriptografi melindungi pesan dan identitas ketika saluran tidak aman. One-time
pad memberi kerahasiaan yang mustahil ditembus; hash memverifikasi integritas.

## Prasyarat

- Tidak ada

## Bahan & Alat

- Tabel one-time pad
- Pensil dan kertas
- Tabel checksum

## Prosedur

### One-Time Pad

1. Bangun kunci yang benar-benar acak dengan panjang sama dengan pesan.
2. Tambahkan kunci ke teks asal modulo 26 untuk mengenkripsi; kurangi untuk
   mendekripsi.
3. Hancurkan setiap kunci setelah satu kali pakai.

### Integritas

1. Tambahkan hash atau checksum untuk mendeteksi manipulasi.
2. Verifikasi dengan rahasia bersama bila memungkinkan.

## Catatan Keselamatan

- Jangan pernah memakai ulang one-time pad; pemakaian ulang membuatnya bisa
  ditembus.
- Pisahkan kunci dari pesan.

## Verifikasi

- **Status:** draft
- **Diuji oleh:** —
- **Tanggal:** —

## Sumber

- Public-domain cryptography primers (domain publik)
- NIST cryptographic guidelines (domain publik)
