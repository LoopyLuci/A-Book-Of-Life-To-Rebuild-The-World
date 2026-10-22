# Quy trình thiết kế mạch tích hợp

> **Domain:** silicon | **Difficulty:** master | **Safety:** yellow

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Một mạch tích hợp đi từ đặc tả bằng văn bản tới một bố cục GDSII mà một nhà
sản xuất bán dẫn có thể dùng để làm mặt nạ. Nguyên tắc cốt lõi là mọi giai
đoạn đều là một cổng kiểm chứng: không gì đi tiếp trước khi giai đoạn trước
được chứng minh, bởi chi phí của một lỗi tăng vọt theo từng bước, từ biên
dịch lại cho tới làm lại toàn bộ con chip. Thiết kế vì thế chủ yếu là một
lập luận về bằng chứng, và thứ còn lại là kho lưu trữ của những gì đã được
kiểm tra, vào lúc nào, và bằng phiên bản công cụ nào.

## Điều kiện tiên quyết

- Thiết kế số và logic Boole
- Phân tích định thời: setup, hold, lệch đồng hồ và đường tới hạn
- Verilog hoặc VHDL, và bộ mô phỏng cùng bộ tổng hợp được nêu dưới đây
- Bộ công cụ thiết kế công nghệ: ô chuẩn, LEF và GDEF, các lớp GDSII, và số
  liệu định thời Liberty
- Quản lý phiên bản có phân nhánh và phản biện

## Vật liệu & Dụng cụ

- Tài liệu đặc tả và kế hoạch kiểm chứng
- Mã nguồn RTL, một testbench, và bộ mô phỏng kèm trình xem dạng sóng
- Bộ tổng hợp với thư viện ô chuẩn và một tệp định thời Liberty
- Bộ đặt vị trí và định tuyến kèm bộ công cụ thiết kế, cộng phân tích định thời
  tĩnh
- Bộ công cụ ký duyệt: lint, CDC, DRC, LVS, và kiểm tra sụt áp IR và điện
  động hoá
- Kho Git, công cụ theo dõi phiếu công việc, và một mô hình chi phí gồm chi
  phí tấm wafer, diện tích die, số die trên mỗi wafer, và chi phí một lần cho
  mặt nạ và thiết kế

## Quy trình

### Đặc tả và viết RTL

1. Viết đặc tả: giao diện, đồng hồ, thông lượng, ngân sách độ trễ, trần công
   suất, trần diện tích die, và trần chi phí.
2. Viết kế hoạch kiểm chứng trước khi viết RTL, bao gồm các khẳng định, các
   trường hợp biên và các mục tiêu độ phủ.
3. Chốt đặc tả và ghi lại nó, để một thay đổi về sau hiện ra là một thay đổi
   chứ không phải là sự trôi dạt.
4. Viết RTL, mô phỏng testbench tới khi hồi quy đạt, và chạy lint để tìm sai
   lệch độ rộng, gán thiếu và nhiều nguồn điều khiển.

### Tổng hợp và đặt vị trí

1. Đặt các ràng buộc đồng hồ, gồm chu kỳ và độ bất định, và chạy tổng hợp theo
   diện tích và định thời mục tiêu.
2. Đọc báo cáo đường tới hạn và ước lượng công suất: công suất động xấp xỉ bằng
   C x V^2 x f cộng thêm dòng rò.
3. Lập kế hoạch sơ đồ mặt bằng trước khi công cụ làm việc đó, đặt các bộ nhớ,
   các khối tương tự và vành I/O, và chừa chỗ cho lưới nguồn.
4. Chạy đặt vị trí, rồi chèn cây đồng hồ, rồi định tuyến, và kiểm tra độ lệch
   cùng mức ùn tắc định tuyến sau mỗi giai đoạn.

### Ký duyệt và gửi sản xuất

1. Chạy phân tích định thời tĩnh ở các góc chậm và nhanh, cho cả setup và hold.
2. Chạy DRC cho các quy tắc khoảng cách, mật độ và antenna, LVS đối chiếu với
   sơ đồ nguyên lý, và các kiểm tra sụt áp IR và điện động hoá.
3. Đóng mọi vi phạm, rồi chạy một Monte Carlo đa góc để phơi bày các lỗi
   định thời hiếm gặp.
4. Xuất GDSII, tạo bộ mặt nạ, lưu trữ nó kèm tổng kiểm và các phiên bản công
   cụ đã dùng, và chia đơn hàng giữa hai nhà sản xuất để dự phòng về tiến độ.

## Lưu ý an toàn

- Những nguy cơ ở đây là nguy cơ dự án: một lần gửi sản xuất chưa được phản
  biện lãng phí trọn bộ mặt nạ và toàn bộ chi phí đứng sau nó.
- Khoá mã nguồn và mọi sở hữu trí tuệ của bên thứ ba, và giữ các tệp thiết kế
  trong một kho có kiểm soát truy cập; các quy định kiểm soát xuất khẩu áp
  dụng cho chúng.
- Hãy dùng các bản build có thể tái lập: ghi lại phiên bản công cụ, các kịch
  bản và trạng thái giấy phép, để kho lưu trữ có thể được dựng lại y hệt.
- Hãy kiểm chứng IP của bên thứ ba trước khi dùng, bởi một lỗi tinh vi trong một
  macro cứng rất tốn kém và khó tìm.
- Hãy để một người thứ hai đối chiếu danh sách ký duyệt với đặc tả trước khi
  đặt đơn hàng.
- Lưu trữ GDSII và bộ mặt nạ; mất chúng nghĩa là phải trả tiền làm lại mặt nạ.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- NIST Semiconductor Reference (phạm vi công cộng)
