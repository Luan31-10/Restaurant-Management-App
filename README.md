 Ứng dụng Quản lý Nhà hàng Đa nền tảng (Flutter)

Một ứng dụng di động toàn diện được thiết kế để tối ưu hóa quy trình vận hành nhà hàng, hỗ trợ nhân viên phục vụ quản lý bàn và gọi món một cách nhanh chóng, chính xác. 

Dự án được xây dựng bằng **Flutter**, đảm bảo trải nghiệm mượt mà trên cả hai nền tảng Android và iOS.

  Các tính năng nổi bật

* Quản lý trạng thái bàn theo thời gian thực:** Theo dõi trực quan trạng thái của từng bàn (Trống, Đang có khách, Đang chờ thanh toán), giúp tránh tình trạng trùng lặp order và nhầm lẫn trong vận hành.
* Hệ thống gọi món tối ưu:** Giao diện trực quan dựa trên chuẩn Material Design, giúp nhân viên thao tác gọi món, thêm topping, ghi chú và chuyển bàn cực kỳ nhanh chóng.
* Thanh toán & Xuất hóa đơn thông minh:** Tự động tính toán tổng tiền, áp dụng mã giảm giá và xuất hóa đơn tạm tính chính xác.
* Khả năng hoạt động Offline:** Sử dụng bộ nhớ cục bộ (Local Storage) để lưu trữ dữ liệu thực đơn và danh sách bàn, giúp ứng dụng vẫn hoạt động ổn định ngay cả khi kết nối mạng chập chờn.
* Giao diện chuẩn UI/UX:** Thiết kế hiện đại, thân thiện, tập trung vào trải nghiệm của người dùng cuối (nhân viên phục vụ).

 Công nghệ sử dụng

* Nền tảng (Framework):** Flutter
* Ngôn ngữ lập trình:** Dart
* Quản lý trạng thái (State Management):** Provider / GetX *(Thay bằng thư viện bạn đã dùng)*
* Cơ sở dữ liệu (Database):** SQLite / Shared Preferences
* Thiết kế giao diện:** Material Design

 Hướng dẫn cài đặt và chạy ứng dụng

Để chạy dự án này trên máy tính cá nhân, vui lòng đảm bảo bạn đã cài đặt môi trường [Flutter SDK](https://docs.flutter.dev/get-started/install).

1. Clone mã nguồn về máy:
   git clone [https://github.com/Luan31-10/Restaurant-Management-App.git](https://github.com/Luan31-10/Restaurant-Management-App.git)
2. Di chuyển vào thư mục dự án:

cd Restaurant-Management-App
3. Tải các thư viện phụ thuộc (Dependencies):

flutter pub get
4. Chạy ứng dụng (trên máy ảo hoặc thiết bị thật):

flutter run
Thông tin tác giả
Võ Thành Luân - Sinh viên chuyên ngành Công nghệ Phần mềm - ĐH HUTECH

GitHub: https://github.com/Luan31-10




