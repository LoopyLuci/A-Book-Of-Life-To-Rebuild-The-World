# Nghiên cứu siêu lạnh và làm lạnh pha loãng

> **Domain:** quantum | **Difficulty:** master | **Safety:** red

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Tủ lạnh pha loãng làm mát mẫu xuống vài milikelvin bằng cách trộn helium lỏng
và helium thường, và nó chỉ giữ được nhiệt độ đó nếu toàn bộ ngân sách tải
nhiệt được đáp ứng. Nguyên tắc cốt lõi là mọi cáp, mọi dây và mọi bề mặt đều
là một lỗ hổng trong lớp cách nhiệt, nên thiết kế chủ yếu là đếm nhiệt tính
bằng microwatt rồi loại bỏ nó. Mẫu chỉ là phần nhỏ nhất của hệ thống; đường
ống, bộ lọc và tấm chắn quyết định phép đo có khả thi hay không.

## Điều kiện tiên quyết

- Cơ sở kỹ thuật siêu lạnh và sơ đồ pha của helium
- Tính lỏng siêu và hiện tượng pha loãng helium-3 trong helium-4
- Kỹ thuật vi sóng và thiết kế chuỗi suy giảm, lọc
- Thực hành chân không, kiểm tra rò rỉ và xử lý an toàn chất siêu lạnh

## Vật liệu & Dụng cụ

- Tủ lạnh pha loãng có phòng trộn và phòng chưng cất (still)
- Đường ống chuyển chất siêu lạnh và bộ bơm chân không có bẫy lạnh
- Cáp đồng trục chịu chân không, đầu nối SMA và SMP, và tản nhiệt
- Chuỗi suy giảm vi sóng và một bộ lọc thông thấp cho mỗi đường tín hiệu
- Nam châm siêu dẫn, bộ nhiệt kế và phòng có tấm chắn

## Quy trình

### Lập kế hoạch tải nhiệt

1. Liệt kê mọi đường dây đi từ nhiệt độ phòng xuống phòng trộn và đếm số
   đường.
2. Tính rò nhiệt dẫn qua từng cáp từ hệ số dẫn nhiệt của vật liệu, với
   Q = k A dT / L, và lưu ý rằng một đường đồng trục không suy giảm có thể
   dẫn tới hơn một miliwatt xuống tầng 4 K.
3. Tính tải bức xạ qua từng tấm chắn với
   Q = sigma A (T_nóng mũ bốn trừ T_lạnh mũ bốn), trong đó sigma là
   5.67e-8 W trên mỗi mét vuông trên mỗi kelvin mũ bốn.
4. Cộng tải làm mát do tầng khuếch đại, so với tổng với công suất làm mát tại
   phòng trộn, thường là 10 đến 100 microwatt ở 10 mK, và chừa biên an toàn
   tối thiểu 30 phần trăm.

### Chuẩn bị đường dây

1. Kết thúc mọi đường đồng trục bằng một bộ suy giảm tại tầng 50 K, tầng 4 K,
   phòng chưng cất và phòng trộn, khoảng 10 dB mỗi tầng.
2. Thêm một bộ lọc thông thấp tại tầng 4 K cho mỗi đường tín hiệu, với tần số
   cắt khoảng 5 GHz, và một tần số cắt thấp hơn nhiều là 700 MHz hoặc thấp hơn
   trên mỗi đường lệch DC.
3. Neo mỗi đường dây vào các tầng bằng băng đồng hoặc nhôm để nhiệt dừng lại ở
   đó.
4. Kiểm tra chân không toàn bộ đường và đầu nối xuyên vỏ, và không bao giờ đóng
   kín khoang chân không trên một đường lạnh chưa được kiểm tra rò rỉ.

### Làm lạnh và kiểm chứng

1. Bật tuần tự helium và bơm chân không theo thứ tự quy định và không bao giờ
   ngắt quãng một quá trình hâm lên đã tạo được chân không.
2. Theo dõi nhiệt độ các tầng và mức helium, và ghi lại thời gian ổn định cùng
   nhiệt độ nền cuối cùng.
3. Chỉ đóng các tấm chắn bức xạ sau khi nhiệt độ nền đã ổn định, rồi chuyển
   mẫu và xác nhận rằng nhiệt độ tại giá đỡ mẫu khớp với nhiệt kế.
4. Ghi lại cùng nhau nhiệt độ nền, nhiệt độ các tầng và sàn nhiễu vi sóng cho
   mỗi lần làm lạnh.

## Lưu ý an toàn

- Helium lỏng nở ra với mức độ rất lớn khi nóng lên và có thể làm vỡ một thể
  tích kín, nên mọi thể tích lạnh đều cần một đường xả áp và các thiết bị xả
  áp không bao giờ được chặn hoặc bị nghẽn.
- Helium lỏng và nitơ lỏng gây bỏng lạnh và có thể đẩy oxy ra khỏi một căn
  phòng; hãy làm việc ở nơi thông gió tốt có máy theo dõi và không bao giờ làm
  việc một mình với chất siêu lạnh.
- Một đường chuyển chất siêu lạnh đã được mở có thể đẩy helium lỏng vào một
  đường chân không và gây nổ lõm; không bao giờ xả một đường lạnh ra khí quyển mà
  không làm theo đúng quy trình.
- Oxy ngưng tụ trên một bề mặt lạnh làm nó giòn và mọi khớp nối siêu lạnh trở
  thành nguồn nguy hiểm do mảnh vỡ; hãy dùng đúng loại gioăng kim loại và
  không bao giờ vặn chặt một khớp nối lạnh.
- Nam châm siêu dẫn tích trữ năng lượng và có thể mất từ trường mà không báo
  trước, giải phóng một từ trường lớn và làm sôi chất siêu lạnh; hãy đặt giới
  hạn tốc độ tăng dòng và không bao giờ để nó có dòng điện mà không giám sát.
- Sự cố chân không hoặc dầu bơm trào ngược có thể làm nhiễm một tầng lạnh và
  phá huỷ thí nghiệm mà không có dấu hiệu nhìn thấy.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- NIST Cryogenics Guidance (phạm vi công cộng)
