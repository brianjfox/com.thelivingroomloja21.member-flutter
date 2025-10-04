# Push Notifications Setup Guide

This guide explains how to complete the push notification setup for The Living Room Member app.

## Overview

The app has been configured with Firebase Cloud Messaging (FCM) for push notifications. The following components have been implemented:

- ✅ Firebase dependencies added to `pubspec.yaml`
- ✅ Bundle ID updated to `com.thelivingroomloja21.member`
- ✅ iOS push notification capabilities configured
- ✅ Android push notification permissions and services configured
- ✅ Push notification service implementation created
- ✅ Settings screen updated with notification controls
- ✅ Firebase configuration files created (placeholder)

## Required Steps to Complete Setup

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Add your app with bundle ID: `com.thelivingroomloja21.member`

### 2. Android Configuration

1. Download the `google-services.json` file from Firebase Console
2. Replace the placeholder file at `android/app/google-services.json`
3. The Google Services plugin is already configured in the build files

### 3. iOS Configuration

1. Download the `GoogleService-Info.plist` file from Firebase Console
2. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist`
3. Add the file to your Xcode project:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Right-click on the Runner folder
   - Select "Add Files to Runner"
   - Choose the `GoogleService-Info.plist` file
   - Make sure "Copy items if needed" is checked
   - Add to target: Runner

### 4. iOS Push Notification Certificates

1. In Firebase Console, go to Project Settings > Cloud Messaging
2. Upload your iOS APNs certificate or key
3. For development: Use APNs Auth Key (recommended)
4. For production: Use APNs certificate

### 5. Server Integration

The app includes a `PushNotificationService` that handles:
- FCM token generation and management
- Permission requests
- Message handling (foreground, background, terminated)
- Topic subscription/unsubscription
- **Automatic token registration with your existing API**

The service automatically registers FCM tokens with your existing `/api/push/register` endpoint:
- Uses the authenticated user's email from the current session
- Sends the FCM token and platform information
- Handles token refresh automatically
- Re-registers tokens when they change

**No additional server integration needed** - the app uses your existing API endpoint!

### 6. Testing

1. Run the app on a physical device (push notifications don't work on simulators)
2. Go to Settings > Notifications and enable push notifications
3. Check the console logs for the FCM token
4. Test sending notifications from Firebase Console

## Features Implemented

### Push Notification Service (`lib/services/push_notification_service.dart`)

- **Initialization**: Sets up Firebase and requests permissions
- **Token Management**: Gets and refreshes FCM tokens
- **Message Handling**: Handles foreground, background, and terminated app states
- **Topic Management**: Subscribe/unsubscribe from notification topics
- **Permission Management**: Check and request notification permissions

### Settings Integration

- Added notification settings to the Settings screen
- Toggle to enable/disable push notifications
- Display of FCM token for debugging
- Permission status checking

### Platform-Specific Configuration

#### iOS
- Background modes for remote notifications
- APNs integration ready
- Permission handling for iOS 10+

#### Android
- Required permissions for notifications
- Firebase messaging service
- Android 13+ notification permission handling

## Usage Examples

### Sending Notifications from Server

Your existing API server can send notifications using the stored FCM tokens:

```javascript
// Example Node.js server code using your existing database
const admin = require('firebase-admin');

// Get user's FCM tokens from your PUSH_TOKEN table
const tokens = await getPushTokensForUser(userEmail);

// Send to specific user
for (const token of tokens) {
  await admin.messaging().send({
    token: token.token,
    notification: {
      title: 'New Event',
      body: 'A new wine tasting event has been added!'
    },
    data: {
      eventId: '123',
      type: 'event'
    }
  });
}

// Send to all users
const allTokens = await getAllPushTokens();
const messages = allTokens.map(token => ({
  token: token.token,
  notification: {
    title: 'App Update',
    body: 'New features are now available!'
  }
}));
await admin.messaging().sendAll(messages);
```

### Handling Notifications in App

The service automatically handles different notification states:

- **Foreground**: Messages are received and can be displayed as in-app notifications
- **Background**: Messages trigger the background handler
- **Terminated**: Messages are handled when the app is opened

## Troubleshooting

### Common Issues

1. **Token not generated**: Check Firebase configuration files
2. **Notifications not received**: Verify APNs certificates (iOS) or Google Services (Android)
3. **Permission denied**: Check device notification settings
4. **Background messages not handled**: Ensure the background handler is properly registered

### Debug Steps

1. Check console logs for FCM token
2. Verify Firebase project configuration
3. Test with Firebase Console notifications
4. Check device notification settings
5. Verify server integration

## Next Steps

1. Complete Firebase project setup
2. Replace configuration files with real ones
3. Implement server-side notification sending
4. Test on physical devices
5. Set up notification topics for different user groups
6. Implement notification analytics and tracking

## Security Considerations

- FCM tokens should be sent securely to your server
- Implement proper authentication for notification endpoints
- Consider user privacy and notification preferences
- Store tokens securely on the server
- Implement token refresh handling
