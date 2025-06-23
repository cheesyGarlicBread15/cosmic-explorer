# 🌌 Cosmic Explorer

Cosmic Explorer is a multi-platform application (mobile, web, and desktop) that allows users to explore NASA's vast media library. The app provides stunning images, captivating videos, and informative audio clips from space missions, scientific discoveries, and astronomical phenomena.

**Website:** https://cosmic-explorer-f4ca2.web.app/

**API:** [NASA Image and Video Library](https://images.nasa.gov/docs/images.nasa.gov_api_docs.pdf)

---

## 🛸 Features

- 🌠 Browse NASA images, videos, and audio
- 🔍 Search through NASA's media library
- 🎞️ Zoomable photo viewer
- 🎧 Launch audio and video content in browser
- 🌐 Cross-platform support (Web, Android, Desktop)

---

## 🚀 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/cosmic-explorer.git
cd cosmic-explorer
```

### 2. Configure `.env`

Create a `.env` file in the root directory and add your Supabase credentials:

```env
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

> ⚠️ Be sure to add `.env` to your `.gitignore` file.

### 3. Install Dependencies

```bash
flutter pub get
```

---

## 📦 Dependencies Version

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_dotenv: ^5.2.1
  flutter_spinkit: ^5.2.1
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.1.0
  go_router: ^15.1.2
  http: ^1.4.0
  photo_view: ^0.15.0
  url_launcher: ^6.3.1
```
