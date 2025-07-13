# API Key Setup Guide

This project uses Google Cloud API keys for weather and maps services. To set up the project properly, follow these steps:

## 1. Get Your Google Cloud API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Weather API
   - Geocoding API
   - Maps JavaScript API
4. Create credentials (API Key) for your project
5. Copy your API key

## 2. Configure the API Key

### For Dart/Flutter Code:

1. Copy the template file:
   ```bash
   cp lib/config/api_config_template.dart lib/config/api_config.dart
   ```

2. Open `lib/config/api_config.dart` and replace `YOUR_GOOGLE_CLOUD_API_KEY_HERE` with your actual API key:
   ```dart
   static const String googleCloudApiKey = 'your_actual_api_key_here';
   ```

### For Android Manifest:

1. Copy the template manifest file:
   ```bash
   cp android/app/src/main/AndroidManifest.template.xml android/app/src/main/AndroidManifest.xml
   ```

2. Open `android/app/src/main/AndroidManifest.xml` and replace `YOUR_ANDROID_MAPS_API_KEY` with your actual Google Maps API key:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY" android:value="your_actual_android_maps_api_key"/>
   ```

## 3. Security Notes

- The `lib/config/api_config.dart` file is already added to `.gitignore` to prevent it from being committed to version control
- The `android/app/src/main/AndroidManifest.xml` file is also added to `.gitignore` to prevent API keys from being committed
- Never commit your actual API keys to GitHub or any public repository
- The template files (`api_config_template.dart` and `AndroidManifest.template.xml`) are safe to commit as they don't contain real keys

## 4. API Key Restrictions (Recommended)

For security, consider setting up API key restrictions in Google Cloud Console:

1. Go to your API key settings in Google Cloud Console
2. Set application restrictions (e.g., Android apps, iOS apps, HTTP referrers)
3. Set API restrictions to only the APIs you need (Weather API, Geocoding API, Maps JavaScript API)

## 5. Environment Variables (Alternative)

For production apps, consider using environment variables or secure storage solutions instead of hardcoded API keys.

## Troubleshooting

If you encounter API-related errors:
1. Verify your API key is correct
2. Check that the required APIs are enabled in Google Cloud Console
3. Ensure your API key has the necessary permissions
4. Check if you've hit any usage limits 