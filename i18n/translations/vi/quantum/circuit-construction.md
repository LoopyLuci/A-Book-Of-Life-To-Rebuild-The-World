# Xây dựng mạch lượng tử

> **Domain:** quantum | **Difficulty:** apprentice | **Safety:** green

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Mạch lượng tử là một công thức bằng văn bản: một danh sách các cổng trên một
danh sách qubit, rồi tới phép đo. Nguyên tắc cốt lõi là mạch bạn viết không
phải mạch chạy, vì trình biên dịch phải ánh xạ nó trước lên các cổng và các
kết nối mà phần cứng thực sự có. Học cách đọc bản ánh xạ đó, và giữ hai mạch
đó gần nhau, chính là kỹ năng thực tế.

## Điều kiện tiên quyết

- Véc tơ phức và phép nhân ma trận
- Mặt cầu Bloch và các cổng qubit đơn
- Python cơ bản hoặc một ngôn ngữ kịch bản khác
- Các quy tắc của mạch lượng tử: không sao chép, và phép đo phá huỷ

## Vật liệu & Dụng cụ

- Một SDK lượng tử như Qiskit, Cirq hoặc Braket
- Bộ mô phỏng vectơ trạng thái cho mạch nhỏ, tới khoảng 20 qubit
- Một backend phần cứng và dữ liệu hiệu chuẩn được công bố của nó
- Một sổ tay hoặc tệp chứa mạch và kết quả dự kiến
- Bản sao cục bộ của mô hình nhiễu cho thiết bị đích

## Quy trình

### Viết mạch

1. Nêu rõ câu hỏi mà mạch trả lời trước khi viết bất kỳ cổng nào.
2. Xây mạch theo từng lớp, mỗi lần một cổng, và vẽ nó ra để kiểm tra rằng
   các dây là đúng những qubit bạn muốn.
3. Giữ số cổng nhỏ, và ưu tiên một cặp rối (entangling) thay vì nhiều cặp
   chồng lấn.
4. Thêm phép đo sau cùng, và nhớ rằng đo sớm sẽ phá huỷ trạng thái cho phần
   còn lại của mạch.

### Biên dịch

1. Gửi mạch qua bộ biên dịch trung gian cho backend đích và để nó chọn tập cổng
   gốc cùng cách ánh xạ.
2. Xem bố cục mà trình biên dịch đã chọn: trên lưới hoặc kết nối lục giác
   nặng, các qubit xa nhau được nối bằng cổng hoán đổi vốn làm tăng lỗi.
3. Tự chọn bố cục ban đầu khi mạch có hình học tự nhiên, và so sánh số cổng của
   cả hai lựa chọn.
4. Đặt mức tối ưu hoá ở 1 hoặc 2, ghi lại mức nào tạo ra lần chạy bạn giữ lại,
   và kiểm tra các thời điểm xung đã lên lịch, vì trình biên dịch có thể chèn
   thời gian nhàn rỗi trong đó qubit trôi lệch.

### Chạy và đọc kết quả

1. Chạy mạch nhiều lần và đếm các kết quả; một lần chạy đơn lẻ gần như không
   nói lên điều gì.
2. So sánh biểu đồ phân bố với mô phỏng lý tưởng và nêu ra sự khác biệt bằng
   một con số chứ không phải bằng ấn tượng.
3. Kiểm tra siêu dữ liệu của công việc để biết ngày hiệu chuẩn thiết bị, và từ
   chối báo cáo một con số lấy từ thiết bị chưa được hiệu chuẩn.
4. Lưu lại cùng nhau mạch, bản đã biên dịch, giá trị hạt giống và các số đếm,
   chạy lại với hạt giống khác, và xác nhận các thống kê khớp nhau trước khi
   rút ra bất kỳ kết luận nào.

## Lưu ý an toàn

- Bộ mô phỏng có thể làm cạn bộ nhớ của máy: một vectơ trạng thái cần
  16 byte cho mỗi qubit, nên 30 qubit cần 16 terabyte, và thay vào đó nên dùng
  các phương pháp stabilizer hoặc ma trận mật độ.
- Không bao giờ gửi một mạch chứa khoá bí mật trong các cổng của nó tới thiết
  bị dùng chung mà không xem xét kỹ, vì một mạch tiết lộ rất nhiều về dữ liệu
  mà nó được xây dựng từ đó.
- Chạy trên phần cứng tốn thời gian xếp hàng và làm mát máy, nên hãy gom nhiều
  mạch thành lô và để thiết bị rảnh cho người khác.
- Phép đo có tính phá huỷ, và một mạch đo sớm rồi dùng lại qubit sẽ cho ra câu
  trả lời sai chứ không phải thông báo lỗi.
- Không báo cáo kết quả phần cứng mà thiếu tên thiết bị, ngày hiệu chuẩn và số
  lần chạy, vì không thứ nào trong số đó có thể khôi phục lại sau này.
- Một bộ mô phỏng không có nhiễu sẽ vui vẻ cho ra kết quả hoàn hảo cho một mạch
  không chạy được, nên hãy luôn nói rõ công cụ nào đã tạo ra các con số.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- NIST Quantum Initiative Reference (phạm vi công cộng)
