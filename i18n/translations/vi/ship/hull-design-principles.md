# Nguyên tắc thiết kế thân tàu

> **Domain:** ship | **Difficulty:** apprentice | **Safety:** green

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Thân tàu là sự thỏa hiệp giữa thể tích nó phải chở, lực cản nó tạo ra trong
nước, và cách nó cư xử trong biển động. Nguyên tắc cốt lõi là thiết kế bắt
đầu từ trọng lượng chứ không phải từ chiều dài: mức nước là bất cứ điều gì
con tàu nặng, và hình dạng thân dưới nước sau đó quyết định trọng lượng ấy
tốn bao nhiêu sức để chuyển động. Độ đầy và beam tàu mua lại sự ổn định và
không gian hàng hoá và trả bằng lực cản, nên mọi lựa chọn đều là một sự đánh
đổi phải được cân đo.

## Điều kiện tiên quyết

- Định luật Archimedes và ý nghĩa của mức nước
- Lượng giác cơ bản cho các hệ số hình thức và các khoảng cách đo
- Đọc bản vẽ tỷ lệ và dùng thước toả với đường cong mượt (spline)
- Từ vựng của biển: chiều cao mớn, chiều cao khô, beam và độ nghiêng

## Vật liệu & Dụng cụ

- Giấy vẽ tỷ lệ, bàn vẽ, thước toả và đường cong mượt
- Máy đo diện tích, hoặc phương pháp lưới để đo diện tích trên bản vẽ
- Số liệu thuỷ tĩnh cho nước biển ở 1025 kg/m3 và nước ngọt ở 1000 kg/m3
- Bảng tra hệ số khối, hệ số thể tích và hệ số mặt nước
- Số liệu lực cản và cách ước lượng số vòng quay chân vịt
- Bảng trọng lượng và mô men, và khuôn đánh dấu chiều cao nước

## Quy trình

### Xác định yêu cầu

1. Liệt kê tải trọng hữu ích, thuyền viên, nhiên liệu và dự trữ; tổng của
   chúng là trọng tải.
2. Cộng thêm trọng lượng tàu rỗng cho kết cấu, máy tành và trang thiết bị,
   rồi chia tổng cho mật độ nước để có thể tích thân tàu phải dịch chuyển
   dưới mực nước.
3. Chọn chiều dài toàn tàu và mức nước từ hàng hoá, và giữ tỷ lệ chiều dài
   trên beam trong khoảng 4:1 tới 6:1 cho tàu đa dụng.

### Chọn hình thức

1. Tính hệ số khối bằng thể tích dịch chuyển chia cho L x B x T, với T là
   chiều cao mớn, và hướng tới 0.4 tới 0.6 cho một tàu chuyển vận theo mức
   nước.
2. Hướng tới hệ số thể tích 0.55 tới 0.75 và hệ số mặt nước 0.6 tới 0.8, và
   nhớ rằng một hình thức đầy hơn, tới khoảng 0.8, chở nhiều hơn nhưng tạo
   nhiều lực cản hơn.
3. Cân đối sự đánh đổi: beam rộng hơn và độ đầy hơn làm tăng mô-men hồi phục
   và thể tích hàng hoá, và đổi lại bằng lực cản và chuyển động trong biển.

### Dựng các đường

1. Vẽ các đường ngang (buttocks) khoảng bốn vị trí trên một chiều dài thân
   tàu, và vẽ các đường nước ở mớn thiết kế, mớn tải và hai đường nữa cao hơn.
2. Đặt đường gốc, kheo tàu, mũi và trụ lái, mép boong và đường cong boong, dùng
   quy tắc 10-90-10 cho hai đầu, với 10% chiều dài phía trước và phía sau các
   đường vuông góc và 90% ở giữa.
3. Vuốt các thiết diện bằng đường cong mượt và kiểm tra rằng độ cong của mỗi
   đường liên tục và các thiết diện chạy mượt với nhau.

### Ước lượng công suất

1. Ước lượng lực cản ma sát bằng 0.5 x rho x V^2 x S x C_f, với C_f là 0.075
   chia cho bình phương của (log10(L) - 2) cho một thân tàu trơn ở số Reynolds
   trên 1e7.
2. Cộng lực cản dư, tính 15% tới 40% tổng cho một tàu chuyển vận theo mức
   nước ở tốc độ trung bình.
3. Ước lượng công suất trục bằng lực cản nhân tốc độ chia cho hiệu suất tổng,
   0.35 tới 0.50 cho một máy diesel nhỏ có chân vịt, rồi quy đổi sang số vòng
   quay chân vịt mỗi phút.

## Lưu ý an toàn

- Đây là một bài tập trên bàn vẽ, nhưng các con số nó tạo ra quyết định khả
  năng nổi: hãy kiểm tra độ ổn định và chiều cao khô với hàng hoá đã lên tàu,
  không phải với trạng thái tàu rỗng.
- Không bao giờ làm việc một mình trên một thân tàu đang nổi; hãy dùng thang
  và dây an toàn, và giữ áo phao trong tầm tay.
- Nước lạnh và chết đuối là những nguy cơ thật sự trên tàu, và lật tàu trong
  khoang kín kết thúc rất nhanh.
- Giữ chiều cao khô đủ cao để mép boong vẫn khô trong biển chạy theo phía sau.
- Kiểm tra lại độ ổn định sau mỗi lần thay đổi trọng lượng, kể cả khi đổi
  thuyền viên hay đổi vật tư.
- Không duyệt một mức nước hay một chiều cao mớn mà không có biên an toàn; mật
  độ nước biển thay đổi theo nhiệt độ và độ mặn.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- US Navy Hull Design Principles (phạm vi công cộng)
