// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/10.12.3/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.3/firebase-messaging-compat.js');

// Initialize Firebase
firebase.initializeApp({
  apiKey: "AIzaSyCGKqhloD3M3EZs_frlLNoyMWykta52AMQ",
  authDomain: "projectmedi-46b08.firebaseapp.com",
  projectId: "projectmedi-46b08",
  storageBucket: "projectmedi-46b08.firebasestorage.app",
  messagingSenderId: "801951855531",
  appId: "1:801951855531:web:b887909be815b4994b58ee",
  measurementId: "G-0F99T3DF8Z"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
  });
});