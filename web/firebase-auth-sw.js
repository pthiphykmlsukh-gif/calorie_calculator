// ไฟล์: /web/firebase-auth-sw.js

// Import and initialize the Firebase SDK
importScripts("https_local/firebase-app.js");
importScripts("https_local/firebase-auth.js");

firebase.initializeApp({
  //
  // ใส่ค่า Config ของโปรเจกต์ Firebase คุณตรงนี้
  // (ไปคัดลอกจากในเว็บ Firebase Console มาใส่)
  //
  apiKey: "AIzaSyBz8QsfGuR3EDB8rElpuSIWuJNSJ24gFro",
  authDomain: "calorie-calculator-app-2025.firebaseapp.com",
  projectId: "calorie-calculator-app-2025",
  storageBucket: "calorie-calculator-app-2025.firebasestorage.app",
  messagingSenderId: "303663460854",
  appId: "1:303663460854:web:4d6a8b79f61e6adef597d7"
});

// This script is intentionally blank
// It's used by Firebase Auth to handle auth redirects