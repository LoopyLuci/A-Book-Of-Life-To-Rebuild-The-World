# Trình biên dịch, trình liên kết và hệ thống build

> **Domain:** computers | **Difficulty:** journeyman | **Safety:** green

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Một lần build biến mã nguồn thành tệp nhị phân qua các giai đoạn thường bị
giấu đi: tiền xử lý, biên dịch ra assembly, assembly thành tệp đối tượng, và
liên kết các tệp đối tượng thành tệp thực thi. Biết rõ từng giai đoạn biến
bộ công cụ từ một điều bí ẩn thành một công cụ, vì phần lớn các lỗi gây bối
rối — một ký hiệu thiếu, một cú nhảy đột ngột về kích thước, một tệp nhị phân
khác nhau giữa các máy — đều thuộc về một giai đoạn và có một cách sửa. Nguyên
tắc cốt lõi là mọi giai đoạn đều tạo ra một sản phẩm trung gian có thể đọc
được, nên một lần build luôn phải có thể kiểm tra chứ không phải một hộp đen.

## Điều kiện tiên quyết

- Lập trình C và bộ tiền xử lý
- Lập trình C nhúng
- Dùng dòng lệnh và trình soạn thảo văn bản
- Kiến thức cơ bản về tệp và thư mục

## Vật liệu & Dụng cụ

- Bộ công cụ GNU: trình biên dịch, trình hợp dịch, trình liên kết, trình lưu
  trữ, objdump, nm, size
- GNU Make, hoặc một trình điều khiển build khác
- Một dự án nhỏ gồm một file header, hai file nguồn và một chương trình kiểm thử
- Trình xem tệp đối tượng và tệp hex, cùng một hệ thống quản lý phiên bản
- Một thư mục build tách riêng khỏi cây mã nguồn
- Một tệp manifest ghim phiên bản trình biên dịch và các cờ biên dịch

## Quy trình

### Theo dõi từng giai đoạn

1. Chạy riêng bộ tiền xử lý và đọc đầu ra của nó, rồi biên dịch ra assembly và
   đọc phần đó, để bạn biết lỗi đến từ giai đoạn nào.
2. Tạo các tệp đối tượng và xem các tiêu đề phần: phần text, data, dữ liệu
   chỉ đọc và bss, cùng bảng ký hiệu.
3. Liên kết các tệp đối tượng thành tệp thực thi và xem điểm vào và bản đồ thể
   hiện trình liên kết đã đặt cái gì ở đâu.

### Kiểm soát bản build

1. Viết một makefile với các quy tắc tường minh, các mục tiêu phony, và một
   file phụ thuộc cho mỗi file nguồn, để một thay đổi trong header sẽ build
   lại mọi file có chứa nó.
2. Giữ một mục tiêu cho mỗi đầu ra và lệnh biên dịch trong một biến duy nhất,
   để không quy tắc nào mâu thuẫn về các cờ biên dịch.
3. Bật các phần theo từng hàm và tuỳ chọn trình liên kết loại bỏ các phần
   không dùng, rồi đo mức thay đổi trong tệp bản đồ.

### Liên kết có chủ đích

1. Chọn liên kết tĩnh hay động cho từng thành phần, và lưu ý rằng một thư viện
   dùng chung tạo thêm phụ thuộc phiên bản cho mọi máy chạy nó.
2. Nêu rõ điểm vào, các file khởi động, ngăn xếp và vùng nhớ động trong script
   liên kết thay vì chấp nhận mặc định.
3. Liệt kê các ký hiệu còn lại trong tệp nhị phân và loại bỏ những ký hiệu chỉ
   cần cho việc gỡ lỗi trước khi phát hành.

### Làm cho bản build có thể tái lập

1. Cố định phiên bản bộ công cụ, các cờ biên dịch và môi trường trong một tệp
   manifest mà bản build đọc, để mọi máy biên dịch theo cùng một cách.
2. Loại bỏ đường dẫn tuyệt đối khỏi các tệp đối tượng bằng cờ ánh xạ lại đường
   dẫn nguồn, và đặt biến source date epoch thành một giá trị cố định.
3. Build cùng một commit hai lần trên hai máy khác nhau và so sánh tổng kiểm
   của các đầu ra; chúng phải giống hệt nhau.

## Lưu ý an toàn

- Một kịch bản build chạy mã tuỳ ý với quyền của bạn. Chỉ build từ mã nguồn mà
  bạn đã đọc và tin tưởng, và xem xét mọi file build mới trước khi chạy nó.
- Một quy tắc make xoá tệp có thể bị kích hoạt do gõ sai tên mục tiêu. Hãy
  để các lệnh phá huỷ ra khỏi quy tắc, hoặc bảo vệ chúng bằng một lời nhắc,
  và không bao giờ chạy một makefile không tin cậy với quyền quản trị.
- Không tắt bộ bảo vệ ngăn xếp, các kiểm tra nguồn fortify, hoặc cảnh báo để
  cho một bản build chạy được; mỗi thứ trong số đó bắt được một lỗi thật.
- Thông tin gỡ lỗi và bảng ký hiệu trong tệp nhị phân đã phát hành tiết lộ đường
  dẫn tệp, tên người dùng và cấu trúc nội bộ. Hãy loại bỏ chúng trước khi
  phát hành.
- Ghim phiên bản bộ công cụ và ghi lại nó cùng bản build, vì một lần nâng cấp
  trình biên dịch có thể thay đổi kết quả số thập phân, bố cục struct và kết
  quả tối ưu hoá mà không cần thay đổi mã nguồn.
- Hãy theo dõi dung lượng đĩa và thời gian build; một lệnh include bị lặp vô
  hạn hoặc một vòng lặp phụ thuộc không có điểm dừng có thể lấp đầy ổ đĩa và làm
  tắc nghẽn.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- GNU Toolchain Manual (phạm vi công cộng)
