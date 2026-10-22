# Ngôn ngữ assembly và mô hình máy

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Assembly là dạng văn bản của những gì bộ xử lý thực sự thực thi. Nó cho
thấy máy di chuyển dữ liệu giữa các thanh ghi và bộ nhớ ra sao, nó rẽ nhánh
ra sao, và ngăn xếp được dùng ra sao, điều đó làm cho nó trở thành công cụ
đúng đắn cho những phần của hệ thống mà không thể lãng phí thời gian hay bộ
nhớ. Nguyên tắc cốt lõi là kiến trúc là một hợp đồng: cách mã hoá lệnh, tập
thanh ghi và quy ước gọi đều là cố định, nên mã nguồn tuân thủ chúng vẫn đúng
qua các trình biên dịch, thư viện và các bản sửa đổi trong tương lai.

## Điều kiện tiên quyết

- Lập trình C nhúng
- Hệ nhị phân và thập lục phân
- Logic Boole và biểu diễn số bù hai (two's complement)
- Đọc bản đồ bộ nhớ và datasheet của bộ xử lý

## Vật liệu & Dụng cụ

- Board Cortex-M có đầu dò gỡ lỗi, hoặc máy chủ có trình dịch ngược
- Bộ công cụ ARM GCC, gồm tiện ích objdump và nm
- Sổ tay tham khảo cho tập lệnh và bản đồ bộ nhớ
- Trình soạn thảo văn bản có chế độ xem thập lục phân
- Máy phân tích logic để quan sát định thời chân và bus
- Một kịch bản kiểm thử hoặc chương trình terminal đưa vào một đầu vào đã biết

## Quy trình

### Học tập lệnh

1. Liệt kê tập thanh ghi của kiến trúc: 13 thanh ghi đa dụng từ R0 đến R12,
   cộng con trỏ ngăn xếp, thanh ghi liên kết và bộ đếm chương trình, cùng các
   cờ trạng thái mang dấu, bằng không, nhớ và tràn.
2. Ghi lại các chế độ địa chỉ, từ thanh ghi và tức thời, qua thanh ghi có độ
   lệch và gián tiếp qua thanh ghi, tới đẩy và bật ra ngăn xếp, kèm một ví dụ
   một dòng cho mỗi chế độ.
3. Ghi nhớ các cách mã hoá: lệnh 16-bit ở mã hoá cơ bản, lệnh 32-bit ở mã hoá
   rộng, và lệnh 32-bit phải nằm trên ranh giới 4-byte.

### Đọc một bản dịch ngược

1. Biên dịch một hàm C nhỏ kèm thông tin gỡ lỗi và dịch ngược nó bằng tiện
   ích objdump, rồi khớp từng dòng C với các lệnh của nó.
2. Nhận ra phần mở đầu lưu các thanh ghi, phần thân, và phần kết thúc khôi
   phục chúng rồi trả về qua thanh ghi liên kết.
3. Tìm kích thước khung ngăn xếp trong bảng liệt kê và xác nhận nó khớp với
   điều trình biên dịch báo cho cùng hàm đó.

### Viết một routine

1. Viết một hàm bằng assembly nhận hai đối số trong hai thanh ghi đầu tiên và
   trả kết quả trong thanh ghi đầu tiên, tuân theo quy ước gọi hàm.
2. Giữ con trỏ ngăn xếp cân bằng 8-byte ở mọi ranh giới lời gọi và kiểm tra
   sự căn chỉnh trước khi trả về.
3. Kiểm thử routine này so với một bản triển khai C trên nhiều đầu vào và so
   sánh kết quả từng giá trị một.

### Kết hợp với C và đo đạc

1. Chỉ đánh dấu một routine là naked ở nơi thật sự cần, và để trình biên dịch
   quản lý các thanh ghi quanh lời gọi ở mọi nơi khác.
2. Đo số chu kỳ bằng bộ đếm chu kỳ của lõi và so sánh với cùng công việc viết
   bằng C ở mỗi mức tối ưu.
3. Đọc tệp bản đồ của trình liên kết để xem phần flash và RAM đã tiết kiệm
   được bao nhiêu, và chỉ giữ lại ở nơi mức tiết kiệm đáng với công sức bảo
   trì.

## Lưu ý an toàn

- Một routine viết bằng assembly có thể đưa một chân đầu ra về bất kỳ trạng
  thái nào ngay khi nó chạy, và một vòng lặp vô hạn bên trong trình xử lý
  ngắt sẽ kích hoạt watchdog hoặc treo máy. Hãy kiểm chứng mã mới với bộ
  cơ cấu chấp hành đã tháo rời.
- Ghi vào sai địa chỉ trong assembly sẽ làm hỏng bộ nhớ và thanh ghi ngoại vi
  mà không có cảnh báo. Hãy đối chiếu mọi địa chỉ với bản đồ bộ nhớ trước khi
  ghi, và xác nhận vùng đó thực thi được và không bị bảo vệ.
- Tôn trọng các quy tắc căn chỉnh của lõi; một truy cập 32-bit lệch căn chỉnh
  sẽ gây lỗi trên một số thiết bị và âm thầm tốn chu kỳ trên những thiết bị
  khác.
- Chế độ chạy từng bước làm thay đổi định thời của chương trình, nên đừng gỡ
  lỗi một vòng lặp điều khiển bằng cách chạy từng bước. Hãy dùng bộ đệm
  truy vết hoặc máy phân tích logic thay thế.
- Hãy luôn sẵn có phép reset phần cứng, một bootloader hoặc một ảnh khôi
  phục, và kiểm thử đường khôi phục trước khi phụ thuộc vào nó.
- Mặc định coi assembly là không thể bảo trì: giữ nó ngắn gọn, có chú thích về
  cách dùng thanh ghi, và có bài kiểm thử tham chiếu bằng C bao phủ.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- Arm Cortex-M Documentation (phạm vi công cộng)
