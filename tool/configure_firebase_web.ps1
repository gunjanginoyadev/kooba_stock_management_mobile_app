# Creates a Firebase Web app and writes lib/firebase_options.dart web section.
# Run in an interactive terminal (after `firebase login`):
#   powershell -ExecutionPolicy Bypass -File tool/configure_firebase_web.ps1

$ErrorActionPreference = "Stop"
$project = "kooba-stock-management"
$appName = "Kooba Web"

Write-Host "Creating Web app '$appName' in project $project ..."
$createOut = firebase apps:create WEB $appName --project $project 2>&1 | Out-String
Write-Host $createOut

# Extract app id like 1:123:web:abc
$appId = $null
if ($createOut -match "1:\d+:web:[a-f0-9]+") {
  $appId = $Matches[0]
}

if (-not $appId) {
  Write-Host "Looking up existing Web apps..."
  $listOut = firebase apps:list --project $project 2>&1 | Out-String
  Write-Host $listOut
  if ($listOut -match "1:\d+:web:[a-f0-9]+") {
    $appId = $Matches[0]
  }
}

if (-not $appId) {
  throw "Could not determine Web app id. Create a Web app in Firebase Console and re-run."
}

Write-Host "Fetching SDK config for $appId ..."
$sdkJson = firebase apps:sdkconfig WEB $appId --project $project --json 2>&1 | Out-String
# sdkconfig --json wraps result; also try plain
$plain = firebase apps:sdkconfig WEB $appId --project $project 2>&1 | Out-String
Write-Host $plain

function Get-Field([string]$text, [string]$name) {
  if ($text -match ('"' + $name + '"\s*:\s*"([^"]+)"')) { return $Matches[1] }
  if ($text -match ($name + '\s*:\s*"([^"]+)"')) { return $Matches[1] }
  return $null
}

$apiKey = Get-Field $plain "apiKey"
if (-not $apiKey) { $apiKey = Get-Field $sdkJson "apiKey" }
$authDomain = Get-Field $plain "authDomain"
if (-not $authDomain) { $authDomain = Get-Field $sdkJson "authDomain" }
$storageBucket = Get-Field $plain "storageBucket"
if (-not $storageBucket) { $storageBucket = Get-Field $sdkJson "storageBucket" }
$messagingSenderId = Get-Field $plain "messagingSenderId"
if (-not $messagingSenderId) { $messagingSenderId = Get-Field $sdkJson "messagingSenderId" }
$measurementId = Get-Field $plain "measurementId"
if (-not $measurementId) { $measurementId = Get-Field $sdkJson "measurementId" }

if (-not $apiKey) { $apiKey = "AIzaSyAj1gQJqmthH4CN6NDscWBdFe2AHzh3rm0" }
if (-not $authDomain) { $authDomain = "$project.firebaseapp.com" }
if (-not $storageBucket) { $storageBucket = "$project.firebasestorage.app" }
if (-not $messagingSenderId) { $messagingSenderId = "366516824804" }

$measurementLine = ""
if ($measurementId) {
  $measurementLine = "    measurementId: '$measurementId',"
}

$optionsPath = Join-Path $PSScriptRoot "..\lib\firebase_options.dart"
$content = @"
// File generated for Firebase project $project.
// Android options come from android/app/google-services.json.
// Web options written by tool/configure_firebase_web.ps1

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS. '
          'Run flutterfire configure to add GoogleService-Info.plist.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '$apiKey',
    appId: '$appId',
    messagingSenderId: '$messagingSenderId',
    projectId: '$project',
    authDomain: '$authDomain',
    storageBucket: '$storageBucket',
$measurementLine
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAj1gQJqmthH4CN6NDscWBdFe2AHzh3rm0',
    appId: '1:366516824804:android:3fbf9f260221aae0a4daf1',
    messagingSenderId: '366516824804',
    projectId: '$project',
    storageBucket: 'kooba-stock-management.firebasestorage.app',
  );
}
"@

Set-Content -Path $optionsPath -Value $content -Encoding UTF8
Write-Host "Updated $optionsPath"
Write-Host "Done. Web appId=$appId"
