# Kiến trúc ứng dụng — Phiếu Nhập Kho (Flutter + Firebase)

## 1. Tổng quan kiến trúc

Ứng dụng dùng **Cubit (flutter_bloc) + Repository Pattern**, chia làm 3 lớp:

```
UI (Screens/Widgets)
      │  gọi method, lắng nghe state qua BlocProvider/BlocBuilder
      ▼
Cubit (State Management)
      │  gọi method trên interface, không biết Firestore là gì
      ▼
Repository (Data Layer)
      │  implementation cụ thể: FirestorePhieuNhapRepository
      ▼
Firebase (Firestore)
```

```
lib/
 ├── models/
 │    ├── phieu_nhap_kho.dart      # Model document cha (header)
 │    └── chi_tiet_vat_tu.dart     # Model 1 dòng vật tư (sub-collection)
 ├── repositories/
 │    └── phieu_nhap_repository.dart   # Interface + FirestorePhieuNhapRepository
 ├── cubit/
 │    ├── phieu_nhap_cubit.dart
 │    └── phieu_nhap_state.dart
 └── screens/
      └── phieu_nhap_form_screen.dart

test/
 └── phieu_nhap_cubit_test.dart    # unit test Cubit, không cần Firebase thật
```

## 2. Vì sao chọn Cubit thay vì Bloc (Event) hoặc Riverpod/Provider?

- **Luồng nghiệp vụ của màn hình này tuyến tính** (nhập liệu → validate → lưu → thành công/lỗi), không cần đến cơ chế Event → Transformer phức tạp của Bloc thuần, cũng không cần dependency-graph reactive của Riverpod. Cubit đủ mạnh và đơn giản hơn để maintain.
- Method gọi trực tiếp (`cubit.themDong()`, `cubit.luuPhieu()`) thay vì phải định nghĩa Event class cho từng hành động — giảm boilerplate đáng kể cho 1 form không quá phức tạp.
- **Đồng nhất với codebase/kinh nghiệm hiện có của team** — giữ nguyên convention `LoadStatus`-style enum, `Equatable`, Repository injection qua constructor. Nhất quán về kiến trúc giúp code dễ review, dễ onboard, giảm rủi ro hơn là trộn nhiều state management khác nhau trong cùng dự án.

## 3. Vì sao tách Repository Pattern (Cubit không gọi Firestore trực tiếp)?

- **Testability**: `PhieuNhapCubit` chỉ phụ thuộc vào interface `PhieuNhapRepository`, không phụ thuộc `cloud_firestore`. Nhờ vậy unit test dùng `FakePhieuNhapRepository` chạy cực nhanh, không cần khởi tạo Firebase, không cần mạng, không tốn quota Firestore khi chạy CI.
- **Tách biệt tầng nghiệp vụ và tầng hạ tầng**: nếu sau này đổi data source (VD: thêm cache local bằng Hive/SQLite, hoặc đổi sang REST API), chỉ cần viết implementation mới của `PhieuNhapRepository`, không phải sửa Cubit hay UI.
- **Đúng Dependency Inversion Principle**: tầng cao (Cubit — nghiệp vụ) không phụ thuộc tầng thấp (Firestore — chi tiết kỹ thuật), cả hai cùng phụ thuộc vào abstraction (interface).

## 4. Vì sao dùng `enum FormStatus` thay vì nhiều `bool`?

Thay vì `isSaving`, `isSuccess`, `hasError`... (dễ tồn tại nhiều cờ `true` cùng lúc do quên reset), dùng 1 enum duy nhất `{ initial, saving, success, failure }` đảm bảo **state luôn ở đúng 1 trạng thái tại một thời điểm** — loại bỏ hẳn nhóm bug "impossible state" và khiến `BlocBuilder`/`BlocConsumer` ở UI chỉ cần 1 `switch`/`if-else` rõ ràng theo enum.

## 5. Vì sao tách `models/` riêng, không dùng `Map<String, dynamic>` trực tiếp?

- Có `toJson()`/`fromJson()` tường minh giúp kiểm soát chặt việc field nào lưu ở Firestore, tránh lỗi runtime kiểu `null` hoặc sai key do gõ tay chuỗi ở nhiều nơi.
- `Equatable` trên model giúp Cubit so sánh state chính xác (tránh rebuild UI thừa) và giúp assert dễ dàng trong unit test (`expect(state.phieu, equals(...))`).
- Getter tính toán (`thanhTien`, `tongTien`) đặt ngay trong model để đảm bhảo **single source of truth** — không lưu số tiền đã tính sẵn trong state rồi phải đồng bộ tay mỗi khi số lượng/đơn giá đổi.

## 6. Vì sao Firestore dùng sub-collection `chi_tiet` thay vì mảng nhúng trong document cha?

- Phiếu nhập có số dòng vật tư không cố định; nếu nhúng thành `array` trong document cha, mỗi lần sửa 1 dòng phải ghi lại toàn bộ mảng, và document dễ chạm giới hạn 1MB nếu phiếu dài.
- Sub-collection cho phép query/update từng dòng độc lập, và dễ mở rộng sau này (VD: thêm field `daKiemKe: bool` cho từng dòng vật tư mà không đụng document cha).
- Đánh đổi: ghi phiếu cần 1 **batch write** (header + toàn bộ dòng chi tiết) để đảm bảo tính nguyên tử — được xử lý trong `FirestorePhieuNhapRepository.savePhieuNhap()`.

## 7. Chiến lược unit test

| Thành phần | Cách test | Công cụ |
|---|---|---|
| Getter tính toán (`thanhTien`, `tongTien`) | Test thuần Dart, không cần mock | `test` |
| `PhieuNhapCubit` (luồng state, validate) | Test cô lập bằng repository giả | `bloc_test` + `FakePhieuNhapRepository` |
| `FirestorePhieuNhapRepository` | Test với Firestore giả lập, không tốn quota | `fake_cloud_firestore` |
| Widget/Form | Test render, nhập liệu, hiển thị lỗi | `flutter_test` (`testWidgets`) |

Việc tách Cubit khỏi Firestore (mục 3) là điều kiện tiên quyết giúp tầng `bloc_test` chạy được mà **không cần khởi tạo Firebase** trong môi trường test — đây là yêu cầu bắt buộc để unit test chạy nhanh và ổn định trong CI.