# Chuẩn bus và giao diện tín hiệu

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Bus là một thoả thuận về dây dẫn: một mức logic nghĩa là gì, ai được phép
điều khiển đường dây, và bộ thu biết khi nào một bit là hợp lệ. Nguyên tắc cốt
lõi là mọi chuẩn bus đều giải quyết cùng ba vấn đề: sức tải đầu ra, đồng hồ
và phân xử, và một thiết bị bỏ qua bất kỳ vấn đề nào trong ba sẽ hỏng theo
kiểu đột ngột chứ không hỏng dứt khoát. Ba giao diện dưới đây bao phủ phần
lớn những gì một xưởng phải kết nối.

## Điều kiện tiên quyết

- Logic số: đẩy-kéo, mở bơm, điện trở kéo lên và mức logic
- Đọc bảng chân trong datasheet và sơ đồ định thời
- Đóng khung dữ liệu nối tiếp: tốc độ baud, số bit dữ liệu, bit chẵn lẻ và bit
  dừng
- Hàn mạch cơ bản và sử dụng đồng hồ vạn năng hoặc máy phân tích logic

## Vật liệu & Dụng cụ

- Máy phân tích logic có khả năng giải mã UART, I2C và SPI
- Board phát triển vi điều khiển và vài board mở rộng
- Gói điện trở kéo lên, 2 kOhm đến 10 kOhm cho I2C ở 400 kHz
- Điện trở mắc nối tiếp 22 đến 33 Ohm và điện trở kết thúc 120 Ohm cho các
  đoạn dài
- Nguồn cấp điện bàn, đồng hồ vạn năng và dao động ký

## Quy trình

### UART

1. Thống nhất khung trước: 8 bit dữ liệu, không bit chẵn lẻ và 1 bit dừng,
   tức là 10 bit trên đường dây cho mỗi byte.
2. Đặt cả hai đầu cùng tốc độ baud, và nhớ rằng sai số 2 phần trăm thường
   còn chấp nhận được còn 5 phần trăm thì không.
3. Nối đầu phát sang đầu thu và đầu thu sang đầu phát, và nối chung mặt đất;
   mặt đất chung là phần hay bị bỏ sót nhất.
4. Xác nhận trạng thái rảnh là logic 1 và logic 0 đánh dấu bit bắt đầu, rồi
   kiểm tra mức logic ở cả hai đầu trước khi tin vào dữ liệu, và lắp bộ
   chuyển mức cho liên kết 5 V sang 3.3 V.

### I2C

1. Kéo SDA và SCL lên nguồn qua điện trở 2 kOhm đến 10 kOhm, và kiểm tra thời
   gian tăng so với điện dung bus trước khi nâng tần số đồng hồ.
2. Gọi địa chỉ các thiết bị bằng địa chỉ 7-bit, và nhớ rằng nhiều linh kiện
   dùng hai địa chỉ riêng cho hai nguồn cấp điện của chúng.
3. Đọc thứ tự địa chỉ và thanh ghi từ datasheet, rồi xác nhận cả hai trên máy
   phân tích trước khi tin vào chuỗi lệnh.
4. Kiểm tra thời gian thiết lập và giữ trong sơ đồ định thời, giữ đồng hồ
   dưới 100 kHz cho lần thử đầu tiên, và xoá một bus bị kẹt bằng xung chín
   đồng hồ thay vì giữ SDA ở mức thấp.

### SPI

1. Nối đồng hồ, đầu vào của master, đầu ra của master và tín hiệu chọn chip,
   và mỗi thiết bị có đường chọn riêng.
2. Bắt đầu ở chế độ 0, đồng hồ rảnh ở mức thấp, lấy dữ liệu ở cạnh lên, rồi
   xác nhận chế độ theo datasheet.
3. Giữ đồng hồ dưới 1 MHz cho lần thử đầu tiên, rút ngắn dây nếu các cạnh
   trông bị bo tròn trên máy phân tích, và lắp 22 đến 33 Ohm mắc nối tiếp với
   dây đồng hồ và dây dữ liệu để triệt tiêu hiện tượng gợn sóng.
4. Đọc định thời song công đầy đủ trong datasheet, gồm cả độ trễ giữa lúc
   tín hiệu chọn chip có hiệu lực và cạnh đồng hồ đầu tiên.

## Lưu ý an toàn

- Máy phân tích logic và nhiều board phát triển nối mặt đất của chúng với đất
  của máy chủ, nên đo một mạch cao áp hoặc mạch điện lưới có thể phá huỷ máy
  phân tích và gây hoả hoạn.
- Kiểm tra nguồn cấp của cả hai đầu trước khi nối bus; một thiết bị ngoại vi
  5 V điều khiển một đầu vào 3.3 V có thể phá huỷ bộ điều khiển.
- Không bao giờ đo một động cơ hay mạch nhiệt đang chạy mà không dùng đầu đo
  vi sai có hệ số chịu điện áp phù hợp.
- Giữ mặt đất chung giữa hai thiết bị; mặt đất lơ lửng cho dữ liệu sai và có
  thể làm hỏng các cổng.
- Giữ điện trở kéo lên của I2C ngắn nhất mà điều điện cho phép, vì một đoạn
  dài không kết thúc sẽ bức xạ và gây lỗi đột ngột.
- Chỉ một đường dây bị chập là hỏng mọi thiết bị trên bus, nên hãy cấp điện
  cho cả đoạn trước khi đi lại dây.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- NXP and Analog Devices Interface Notes (phạm vi công cộng)
