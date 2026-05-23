
## Giới thiệu

**Pro Video Editor** là ứng dụng Android được xây dựng bằng Flutter, tích hợp đầy đủ các tính năng:

- Chỉnh sửa video cơ bản: cắt, ghép, filter, text, âm thanh
- Chỉnh sửa Pro (AutoCut): tự động cắt video theo nhịp
- Chỉnh sửa ảnh: crop, filter, sticker, text
- AI Lab: tự động tạo tiêu đề, mô tả, hashtag bằng Gemini AI
- Lưu trữ & quản lý dự án trên Firebase Cloud
- Quản lý hồ sơ người dùng

---

## 🛠️ Công nghệ sử dụng

### Frontend
| Công nghệ | Phiên bản | Vai trò |
|-----------|-----------|---------|
| Flutter | 3.x | Framework phát triển đa nền tảng |
| Dart | 3.x | Ngôn ngữ lập trình |

### Backend (Firebase)
| Dịch vụ | Vai trò |
|---------|---------|
| Firebase Authentication | Đăng ký, đăng nhập |
| Cloud Firestore | Lưu metadata người dùng và video |
| Firebase Storage | Lưu file video và ảnh |

### Thư viện chính
| Package | Vai trò |
|---------|---------|
| `pro_video_editor` | Chỉnh sửa video (Media3 + FFmpeg) |
| `pro_image_editor` | Chỉnh sửa ảnh |
| `google_generative_ai` | Tích hợp Gemini AI |
| `file_picker` | Chọn file từ gallery |
| `gal` | Lưu ảnh/video vào gallery |
| `media_kit` | Phát video |

---

##  Kiến trúc hệ thống

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  HomePage │ ProjectPage │ VideoAiPage   │
├─────────────────────────────────────────┤
│         Business Logic Layer            │
│  AuthService │ LocalVideoRepository     │
│  GeminiAiService                        │
├─────────────────────────────────────────┤
│            Data Layer                   │
│  Firestore │ Firebase Storage           │
│  Gemini API                             │
└─────────────────────────────────────────┘
```

---

## 📁 Cấu trúc project

```
lib/
├── main.dart
├── features/
│   ├── auth/
│   │   └── pages/auth_page.dart
│   ├── editor/
│   │   ├── pages/
│   │   │   ├── video_editor_basic_example_page.dart
│   │   │   └── video_editor_grounded_example_page.dart
│   │   └── widgets/preview_video.dart
│   ├── ai/
│   │   └── pages/video_ai_page.dart
│   ├── home/
│   │   ├── pages/
│   │   │   ├── home_page.dart
│   │   │   ├── project_page.dart
│   │   │   ├── profile_page.dart
│   │   │   └── settings_page.dart
│   │   └── widgets/splash_screen.dart
│   └── upload/
│       └── upload_video_page.dart
├── core/
│   └── services/
│       ├── auth_service.dart
│       └── local_video_repository.dart
└── shared/
    └── widgets/upload_progress_dialog.dart
```

---

##  Cấu trúc dữ liệu Firestore

```
users/                          ← Collection
  {uid}/                        ← Document
    displayName: String
    email: String
    photoUrl: String?
    createdAt: Timestamp
    loginMethod: String
    
    videos/                     ← Sub-collection
      {videoId}/                ← Document
        title: String
        type: String
        mediaType: String
        downloadUrl: String
        storagePath: String
        fileSize: Number
        createdAt: Timestamp
        aiContentStatus: String
        aiTitles: Array
        aiDescription: String
        aiHashtags: Array
        aiGeneratedAt: Timestamp
```

---

##  Cài đặt & chạy

### Yêu cầu
- Flutter SDK >= 3.0
- Android SDK >= 24 (Android 7.0+)
- Tài khoản Firebase
- Gemini API Key

### Các bước cài đặt

**1. Clone project**
```bash
git clone <repository-url>
cd pro_video_editor/example
```

**2. Cài đặt dependencies**
```bash
flutter pub get
```

**3. Cấu hình Firebase**
- Tạo project trên [Firebase Console](https://console.firebase.google.com)
- Tải `google-services.json` → đặt vào `android/app/`
- Bật Authentication (Email/Password)
- Tạo Firestore database
- Tạo Storage bucket

**4. Lấy Gemini API Key**
- Vào [Google AI Studio](https://aistudio.google.com/apikey)
- Tạo API Key mới

**5. Chạy app**
```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY_HERE
```

---

##  Firebase Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.auth.uid == userId;
    }
  }
}
```

---

##  Giao diện ứng dụng

| Màn hình | Mô tả |
|----------|-------|
| Đăng nhập / Đăng ký | Xác thực Firebase Auth |
| Tab Chỉnh sửa | Video cơ bản, Pro, Ảnh |
| Tab AI Lab | Tạo tiêu đề, mô tả, hashtag bằng Gemini |
| Tab Dự án | Quản lý video/ảnh đã lưu |
| Tab Tôi | Hồ sơ, cài đặt |

---

##  Kết quả đạt được

- ✅ Hoàn thành 4 nhóm chức năng chính
- ✅ Tích hợp Gemini AI tạo nội dung tự động
- ✅ Firebase Authentication + Firestore + Storage hoạt động ổn định
- ✅ Giao diện dark mode thân thiện
- ✅ Chạy thực tế trên Android (Redmi Note 13)

##  Hạn chế

- Render video 1080p chậm trên thiết bị RAM thấp (< 3GB)
- Thumbnail một số video không hiển thị do giới hạn codec Android 8.x
- Chưa hỗ trợ iOS

##  Hướng phát triển

- Hỗ trợ iOS và tối ưu hiệu năng render
- Chia sẻ trực tiếp lên TikTok, YouTube, Instagram
- Nâng cấp AI: phân tích cảm xúc video, gợi ý nhạc nền tự động
- Tính năng cộng tác nhóm

---

##  Tài liệu tham khảo

- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [pro_video_editor package](https://pub.dev/packages/pro_video_editor)
- [pro_image_editor package](https://pub.dev/packages/pro_image_editor)

---
