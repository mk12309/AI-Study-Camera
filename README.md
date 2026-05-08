# 📸 AI Study Camera - Snap & Learn

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-green.svg)](https://fastapi.tiangolo.com)
[![AI](https://img.shields.io/badge/AI-Gemini%201.5%20Flash-purple.svg)](https://ai.google.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**AI Study Camera** is a premium mobile application designed to revolutionize how students study. By simply snapping a photo of handwritten or printed notes, the app uses state-of-the-art AI to transform them into interactive study materials.

---

## ✨ Key Features

*   **🔍 AI Note Scanning:** High-fidelity document scanning with real-time camera preview and intelligent cropping.
*   **📝 Instant Summaries:** Transform pages of notes into concise, easy-to-read AI summaries.
*   **🧠 Interactive Quizzes:** Automatically generate Multiple Choice Questions (MCQs) from your scanned content to test your knowledge.
*   **🗂️ Smart Flashcards:** Create digital study cards with a flip-to-reveal interface for better memorization.
*   **🎧 Audio Explanations:** Listen to your notes with AI-generated audio explanations, perfect for learning on the go.
*   **📂 Organized Library:** Keep all your study materials in one place, categorized by subject and date.
*   **🌓 Premium UI/UX:** A modern, violet-themed interface with smooth animations and intuitive navigation.

---

## 🛠️ Tech Stack

### **Frontend**
*   **Framework:** Flutter (Dart)
*   **State Management:** ValueNotifiers & Reactive UI
*   **Camera:** Custom camera implementation with `camera` & `image_picker`
*   **UI Components:** Google Fonts (Outfit), Material 3, Custom animations

### **Backend**
*   **Framework:** FastAPI (Python)
*   **Database:** MongoDB
*   **OCR Engine:** EasyOCR (Local fallback)
*   **AI Engine:** Google Gemini 1.5 Flash (for summarization, quiz, and card generation)
*   **Auth:** JWT-based secure authentication

---

## 🚀 Getting Started

### **1. Prerequisites**
*   Flutter SDK installed
*   Python 3.10+ installed
*   MongoDB instance (Local or Atlas)
*   Gemini API Key

### **2. Backend Setup**
1. Navigate to the `backend` folder.
2. Create a `.env` file:
   ```env
   MONGO_URI=your_mongodb_connection_string
   GEMINI_API_KEY=your_google_ai_key
   SECRET_KEY=your_jwt_secret
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the server:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

### **3. Frontend Setup**
1. Navigate to the `frontend` folder.
2. Update `lib/main.dart` with your server's IP address:
   ```dart
   const String baseUrl = "http://YOUR_IP:8000";
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## 📱 Interface Preview

The application features 12+ meticulously designed screens including:
*   **Splash & Onboarding:** Engaging entry flow.
*   **Home Dashboard:** Quick access to all study tools.
*   **Processing Hub:** Real-time AI analysis visualization.
*   **Study Modes:** Dedicated views for Quizzes, Flashcards, and Audio.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request to improve the AI Study Camera experience.

---
*Developed with ❤️ by [mk12309](https://github.com/mk12309)*
