// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBkT5FyjxX9crfOHkebOXph5vbn44oEu_o",
  authDomain: "gestion-stages-notifs.firebaseapp.com",
  projectId: "gestion-stages-notifs",
  storageBucket: "gestion-stages-notifs.firebasestorage.app",
  messagingSenderId: "41889985478",
  appId: "1:41889985478:web:5d675a1ca1d3e8cb6fb8c7"
});

const messaging = firebase.messaging();
