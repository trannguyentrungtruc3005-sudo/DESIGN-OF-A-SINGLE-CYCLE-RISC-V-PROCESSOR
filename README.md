Milestone 2 yêu cầu thiết kế một bộ xử lý RV32I single-cycle theo nội dung đã học trên lớp.
Bộ xử lý sử dụng tập lệnh RV32I (không bao gồm các lệnh FENCE) và được mở rộng để có thể
giao tiếp với các ngoại vi bên ngoài, bao gồm LCD, LED và SWITCH; LED 7 đoạn là tùy chọn.
Hệ thống bộ nhớ được xây dựng từ hai mô hình bộ nhớ logic element giống nhau: một được
cấu hình chỉ đọc để lưu trữ instruction memory, và một cho phép đọc–ghi để làm data memory.
Thiết kế phải đáp ứng các yêu cầu của milestone và sẽ được kiểm tra bằng cả bộ test sinh viên
tự xây dựng và bộ testbench đầy đủ trên máy chủ DOELAB.

Overview:

Thiết kế bộ xử lý tuân theo kiến trúc RV32I đơn chu kỳ chuẩn như đã được thảo luận trong
các bài giảng và được minh họa trong Hình 1 của tài liệu đặc tả Milestone 2. Kiến trúc này bao
gồm các khối chức năng chính sau:
1. Program Counter (PC) với logic tính toán địa chỉ lệnh tiếp theo (PC_next)
2. Instruction Memory (I$)- Bộ nhớ lệnh chỉ đọc
3. Control Unit- Đơn vị điều khiển thực hiện giải mã lệnh và sinh các tín hiệu điều khiển
4. Immediate Generator (ImmGen)- Bộ sinh giá trị immediate với mở rộng dấu phù hợp
5. Register File (Regfile)- Bộ thanh ghi 32 thanh ghi x 32-bit
6. Arithmetic Logic Unit (ALU)- Đơn vị tính toán số học và logic
7. Branch Comparison Unit (BRC/BRU)- Đơn vị so sánh cho các lệnh rẽ nhánh
8. Load-Store Unit (LSU)- Đơn vị tích hợp bộ nhớ dữ liệu (D$) và giao diện I/O
Mỗi lệnh được thực thi hoàn chỉnh trong một chu kỳ đồng hồ duy nhất, tuần tự đi qua các
giai đoạn: Fetch (lấy lệnh), Decode (giải mã), Execute (thực thi), Memory Access (truy cập bộ
nhớ) và Write-back (ghi ngược). LSU quản lý việc truy cập đến cả bộ nhớ dữ liệu 2KiB và các
thiết bị ngoại vi được ánh xạ bộ nhớ theo đúng các vùng địa chỉ đã được quy định trong bảng
ánh xạ bộ nhớ.
