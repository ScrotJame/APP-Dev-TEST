# Phiếu Nhập Kho — Ứng dụng quản lý tồn kho (Flutter + Firebase)

## 1. Tổng quan

| Hạng mục | Công nghệ |
|---|---|
| Ngôn ngữ / Framework | Flutter (Dart) |
| State management | Cubit (`flutter_bloc`) |
| Backend / Database | Firebase Firestore |
| Kiến trúc | Repository Pattern (UI → Cubit → Repository → Firestore) |
| Unit test | `test`, `bloc_test`, `fake_cloud_firestore`, `flutter_test` |

## 2. Yêu cầu môi trường

- Flutter SDK 3.47.2 (`flutter --version` để kiểm tra)
- Firebase CLI: `npm install -g firebase-tools`
## 3. Cài đặt & chạy chương trình

### Cách A — Chạy với Firebase Emulator (khuyến nghị, không cần tài khoản Firebase)

```bash
# 1. Cài dependency Flutter
flutter pub get

# 2. Đăng nhập Firebase CLI (chỉ cần cho lệnh emulators, không cần tạo project thật)
firebase login

# 3. Khởi động Firestore Emulator
firebase emulators:start --only firestore

# 4. Chạy app, trỏ vào Emulator
flutter run --dart-define=USE_FIRESTORE_EMULATOR=true
```

Emulator UI mặc định chạy tại `http://localhost:4000` — có thể xem trực tiếp dữ liệu Firestore tại đây.

File cấu hình `firebase.json` và `firestore.rules` đã có sẵn trong repo, không cần cấu hình thêm.

### Cách B — Chạy với project Firebase thật

1. Tạo project mới tại [Firebase Console](https://console.firebase.google.com).
2. Bật **Firestore Database** (chế độ Production hoặc Test).
3. Chạy `flutterfire configure` (cần cài `flutterfire_cli`) để sinh file `firebase_options.dart` tương ứng với project của bạn.
4. Import Security Rules từ `firestore.rules` trong repo vào Console (hoặc `firebase deploy --only firestore:rules`).
5. `flutter run`

> **Lưu ý:** repo không đính kèm `google-services.json` / `GoogleService-Info.plist` / `firebase_options.dart` thật vì chứa thông tin project cá nhân. Vui lòng dùng Cách A (Emulator) để chạy nhanh nhất, hoặc tự tạo project theo Cách B.

## 4. Cấu trúc dữ liệu Firestore

Vì Firestore là NoSQL, cấu trúc dữ liệu được thiết kế theo dạng **document + sub-collection** thay vì bảng quan hệ:

```
phieu_nhap (collection)
 └── {phieuId} (document)
      ├── soPhieu: string
      ├── ngayNhap: timestamp
      ├── nguoiTao: string
      ├── nhaCungCap: string
      ├── trangThai: string        # "moi" | "da_duyet" | "huy"
      ├── tongTien: number         # tổng hợp, đồng bộ khi ghi (xem mục 6.6)
      ├── createdAt: timestamp
      └── chi_tiet (sub-collection)
           └── {dongId} (document)
                ├── maVatTu: string
                ├── tenVatTu: string
                ├── donVi: string
                ├── soLuong: number
                ├── donGia: number
                └── thanhTien: number   # tính toán, xem mục 6.4
```

## 5. Kiến trúc & Quyết định thiết kế

### 5.1 Tổng quan kiến trúc

```
UI (Screens/Widgets)
      │  gọi method, lắng nghe state qua BlocProvider/BlocBuilder
      ▼
Cubit (State Management)
      │  gọi method trên interface, không biết Firestore là gì
      ▼
Repository (Data Layer)
      │  implementation: FirestoreGRNRepository, FirestoreUserRepository...
      ▼
Firebase (Firestore)
```

```
lib/
 ├── commons/
 │    ├── app_colors.dart          # Hệ thống màu sắc thiết kế chuẩn (Navy, Slate, Emerald, Amber, Rose...)
 │    └── enums.dart               # Enum LoadStatus (INITIAL, LOADING, SAVING, SUCCESS, FAILURE)
 ├── models/
 │    ├── GRN_model.dart           # Model phiếu nhập kho (GoodsReceivedNoteModel)
 │    ├── supplies_model.dart      # Model 1 dòng chi tiết vật tư (SuppliesModel)
 │    ├── document_model.dart      # Model chứng từ tham chiếu (DocumentModel)
 │    ├── product_model.dart       # Model danh mục vật tư / sản phẩm (ProductModel)
 │    └── user_model.dart          # Model tài khoản người dùng và vai trò (UserModel)
 ├── repositories/
 │    ├── grn_repositories.dart    # GRNRepository (Interface, FirestoreGRNRepository, InMemoryGRNRepository)
 │    ├── auth_repository.dart     # AuthRepository (Interface + FirebaseAuthRepository)
 │    ├── user_repository.dart     # UserRepository (Interface + FirestoreUserRepository)
 │    ├── user_session_repository.dart # UserSessionRepository (Quản lý phiên đăng nhập hiện tại)
 │    ├── document_repository.dart # DocumentRepository (Lấy danh mục chứng từ)
 │    └── product_repository.dart  # ProductRepository (Lấy danh mục sản phẩm/vật tư)
 ├── page/
 │    ├── home/                    # Màn hình Trang chủ: Danh sách phiếu, tìm kiếm & bộ lọc
 │    │    ├── home_page.dart
 │    │    ├── home_cubit.dart
 │    │    └── home_state.dart
 │    ├── entry_note/              # Màn hình Tạo mới / Lưu nháp phiếu nhập kho (Form wizard 3 bước)
 │    │    ├── entry_note_page.dart
 │    │    ├── entry_note_cubit.dart
 │    │    ├── entry_note_state.dart
 │    │    └── widgets/            # LabeledFormField, SignatureCard, StatusBanner
 │    ├── entry_note_detail/       # Màn hình Chi tiết phiếu & Ký duyệt xác nhận
 │    │    ├── entry_note_detail_page.dart
 │    │    ├── entry_note_detail_cubit.dart
 │    │    └── entry_note_detail_state.dart
 │    └── login/                   # Màn hình Đăng nhập tài khoản
 │         ├── login_page.dart
 │         ├── login_cubit.dart
 │         └── login_state.dart
 ├── utils/
 │    ├── currency_ultis.dart      # Chuyển đổi số tiền thành chữ tiếng Việt (CurrencyUtils)
 │    └── slip_note_utils.dart     # Sinh mã số phiếu chuẩn quy định (SlipNoteUtils: HN-RC-26-XXXXX)
 ├── firebase_options.dart         # Cấu hình kết nối Firebase
 └── main.dart                     # Khởi tạo DI và chạy ứng dụng

test/
 ├── entry_note_cubit_test.dart        # 10 tests: nghiệp vụ wizard tạo/lưu phiếu, công nợ, tính tiền, tự động khớp mã
 ├── entry_note_detail_cubit_test.dart # 4 tests: tải chi tiết phiếu, tải danh sách vật tư, xử lý trạng thái
 ├── home_cubit_test.dart              # 5 tests: tải danh sách phiếu, tìm kiếm, lọc trạng thái, lọc nợ, stream thời gian thực
 ├── models_and_utils_test.dart        # 10 tests: hàm sinh mã số phiếu, dịch tiền bằng chữ, model mapping 2 chiều
 └── widget_test.dart                  # 1 test: smoke test render UI
```

### 5.2 Vì sao chọn Cubit thay vì Bloc (Event) hoặc Riverpod/Provider?

- Luồng nghiệp vụ của màn hình nhập kho mang tính tuyến tính (nhập liệu → validate → tính toán → lưu nháp / lưu chính thức → thành công/lỗi). Cubit không cần đến cơ chế Event → Transformer phức tạp của Bloc thuần, vừa tinh gọn vừa dễ bảo trì.
- Method gọi trực tiếp (`cubit.addItem()`, `cubit.saveNote()`, `cubit.saveDraft()`) giúp code ngắn gọn, không phát sinh boilerplate classes cho từng Event nhỏ.
- Đồng nhất với convention `LoadStatus` enum, `Equatable`, Repository injection qua constructor.

### 5.3 Vì sao tách Repository Pattern (Cubit không gọi Firestore trực tiếp)?

- **Khả năng kiểm thử (Testability)**: `EntryNoteCubit`, `HomeCubit` chỉ phụ thuộc vào các interface (`GRNRepository`, `ProductRepository`...), không phụ thuộc `cloud_firestore`. Nhờ vậy unit test dùng `InMemoryGRNRepository` chạy tức thì, không cần mạng, không tốn quota Firebase.
- **Tách biệt tầng nghiệp vụ và tầng hạ tầng**: Đảm bảo nguyên lý Single Responsibility & Dependency Inversion Principle. Nếu thay đổi backend (VD: REST API, SQLite/Hive offline cache), chỉ cần triển khai Repository mới mà không ảnh hưởng tới Cubit hay UI.

### 5.4 Quản lý trạng thái bằng `enum LoadStatus`

Thay vì dùng nhiều biến cờ boolean rời rạc (`isLoading`, `isSuccess`, `hasError`...) dễ dẫn tới "impossible states", dự án dùng enum `LoadStatus` (`INITIAL`, `LOADING`, `SAVING`, `SUCCESS`, `FAILURE`) kết hợp cùng `copyWith()` giúp luồng UI phản hồi chính xác và tường minh.

### 5.5 Tách Model độc lập và sử dụng derived getters

- Các entity (`GoodsReceivedNoteModel`, `SuppliesModel`...) có `toMap()`/`fromMap()` rõ ràng, quản lý chặt chẽ trường lưu DB và kiểm soát kiểu dữ liệu an toàn.
- Các giá trị tính toán (`totalPrice`, `isFullySigned`...) được triển khai dưới dạng **getter derived** ngay trong Model, đảm bảo duy nhất một nguồn chân lý (Single Source of Truth), tránh việc lệch dữ liệu khi số lượng hoặc đơn giá thay đổi.

### 5.6 Mô hình dữ liệu Firestore: Sub-collection `chi_tiet`

- Danh sách vật tư trong phiếu nhập kho được tách thành sub-collection `chi_tiet` thay vì mảng nhúng trong document cha để tránh giới hạn kích thước document (1MB).
- Thao tác lưu phiếu và toàn bộ dòng chi tiết được thực hiện qua **Firestore Batch Write** (`saveGRN`), đảm bảo tính toàn vẹn dữ liệu (all-or-nothing).

## 6. Chiến lược & hướng dẫn chạy unit test

| Thành phần | Cách test | Công cụ |
|---|---|---|
| Tiện ích tính toán (`SlipNoteUtils`, `CurrencyUtils`) | Pure function testing | `flutter_test` |
| Entity & Model mapping (`toMap` / `fromMap`) | Bidirectional mapping assertion | `flutter_test` |
| `EntryNoteCubit` (luồng tạo phiếu, công nợ, lưu nháp) | In-memory repository testing | `flutter_test` + `InMemoryGRNRepository` |
| `HomeCubit` (tìm kiếm, lọc trạng thái, lọc nợ, stream) | Stream & state verification | `flutter_test` |
| `EntryNoteDetailCubit` (chi tiết phiếu, ký duyệt) | State transition testing | `flutter_test` |

Việc tách Cubit khỏi Firestore (mục 5.3) là điều kiện tiên quyết giúp tầng unit test chạy được mà **không cần khởi tạo Firebase** trong môi trường test — yêu cầu bắt buộc để unit test chạy nhanh và ổn định trong CI.

Chạy toàn bộ tests:

```bash
flutter test
```

Chạy riêng test tạo phiếu nhập kho:

```bash
flutter test test/entry_note_cubit_test.dart
```

Chạy riêng test trang chủ (tìm kiếm, lọc nợ, stream):

```bash
flutter test test/home_cubit_test.dart
```

## 6. Ghi chú bảo mật & môi trường

- Repo **không** chứa credentials bí mật hoặc service account keys.
- File cấu hình Firebase client (`firebase_options.dart`) được quản lý qua FlutterFire CLI.
- Firestore Security Rules (`firestore.rules`) đã được thiết lập cho các collection `phieu_nhap_kho`, `users`, `danh_muc_vat_tu` và `chung_tu`.
