# Phân tích mạch điện xoay chiều và trở kháng

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Ở dòng điện xoay chiều, điện áp và dòng điện không còn lên xuống cùng nhau,
nên tỷ số đơn giản giữa điện áp trên dòng điện không còn là một con số có
ý nghĩa. Nguyên tắc cốt lõi là thay mỗi phần tử bằng trở kháng của nó, một số
phức gồm phần điện trở và phần điện cảm, rồi giải đúng những phương trình
mạch điện như với dòng điện một chiều. Điện cảm do tần số quyết định, đó là
lý do một mạch có thể rất khác nhau ở trạng thái xác lập và ở 50 Hz.

## Điều kiện tiên quyết

- Phân tích mạch điện một chiều cho định luật Kirchhoff và quy tắc mắc nối
  tiếp, mắc song song
- Số phức ở dạng chữ nhật và dạng cực
- Hàm sin và cosin, góc pha và độ lệch pha
- Vi phân và tích phân cơ bản, cho các phần tử điện cảm
- Mối quan hệ giữa giá trị hiệu dụng (RMS), giá trị đỉnh và giá trị đỉnh
  trên đỉnh

## Vật liệu & Dụng cụ

- Máy phát tín hiệu và dao động ký
- Nguồn cấp điện trên bàn và đồng hồ vạn năng số có dải đo điện dung
- Điện trở, tụ điện và cuộn cảm thuộc dãy E12 và E24
- Bộ điện trở rời (decade box), hoặc bộ giá trị cho phần cộng hưởng và lọc
- Dây đồng và khuôn cuộn để làm cuộn cảm thử nghiệm
- Máy biến áp cách ly cho mọi công việc nối với lưới điện

## Quy trình

### Chuyển mạch thành vectơ pha

1. Thay mỗi điện trở bằng R và mỗi tụ điện, cuộn cảm bằng điện cảm của nó:
   X_L = 2 x pi x f x L và X_C = 1 / (2 x pi x f x C).
2. Viết trở kháng của mỗi phần tử ở dạng chữ nhật: Z_R = R, Z_L = j X_L và
   Z_C = -j X_C.
3. Cộng các trở kháng mắc nối tiếp và tổng hợp các nhánh mắc song song theo
   đúng quy tắc dùng cho dòng điện một chiều, giữ riêng các số hạng j, rồi
   chuyển kết quả sang dạng cực: độ lớn là căn bậc hai của R^2 cộng X^2 và góc
   là arctan của X chia R.

### Giải mạng xoay chiều

1. Áp dụng các định luật Kirchhoff cho mạng trở kháng và giải ra các dòng
   điện, điện áp dạng vectơ pha.
2. Chuyển kết quả vectơ pha trở lại miền thời gian, nhớ rằng giá trị hiệu
   dụng của một hàm sin bằng giá trị đỉnh chia cho 1.414.
3. Kiểm tra kết quả bằng công suất: công suất thực là P = V x I x cos(phi),
   công suất phản kháng là Q = V x I x sin(phi), và công suất biểu dương là
   S = V x I tính bằng vôn-ampe.

### Tìm điểm cộng hưởng

1. Cho hai điện cảm bằng nhau và giải ra tần số cộng hưởng
   f0 = 1 / (2 x pi x sqrt(L x C)).
2. Đo hai tần số công suất nửa và tính hệ số chất lượng Q = f0 / (f2 - f1),
   rồi đối chiếu với biểu thức sqrt(L / C) chia cho điện trở mắc nối tiếp.
3. Lưu ý rằng tại cộng hưởng, dòng điện mạch đạt giá trị lớn nhất và điện
   áp trên tụ điện có thể gấp Q lần điện áp nguồn.

### Thiết kế bộ lọc

1. Đặt tần số cắt theo đặc tả và tính điện trở cho một bộ lọc thấp RC đơn
   giản, R = 1 / (2 x pi x f x C), rồi chế tạo nó.
2. Đo đáp ứng tại 0.1, 1 và 10 lần tần số cắt và kiểm tra rằng tín hiệu ra
   giảm 20 dB mỗi thập kỷ.
3. Xác nhận độ lệch pha tại tần số cắt, là 45 độ với bộ lọc bậc nhất, và thêm
   một tầng nữa nếu độ suy giảm chưa đủ dốc.

## Lưu ý an toàn

- Điện áp lưới gây chết người. Hãy coi mọi mạch nối với nguồn là nguy hiểm
  chết người, và chỉ làm việc với chúng khi có đào tạo, giám sát và thiết bị
  phù hợp, sử dụng máy biến áp cách ly.
- Dòng điện làm dừng tim rất nhỏ: khoảng 0.5 mA là ngưỡng cảm nhận, 10 mA là
  ngưỡng không buông, 30 mA có thể làm ngừng thở, và 50 mA có thể gây rung
  thất nhĩ thất.
- Tụ điện đã nạp vẫn giữ năng lượng sau khi tắt nguồn, vì trở kháng của máy
  đo quá cao để phóng điện; hãy dùng điện trở phóng điện và kiểm tra điện áp
  bằng máy đo trước khi chạm vào một nút mạch.
- Mạch cộng hưởng có thể tạo điện áp cao trên tụ điện, và một bộ nghịch đảo
  hoặc một bộ tăng áp có thể đưa hàng trăm vôn lên một nút mạch trông như
  điện áp thấp.
- Giữ đầu ra của máy phát tín hiệu cách ly với đầu ra của nguồn cấp điện
  bàn, và không bao giờ nối một nguồn tín hiệu song song với đầu ra nguồn
  cấp điện.
- Kiểm tra điện áp định mức và dòng gợn sóng định mức của tụ điện, và nhớ
  rằng điện áp trên tụ trong mạch cộng hưởng có thể cao hơn nhiều so với
  điện áp nguồn.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- OpenStax University Physics (CC BY)
