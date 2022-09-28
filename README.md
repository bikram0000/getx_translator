# Getx Translator

2022 © Bikramaditya Meher

[![Pub](https://img.shields.io/pub/v/getx_translator.svg)](https://pub.dartlang.org/packages/getx_translator) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/bikram0000/getx_translator/blob/master/LICENSE)

A command-line application for generating language strings file for Getx Flutter. Easy translation with google sheet.


Add this to your pubspec.yaml file and replace your data.
```yaml
getx_translator:
  path: "lib"
  output_path: "assets/language"
  sheet_url: "https://script.google.com/macros/s/AKfycbwSnBW7NeRWV3vy9i7U8sX8RPyPkC2S8UGYbnehlOKMT5ueJNfwelsJogWTEitnqg8X7g/exec"
  sheet_name: "Sheet1"
  sheet_id: "16gg_KvyPgXYrKzt12JtIZm4DVgNkxarzVlRHfXMyy5Y"
```

Run this code for :: Scanning ... Generating.. Uploading...  Strings.
```dart
flutter pub run getx_translator:main
```

Run this code for getting key and update language files.
```dart
flutter pub run getx_translator:update
```

Run this code for remove unused strings.
```dart
flutter pub run getx_translator:remove
```
for more information and please checkout example folder.