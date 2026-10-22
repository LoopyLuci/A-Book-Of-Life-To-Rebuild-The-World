# Sửa lỗi lượng tử

> **Domain:** quantum | **Difficulty:** master | **Safety:** green

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Sửa lỗi lượng tử là con đường duy nhất dẫn tới một máy tính đủ lâu để có ý
nghĩa, vì không qubit vật lý nào đủ tốt để chạy một thuật toán hữu ích một
mình. Nguyên tắc cốt lõi là sự dư thừa phải được đối chiếu với loại lỗi: một
bit triệu chứng cổ điển phát hiện lỗi đảo bit, một bit triệu chứng khác phát
hiện lỗi đảo pha, và một ancilla đo tính chẵn lẻ chung phát hiện cả hai. Một
mã có khoảng cách d sửa được floor((d-1)/2) lỗi và phát hiện được d-1 lỗi, và
dưới một tỷ lệ lỗi ngưỡng, số qubit tăng thêm sẽ đổi lấy một tỷ lệ lỗi
luận lý thấp hơn tỷ lệ lỗi vật lý.

## Điều kiện tiên quyết

- Cổng lượng tử, nhóm Pauli và hình thức hoá stabilizer
- Ma trận mật độ, mặt cầu Bloch và kênh nhiễu
- Lý thuyết mã hoá sơ cấp cho các mã cổ điển dùng bên trong mã lượng tử
- Một bộ mô phỏng cổ điển hoạt động và một công cụ vẽ mạch

## Vật liệu & Dụng cụ

- Bộ mô phỏng vectơ trạng thái và bộ mô phỏng stabilizer cho các mã nhỏ
- Bộ giải ma trận mật độ cho mô hình nhiễu của một vòng đo
- Dữ liệu đánh giá chuẩn ngẫu nhiên (randomised benchmarking) cho nền tảng đang nghiên cứu
- Một hiện thực tham chiếu của bộ giải mã ghép cặp hoàn hảo trọng số nhỏ nhất
- Bảng tỷ lệ lỗi luận lý theo khoảng cách mã và lỗi vật lý
- Một bảng tính hoặc kịch bản cho ngân sách lỗi vật lý và luận lý

## Quy trình

### Phân loại lỗi

1. Tách lỗi đảo bit (X), đảo pha (Z) và kết hợp (Y), và lưu ý rằng một kênh
   khử cực hoá tạo ra cả ba cùng lúc.
2. Gắn một mô hình nhiễu cho mỗi cổng, và bắt đầu với tỷ lệ khử cực hoá
   qubit đơn là 1e-3 và qubit hai là 1e-2, điều này thực tế đối với qubit siêu
   dẫn.
3. Đưa lỗi đo vào mô hình, bởi vì một lần đọc triệu chứng sai có thể tạo ra
   một lỗi dữ liệu vốn không tồn tại.

### Chọn mã

1. Cố định tỷ lệ lỗi luận lý đích và số chu kỳ mạch; tích của chúng là số cơ
   hội độc lập bị thất bại.
2. So sánh các họ mã: mã Shor chín qubit sửa được một lỗi với chín qubit, mã
   Steane sửa được một lỗi với bảy qubit, và mã bề mặt dùng nhiều qubit hơn
   nhiều để sửa nhiều lỗi hơn.
3. Kiểm tra giới hạn Singleton, n - k >= 2(d-1), và nhớ rằng một mã hệ thống
   con cần ít nhất hai bản sao cho một cổng luận lý hai qubit.

### Mô hình hoá bộ giải mã và tìm ngưỡng

1. Tính triệu chứng cho mỗi vòng stabilizer và tìm lỗi trọng số nhỏ nhất giải
   thích nó, dùng bộ giải mã ghép cặp hoàn hảo trọng số nhỏ nhất cho mã bề
   mặt.
2. Giữ độ trễ của bộ giải mã thấp hơn thời gian một vòng triệu chứng, khoảng
   1 microgiây trên phần cứng siêu dẫn, nếu không lệnh sửa sẽ tới quá muộn để
   ngăn lỗi tiếp theo.
3. Quét một dải khoảng cách, d = 5, 9, 13 và 17, và tìm điểm giao cắt nơi tỷ
   lệ lỗi luận lý ngừng giảm; hãy kỳ vọng khoảng 1% với nhiễu khử cực hoá và
   khoảng 10% với nhiễu xoá.

### Cân đối tổng chi phí phụ

1. Ước lượng số qubit vật lý cần; với tỷ lệ lỗi vật lý 1e-3 và tỷ lệ lỗi
   luận lý đích 1e-12, hãy kỳ vọng khoảng 1e4 qubit vật lý cho mỗi qubit luận
   lý.
2. Cộng các ancilla triệu chứng, mỗi stabilizer một ancilla, nên mã bề mặt
   khoảng cách d cần khoảng d bình phương qubit dữ liệu và d bình phương trừ
   một ancilla.
3. Đếm các qubit nhàn rỗi trong khi phần còn lại tính toán, và ghi lại khoảng
   cách, tổng chi phí phụ và tỷ lệ lỗi vật lý giả định cùng với kết quả.

## Lưu ý an toàn

- Đây là một công việc phân tích, nhưng các con số quyết định một máy có đáng
  để xây hay không: không bao giờ chấp nhận một tỷ lệ lỗi luận lý được tuyên bố
  mà chưa đo trên mô hình nhiễu của phần cứng thật.
- Một bộ giải mã chậm hơn vòng triệu chứng sẽ âm thầm làm suy giảm tỷ lệ lỗi
  luận lý, nên hãy đo độ trễ của bộ giải mã trên máy đích.
- Không bao giờ dùng lại bộ giải mã hay cấu hình phần cứng từ một mô phỏng
  không nhiễu; ngân sách lỗi chỉ đúng trên mô hình nhiễu thật.
- Giữ bộ giải mã cổ điển cách xa tầng siêu lạnh và cách ly phần cứng điều
  khiển, để một lỗi trong bộ giải mã không thể tác động lên trạng thái qubit.
- Ghi lại ngân sách lỗi và khoảng cách mã cùng với dữ liệu hiệu chuẩn, bởi
  một thiết bị được hiệu chuẩn lại mà không kiểm tra lại ngân sách có thể không
  còn nằm dưới ngưỡng.
- Hãy coi mọi tuyên bố về khả năng chịu lỗi mà không có ngưỡng đo được là
  chưa được chứng minh, và nói rõ điều đó trong bản viết.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- NIST Quantum Initiative Reference (phạm vi công cộng)
