importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts(
  "https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyDMCdP2SVvVYxlaN_qmXK51IKxrPUP3UlU",
  authDomain: "benji-crm.firebaseapp.com",
  projectId: "benji-crm",
  storageBucket: "benji-crm.appspot.com",
  messagingSenderId: "432859725374",
  appId: "1:432859725374:web:72a9d87265c694c7ad5b6f",
  measurementId: "G-4YD8PF5306",
});

const messaging = firebase.messaging();
