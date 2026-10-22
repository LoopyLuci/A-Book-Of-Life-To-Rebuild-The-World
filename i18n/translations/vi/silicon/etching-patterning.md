# ăn mòn ướt và ăn mòn khô

> **Domain:** silicon | **Difficulty:** master | **Safety:** red

*Tài liệu tham khảo. Trước khi áp dụng, hãy đối chiếu thông tin này với các
nguồn gốc và những chuyên gia có đủ chuyên môn. Mục này không phải là nguồn
thông tin duy nhất.*

## Tổng quan

Ăn mòn loại bỏ vật liệu một cách chọn lọc để chuyển hình mẫu của lớp nhạy
quang sang lớp màng bên dưới. Hai con số quyết định đặc tính có sống sót hay
không: độ chọn lọc, là tốc độ ăn mòn của lớp chia cho tốc độ ăn mòn của mặt
nạ, và tính bất đẳng hướng, là tỷ lệ giữa phần ăn mòn theo chiều dọc và theo
chiều ngang. Ăn mòn ướt rẻ và bất đẳng hướng, còn ăn mòn plasma khô có tính
hướng và chính xác, nên lựa chọn phải theo hình học chứ không theo tiện lợi.

## Điều kiện tiên quyết

- Quang khắc và Làm mặt nạ (hình mẫu lớp nhạy quang và làm mặt nạ)
- Màng mỏng để làm mặt nạ cứng và lớp chống phản xạ
- Làm sạch tấm wafer và độ bám dính tin cậy của mặt nạ lên bề mặt
- Đọc các bảng tốc độ ăn mòn và độ chọn lọc của chính thiết bị

## Vật liệu & Dụng cụ

- Bàn ướt: các bể có gia nhiệt, điều khiển nhiệt độ và máy quay chuẩn vệ sinh
- Dung dịch ăn mòn: axit fluo hiđric, axit nitric, axit acetic, hiđroxit
  kali, hiđroxit tetrametylammoni, và dung dịch ăn mòn oxi đệm (BOE)
- Máy ăn mòn RIE hoặc ICP với máy phát RF 13.56 MHz, matchbox và bơm
- Khí quy trình: CF4, CHF3, SF6, Cl2 và O2, với hút khí đã xử lý
- Máy đo ellipsoid, máy đo độ hình học bề mặt và kính hiển vi quang học để đo
- Bình chứa PTFE và polyethylene, kẹp wafer và tấm che mặt

## Quy trình

### Lập kế hoạch độ chọn lọc

1. Đặt độ sâu đích và kích thước quan trọng của lớp.
2. Tra tốc độ ăn mòn của lớp màng và của mặt nạ trên chính thiết bị và hoá chất
   của bạn; các tốc độ đã công bố không chuyển đổi được giữa các máy.
3. Yêu cầu độ chọn lọc ít nhất 10:1 cho một lớp màng 100 nm dưới lớp nhạy quang
   1 um, và thêm mặt nạ cứng khi lớp nhạy quang không sống sót được bước ăn
   mòn.
4. Lập kế hoạch cho hiệu ứng tải: hãy kỳ vọng tốc độ ăn mòn giảm khi diện tích
   mở tăng, nên cắt một wafer thử mang cả hình mẫu nhỏ lẫn hình mẫu lớn.

### Ăn mòn ướt

1. Làm sạch wafer, làm khô, và phủ lớp nhạy quang hoặc mặt nạ cứng.
2. Ăn mòn silic bằng axit fluo hiđric, nitric và acetic ở 60-80 °C trong
   20-60 s, hoặc ăn mòn trong hiđroxit kali ở 80 °C để ăn mòn bất đẳng hướng với
   độ chọn lọc trên 100:1 so với silic dioxit.
3. Tráng bằng nước khử ion và làm khô bằng khí nitơ.
4. Bù lại phần ăn mòn ngầm bằng cách phóng to mặt nạ thêm chiều sâu ăn mòn ở
   mỗi cạnh, và giữ mặt phẳng (111) bằng cách che các góc bằng một lưỡi
   nống nhỏ ít nhất 1.41 lần kích thước dự kiến.

### Ăn mòn khô

1. Nạp wafer vào máy ăn mòn, hút chân không, và điều kiện hoá buồng bằng một
   chu trình làm sạch bằng oxy và fluorocabon.
2. Đặt lưu lượng khí, áp suất (khoảng 10-50 mTorr cho RIE và 1-10 mTorr cho
   ICP), công suất nguồn (300-600 W cho silic), và công suất lệch cho lớp màng
   đích.
3. Ăn mòn tới độ sâu đích và dừng theo tín hiệu kết thúc: tín hiệu giao thoa
   quang, hoặc sự sụt giảm của vạch phát quang silic.
4. Đo độ sâu và hồ sơ vách bên trên một wafer đối chứng, kiểm tra xem có vết
   khuyết ở đáy đặc tính rộng hay không, và ghi lại tốc độ cùng độ chọn lọc cho
   lần chạy sau.

## Lưu ý an toàn

- **Nguy hiểm mức đỏ:** Axit fluo hiđric gây chết người khi tiếp xúc với da và
  khi hít vào, và nó phá huỷ xương. Chỉ xử lý nó khi có đào tạo, giám sát và thiết
  bị phù hợp, với gel canxi gluconat ở bàn và quy trình làm việc có cặp.
- **Nguy hiểm mức đỏ:** Không bao giờ cất hoặc mang axit fluo hiđric trong thuỷ
  tinh; nó ăn mòn thuỷ tinh và rò ra qua kính.
- Hỗn hợp fluo hiđric, nitric và acetic giải phóng nitrogen dioxide; hãy làm
  việc trong tủ hút và không bao giờ hít hơi.
- Khí ăn mòn plasma có tính độc và gây ngạt thở: hoá chất clo tạo ra hydrogen
  chloride và hoá chất flo tạo ra hydrogen fluoride.
- Nguồn tần số radio và plasma gây chết người khi chạm vào; hãy giữ các liên
  động cơ và bộ hút khí xử lý chạy mọi lúc có khí chảy.
- Các bể dung dịch ăn mòn phải được dán nhãn với thành phần và ngày, và một bể
  đã từng chứa silic không bao giờ được trả lại dùng để rửa thuỷ tinh.

## Kiểm chứng

- **Trạng thái:** draft
- **Người thử nghiệm:** —
- **Ngày:** —

## Nguồn

- NIST Semiconductor Reference (phạm vi công cộng)
