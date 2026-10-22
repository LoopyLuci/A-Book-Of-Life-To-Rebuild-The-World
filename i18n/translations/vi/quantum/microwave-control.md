# Điện tử điều khiển vi sóng

> **Domain:** quantum | **Difficulty:** master | **Safety:** yellow

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Mọi việc một qubit được yêu cầu thực hiện đều tới dưới dạng một xung vi sóng
có hình dạng. Nguyên tắc cốt lõi là một xung được định nghĩa bởi bao hình,
pha và thời điểm tới mức nanosecond, nên điện tử điều khiển phải giữ pha và tần
số ổn định trong khi biên độ được quét qua một dải rộng cỡ trăm lần. Bất kỳ
thứ gì dao động trong điện tử đều xuất hiện trực tiếp thành lỗi trên qubit.

## Điều kiện tiên quyết

- Kỹ thuật vi sóng: truyền sóng, trộn và trở kháng
- Xử lý tín hiệu số và điều chế IQ
- Tạo đồng hồ, dao động (jitter) và vòng khoá pha
- Nối đất RF, tấm chắn và thực hành an toàn

## Vật liệu & Dụng cụ

- Máy phát dạng sóng tuỳ ý có ít nhất hai kênh
- Bộ trộn IQ và một bộ lọc thông thấp cho mỗi kênh
- Bộ dao động nội bộ có vòng khoá pha và nguồn tham chiếu nhiễu thấp
- Cáp đồng trục, bộ suy giảm và khối chặn DC
- Máy đo công suất và máy phân tích phổ để đặt mức tín hiệu

## Quy trình

### Lập kế hoạch bộ xung

1. Liệt kê mọi thao tác mà thiết bị cần: một xung pi, một xung đọc tín hiệu,
   một xung Ramsey echo, một phép quay Z ảo, và tần số đặt lại trạng thái.
2. Tính biên độ cho mỗi xung từ tần số dao động Rabi và độ dài xung, theo quy
   tắc một diện tích xung bằng pi radian tạo ra đảo cực hoàn toàn.
3. Chọn độ dài xung là một số nguyên chu kỳ kích thích để bao hình không để lại
   độ lệch tần số tàn dư ở cuối, và ghi lại các số hiệu chuẩn cho mọi xung
   cùng lưu chúng với thí nghiệm.

### Xây dựng đường tín hiệu

1. Sinh bao hình tần số cơ sở ở tốc độ lấy mẫu ít nhất gấp đôi thành phần
   tần số cao nhất trong bao hình đó.
2. Trộn nó với bộ dao động nội bộ ở tần số qubit để tạo tín hiệu chỉ dải đơn.
3. Lọc từng kênh để loại bỏ dải phụ không mong muốn và rò rỉ sóng mang, và đo
   mức loại bỏ trên máy phân tích.
4. Đặt mức tín hiệu tại qubit bằng một bộ suy giảm đã hiệu chuẩn, thường từ
   10 microwatt tới 1 milliwatt, và đo tại qubit chứ không đo tại máy phát.
5. Giữ cáp ngắn, dùng cáp cùng pha ở nơi thời gian quan trọng, và cố định mọi
   cáp để nó không thể dịch chuyển giữa các lần chạy.

### Đồng bộ và kiểm chứng

1. Suy ra mọi kênh từ một đồng hồ tham chiếu chủ và ghi lại đồng hồ tham chiếu
   đó trong dữ liệu của mỗi lần chạy.
2. Đo dao động của đường kích hoạt và giữ nó dưới 1 phần trăm của xung ngắn
   nhất.
3. Đặc trưng hoá nhiễu pha của bộ dao động nội bộ và đối chiếu nó với hiện
   tượng mất pha quan sát được trên qubit.
4. Chạy một dãy Rabi và một chuỗi Ramsey ở đầu mỗi buổi và kiểm tra tần số
   cùng biên độ so với nhật ký, rồi lưu các mẫu bao hình thô cạnh kết quả.

## Lưu ý an toàn

- Một khuếch đại vi sóng có thể cấp hàng chục milliwatt vào một thiết bị chết
  ở mức microwatt, nên hãy luôn bắt đầu ở mức công suất thấp nhất và tăng dần
  trong khi theo dõi công suất phản xạ.
- Công suất phát ở 5 GHz gây bỏng và làm nóng mô bên trong; không bao giờ hướng
  ăn-ten về phía người và coi đầu nối ra công là đang sống.
- Một đầu nối lỏng hoặc một cáp hỏng sẽ phóng hồ quang và có thể gây hoả hoạn,
  nên hãy dùng đầu nối có giới hạn lực siết và kiểm tra mọi cáp khi chịu tải.
- Lỗi nối đất đặt tín hiệu RF lên vỏ cáp, vỏ cáp sau đó tìm đường đi qua tủ
  rack và có thể làm hỏng thiết bị đo.
- Khối chặn DC và bộ chia tín hiệu phải đạt định mức tần số; một khối chặn DC
  thông thường sẽ phóng hồ quang ở công suất vi sóng.
- Không bao giờ thay cáp trên một khuếch đại đang cấp nguồn; một số khuếch đại
  cần một tải kết thúc cụ thể trước khi chạy.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- NIST Quantum Initiative Reference (phạm vi công cộng)
