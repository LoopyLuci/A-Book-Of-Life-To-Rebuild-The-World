# Lưới điện một chiều cấp vi mạch

> **Domain:** energy | **Difficulty:** journeyman | **Safety:** red

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Một lưới điện một chiều cấp vi mạch nối các tấm pin mặt trời, pin và tải
tiêu thụ vào một bus chung, thường là 12, 24 hoặc 48 V. Nó tránh được tổn
thất của việc chuyển sang điện áp lưới cho từng bóng đèn và bộ sạc điện
thoại, nhưng đòi hỏi chọn dây, đặt cầu chì và nối đất đúng đắn. Một thiết kế
gọn gàng giữ cho các tải quan trọng tiếp tục hoạt động và giúp dễ cô lập sự
cố.

## Điều kiện tiên quyết

- Kiến thức cơ bản về lắp đặt điện mặt trời PV
- Kỹ năng an toàn điện và dùng đồng hồ vạn năng
- Kiến thức về sạc pin

## Vật liệu & Dụng cụ

- Tấm PV và phụ kiện lắp đặt
- Bộ điều khiển sạc có định mức cho dãy tấm
- Dàn pin có bảo vệ quá dòng
- Busbar DC, cầu chì và bộ ngắt mạch
- Cáp đồng và đầu nối cáp đúng kích thước
- Cọc tiếp đất và dây liên kết
- Tủ phân phối và nhãn dán
- Đồng hồ vạn năng, đồng hồ kẹp và dụng cụ cách điện

## Quy trình

### 1. Xác định tải và điện áp

1. Liệt kê mọi tải với công suất watt, số giờ mỗi ngày, và xem nó có quan
   trọng hay không.
2. Cộng tổng watt-giờ trong ngày và chọn dung lượng pin đủ cho ít nhất hai
   ngày nhiều mây.
3. Chọn điện áp bus để dòng điện ở mức quản lý được: điện áp cao hơn cho
   thời gian chạy dài hơn và tải lớn hơn.
4. Đặt các tải quan trọng trên một mạch riêng, tách khỏi tải tuỳ chọn.

### 2. Thiết kế bảo vệ

1. Đặt cầu chì cho mỗi nguồn và mỗi mạch nhánh ở mức không vượt quá dòng
   chịu được của cáp.
2. Dùng bộ ngắt mạch và cầu chì định mức cho DC; linh kiện AC có thể hồ
   quang điện và không cắt được dòng DC.
3. Liên kết khung thiết bị và cực âm pin theo sơ đồ nối đất đã chọn.
4. Dán nhãn cho mọi dây dẫn, cầu chì và công tắc với nguồn và đích đến.

### 3. Lắp đặt và nghiệm thu

1. Lắp các tấm với khoảng hở để tản nhiệt và để tiếp cận.
2. Nối bộ điều khiển sạc với pin trước, rồi mới nối dãy tấm, theo đúng thứ
   tự của nhà sản xuất.
3. Vặn đầu nối đúng lực siết và kiểm tra sụt áp khi tải.
4. Thử từng mạch bằng đồng hồ vạn năng trước khi nối tải; xác nhận cực tính
   và cách điện.

### 4. Vận hành và bảo dưỡng

1. Ghi lại sản lượng điện hằng ngày, điện áp pin và mức dùng tải.
2. Kiểm tra các cực xem có nóng, ăn mòn hay lỏng kết nối mỗi tháng.
3. Chỉ cân bằng hoặc cân bằng điện áp pin khi nhà sản xuất cho phép.
4. Ngắt dãy tấm trước khi làm việc với pin hoặc bộ điều khiển.

## Lưu ý an toàn

- **Nguy hiểm mức đỏ:** Pin có thể cấp dòng ngắn mạch khổng lồ và giải phóng
  hydro. Hãy đeo kính bảo hộ và tháo đồ trang sức bằng kim loại.
- Hồ quang điện DC không tự tắt như hồ quang điện AC; hãy dùng thiết bị bảo vệ
  định mức DC.
- Không trộn lẫn các hoá học, tuổi hay dung lượng pin khác nhau trong cùng
  một dàn.
- Hệ thống nối lưới hoặc nối máy phát điện cần một thợ điện có chứng chỉ và
  thiết bị chuyển mạch được duyệt.

## Kiểm chứng

- **Trạng thái:** draft

## Nguồn

- NEC Article 712 DC Microgrids
- IEC 62548 Photovoltaic Array Design
- Sandia National Laboratories DC Microgrid Guidance
