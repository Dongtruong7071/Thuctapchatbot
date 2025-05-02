Ứng Dụng Chatbot
Ứng dụng ungdungchatbot là một ứng dụng chat được xây dựng bằng Flutter, tích hợp với Supabase để quản lý dữ liệu và n8n để xử lý phản hồi từ AI. Ứng dụng cho phép người dùng trò chuyện với chatbot, quản lý các đoạn chat, và tùy chỉnh cài đặt như giọng điệu, độ dài phản hồi, và system prompt.


Tính Năng Chính

Gửi và Nhận Tin Nhắn: Trò chuyện với chatbot, hiển thị tin nhắn theo giao diện thân thiện.
Quản Lý Đoạn Chat: Tạo, đổi tên, xóa các đoạn chat.
Tùy Chỉnh Cài Đặt: Điều chỉnh system prompt, giọng điệu (nghiêm túc, trung tính, cảm xúc, cường điệu), và độ dài phản hồi (ngắn, trung bình, dài).
Tìm Kiếm: Tìm kiếm tin nhắn và đoạn chat.
Highlight Từ Khóa: Highlight từ khóa tìm kiếm trong tin nhắn.
Reload Tin Nhắn: Chỉ hiển thị nút reload cho tin nhắn mới nhất của bot.
Bảo Mật: Sử dụng file .env để lưu trữ các giá trị nhạy cảm (Supabase URL, key, API URL).

Công Nghệ Sử Dụng

Flutter: Framework chính để xây dựng giao diện và logic ứng dụng.
Supabase: Backend để lưu trữ dữ liệu (đoạn chat, tin nhắn, thông tin người dùng).
n8n: Dịch vụ xử lý phản hồi từ AI.
Provider: Quản lý trạng thái trong ứng dụng.
flutter_dotenv: Quản lý các giá trị nhạy cảm trong file .env.

Cài Đặt
Yêu Cầu

Flutter SDK (phiên bản 3.0.0 trở lên)
Dart (phiên bản đi kèm với Flutter)
Một IDE (VS Code hoặc Android Studio)
Tài khoản Supabase (để lấy URL và anon key)
API endpoint từ n8n (hoặc dịch vụ AI tương tự)

Bước 1: Clone Repository
git clone https://github.com/Dongtruong7071/Thuctapchatbot.git
cd ungdungchatbot

Bước 2: Cài Đặt Dependencies
Cài đặt các package cần thiết:
flutter pub get

Bước 3: Tạo File .env
Tạo file keys.env trong thư mục gốc của dự án và thêm các giá trị sau:
SUPABASE_URL=https://your-supabase-url.supabase.co
SUPABASE_KEY=your-supabase-anon-key
N8N_API_URL=https://your-n8n-api-url
USER_ID=your-user-id-for-testing


Lưu ý: Đảm bảo file keys.env được thêm vào .gitignore để tránh commit lên repository.
Bước 4: Chạy Ứng Dụng
Kết nối thiết bị hoặc mở emulator/simulator, sau đó chạy:
flutter run

Cách Sử Dụng
Đăng Nhập: Ứng dụng sử dụng AuthenService để xác thực người dùng (có thể mở rộng thêm tính năng đăng nhập).
Tạo Đoạn Chat: Nhấn nút "+" trên AppBar để tạo đoạn chat mới.
Gửi Tin Nhắn: Nhập tin nhắn vào ô nhập liệu và nhấn gửi.
Tùy Chỉnh Cài Đặt:
Nhấn vào menu (ba chấm) trên AppBar và chọn "Cài đặt".
Điều chỉnh System Prompt, Giọng điệu, và Độ dài câu trả lời, sau đó nhấn "Lưu".

Tìm Kiếm Tin Nhắn: Nhấn biểu tượng tìm kiếm trên AppBar, nhập từ khóa để tìm kiếm và highlight tin nhắn.
Reload Tin Nhắn: Nút reload chỉ hiển thị ở tin nhắn mới nhất của bot, cho phép gửi lại yêu cầu.

Cấu Trúc Dự Án
ungdungchatbot/
├── lib/
│   ├── main.dart                    # Điểm vào của ứng dụng
│   ├── models/
│   │   └── conversation.dart        # Model cho đoạn chat
│   ├── screens/
│   │   └── chatscreen/
│   │       ├── chatscreen.dart      # Màn hình chính
│   │       ├── controller/
│   │       │   └── chat_controller.dart  # Quản lý logic chat
│   │       └── widgets/
│   │           ├── chat_app_bar.dart # AppBar với cài đặt
│   │           ├── chat_drawer.dart  # Drawer hiển thị danh sách đoạn chat
│   │           ├── chat_list.dart    # Danh sách tin nhắn
│   │           └── message_input.dart # Ô nhập tin nhắn
│   ├── services/
│   │   ├── authen_service.dart      # Xác thực người dùng
│   │   ├── n8n_service.dart         # Gọi API n8n
│   │   └── supabase_service.dart    # Tương tác với Supabase
│   └── ...
├── assets/
│   └── keys.env                        # File lưu trữ giá trị nhạy cảm
│    
├── pubspec.yaml                    # Quản lý dependencies
└── README.md                       # Tài liệu này

Góp Ý và Báo Lỗi

Nếu bạn gặp lỗi hoặc có ý tưởng cải thiện, vui lòng tạo issue trên repository: GitHub Issues.
Liên hệ: dongr7071@gmail.com

Giấy Phép
Ứng dụng được phát hành dưới MIT License.

Lưu Ý: Hãy thay thế các placeholder (your-username, your-email@example.com, https://your-supabase-url.supabase.co, v.v.) bằng thông tin thực tế của bạn trước khi sử dụng file README.md.
