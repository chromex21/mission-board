/* Firebase Cloud Messaging Service Worker */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Keep in sync with lib/firebase_options.dart (web)
firebase.initializeApp({
  apiKey: 'AIzaSyAqBqOi5HI2GqcWAXJSjqDzgNRhNW9zXlU',
  authDomain: 'mission-board-b8dbc.firebaseapp.com',
  projectId: 'mission-board-b8dbc',
  storageBucket: 'mission-board-b8dbc.firebasestorage.app',
  messagingSenderId: '359577654813',
  appId: '1:359577654813:web:860381d6e647f10e7118f4',
  measurementId: 'G-7GFTKVVBS7',
});

const messaging = firebase.messaging();

// Optional: background message handler
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'New message';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: payload.notification?.icon,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
