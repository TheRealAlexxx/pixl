---
title: React Native app guide
group: Guides
description: Marco's traveler app is a good example of what this guide is for, a mobile app that actually does something, tracks stuff, sends notifications, works on your phone.
---

# React Native app guide

Marco's traveler app is a good example of what this guide is for, a mobile app that actually does something, tracks stuff, sends notifications, works on your phone.

## Setting up your project

The fastest way to get moving is Expo, it skips a lot of the native setup pain. Install it and start a new project:

```bash
npx create-expo-app my-app
cd my-app
npx expo start
```

That last command gives you a QR code, scan it with the Expo Go app on your phone and your app shows up live, and updates as you save files.

## The basic structure

Expo projects come with a file based router by default, every file inside the app folder becomes a screen. A simple screen looks like:

```javascript
import { View, Text, StyleSheet } from 'react-native';

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Marco's Routes</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20, paddingTop: 60 },
  title: { fontSize: 24, fontWeight: 'bold' }
});
```

## Storing data locally

For something like tracking routes or logging inventory, AsyncStorage is the easiest starting point, it's basically a simple key value store on the device:

```javascript
import AsyncStorage from '@react-native-async-storage/async-storage';

await AsyncStorage.setItem('routes', JSON.stringify(routeList));
const saved = await AsyncStorage.getItem('routes');
```

## Notifications

Expo has a notifications module built in. After asking the user for permission, you can schedule a local notification like this:

```javascript
import * as Notifications from 'expo-notifications';

await Notifications.scheduleNotificationAsync({
  content: { title: "New region reached", body: "You've arrived somewhere new" },
  trigger: null
});
```

## Getting it onto your phone for real

While you're building, Expo Go is fine. Once it's finished, you can either keep it as an Expo Go project for your submission, or build a real standalone app with `eas build` if you want something closer to a real App Store style release.
