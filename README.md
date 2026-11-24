<div align="center">
  <img src="assets/app_icon.png" alt="ClarifyAI Logo" width="120" height="120" />
  <h1>ClarifyAI</h1>
  <p><strong>An AI-Powered Smart Study Assistant & Source-Cited Research Companion</strong></p>
<p>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
    <img src="https://img.shields.io/badge/State%20Management-BLoC%20%2F%20Cubit-purple?style=for-the-badge" alt="BLoC" />
  </p>
</div>
---
📖 Overview
ClarifyAI is a cross-platform mobile application built with Flutter designed to help students simplify complex academic materials, conduct source-cited research, and organize their study sessions into dedicated subject libraries. By integrating multimodal AI reasoning with real-time web and video search APIs, ClarifyAI transforms uploaded lecture notes, documents, and images into clear, structured explanations in both Arabic and English.
---
✨ Key Features
🧠 AI Multimodal Tutor: Upload documents, PDFs, or photos of study notes to get simplified explanations, summaries, and step-by-step breakdowns powered by the Google Gemini API.
🔍 Source-Cited Smart Research: Perform deep academic queries with verified web citations using the Tavily Search API.
🎥 Curated Video Recommendations: Automatically fetches the top 3 relevant educational videos matching the user's input language (Arabic or English) via the YouTube Data API v3.
📚 Subject-Specific Libraries: Organize past AI tutoring sessions, research notes, and study materials into structured, persistent libraries synced with Cloud Firestore.
🔐 Secure Authentication: Full user authentication and session management backed by Firebase Authentication.
🎨 Custom Brand Identity: Cohesive dark-navy visual theme (`#020921`) with adaptive app icons (`flutter_launcher_icons`) and zero-flicker native splash screen (`flutter_native_splash`).
---
🏗️ Architecture & Tech Stack
The project follows a Feature-First Clean Architecture combined with BLoC / Cubit for predictable state management:
```text
lib/
├── core/
│   ├── network/
│   │   └── dio_client.dart          # Configured HTTP client for external APIs
│   └── theme/
│       └── app_theme.dart           # Application color palette & typography
├── features/
│   ├── ai_tutor/                    # Multimodal file/image explanation (Gemini)
│   │   ├── data/
│   │   └── logic/
│   ├── auth/                        # Firebase login, registration & state
│   │   ├── data/
│   │   ├── logic/
│   │   └── presentation/
│   ├── libraries/                   # Subject folders & saved study sessions
│   │   ├── data/
│   │   ├── logic/
│   │   └── presentation/
│   └── smart_research/              # Web-cited research & YouTube integration
│       ├── data/
│       └── logic/
├── firebase_options.dart            # Platform-specific Firebase configuration
└── main.dart                        # Entry point, dotenv & splash initialization
```
Core Packages
Category	Packages
State Management	`flutter_bloc`
Networking & Env	`dio`, `flutter_dotenv`
Backend & Cloud	`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
Branding & UI	`flutter_launcher_icons`, `flutter_native_splash`
---
🚀 Getting Started
Prerequisites
Flutter SDK (`>= 3.0.0`)
Dart SDK (`>= 3.0.0`)
A configured Firebase Project (with Email/Password Auth, Firestore, and Storage enabled)
API keys for Google Gemini, YouTube Data API v3, and Tavily
Installation & Setup
Clone the repository:
```bash
   git clone https://github.com/your-username/clarify_ai.git
   cd clarify_ai
   ```
Install dependencies:
```bash
   flutter pub get
   ```
Configure Environment Variables:
Create a file named `app.env` inside the `assets/` directory (`assets/app.env`) and add your API keys:
```env
   GEMINI_API_KEY=your_gemini_api_key_here
   YOUTUBE_API_KEY=your_youtube_data_api_key_here
   TAVILY_API_KEY=your_tavily_api_key_here
   ```
> **Note:** `assets/app.env` is excluded in `.gitignore` to keep your API keys secure.
Configure Firebase:
Run the FlutterFire CLI to link your Firebase project and generate `lib/firebase_options.dart`:
```bash
   flutterfire configure
   ```
Generate App Icons & Splash Screen (Optional):
```bash
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```
Run the application:
```bash
   flutter run
   ```
---
👨‍💻 Author
Ziad Nasser Mohamed Mostafa  
Mobile Application Developer (Flutter)
---
📄 License
This project is developed as an academic graduation project and is licensed under the MIT License.
