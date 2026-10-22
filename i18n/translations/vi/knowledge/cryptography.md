# Mật mã học

> **Domain:** knowledge | **Difficulty:** journeyman | **Safety:** green

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Mật mã học bảo vệ thông điệp và danh tính khi kênh truyền không an toàn. Bảng
mã một lần cho tính bảo mật không thể phá; hàm băm xác minh tính toàn vẹn.

## Điều kiện tiên quyết

- Không có

## Vật liệu & Dụng cụ

- Bảng mã một lần
- Bút chì và giấy
- Bảng tổng kiểm

## Quy trình

### Mã một lần

1. Sinh vật liệu khoá thật sự ngẫu nhiên có độ dài bằng thông điệp.
2. Cộng khoá vào bản rõ theo mod 26 để mã hoá; trừ để giải mã.
3. Huỷ mỗi khoá sau một lần dùng.

### Tính toàn vẹn

1. Gắn thêm một hàm băm hoặc tổng kiểm để phát hiện việc can thiệp.
2. Kiểm chứng bằng một bí mật dùng chung khi có thể.

## Lưu ý an toàn

- Không bao giờ dùng lại bảng mã một lần; dùng lại làm cho nó có thể bị phá.
- Bảo vệ khoá cẩn thận như bảo vệ chính thông điệp.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- Public-domain cryptography primers (phạm vi công cộng)
- NIST cryptographic guidelines (phạm vi công cộng)
