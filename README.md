# Getx Translator

2022 © Bikramaditya Meher

[![Pub](https://img.shields.io/pub/v/getx_translator.svg)](https://pub.dartlang.org/packages/getx_translator) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/bikram0000/getx_translator/blob/master/LICENSE)

A command-line application for generating language strings file for Getx Flutter. Easy translation with google sheet for Getx.

Go to google sheets and make an Apps script file past this code with replacing you sheet id and sheet name, you can get sheet id from sheet url.
```dart
function doPost(request) {
  var error = false;
  var result;
  if (request.parameter.spreadsheetId == null) {
    error = true;
    result = { "status": "FAILED", "message": "Invalid Sheet Id" };
  }
  if (request.parameter.sheetName == null) {
    error = true;
    result = { "status": "FAILED", "message": "Please Provide Sheet Name" };
  }
  if (request.parameter.values == null) {
    error = true;
    result = { "status": "FAILED", "message": "Please Provide Values" };
  }

  var sheetId = request.parameter.spreadsheetId;
  var sheetName = request.parameter.sheetName;
  if (sheetId != '16gg_KvyPgXYrKzt12JtIZm4DVgNkxarzVlRHfXMyy5Y') {
    error = true;
    result = { "status": "FAILED", "message": "Please Provide Correct Sheet Id" };
  }
  if (sheetName != 'Sheet1') {
    error = true;
    result = { "status": "FAILED", "message": "Please Provide Correct Sheet Name" };
  }
  if (error) {
    return ContentService
      .createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);
  }
  // Open Google Sheet using ID
  var sheet = SpreadsheetApp.openById(sheetId).getSheetByName(sheetName);
  result = { "status": "SUCCESS" };
  if (request.parameter.deleteRow != null) {
    //will delete numbers of rows coming from values..
    try {
      var deletingRow = JSON.parse(request.parameter.values);
      for (var i = 0; i < deletingRow.length; i++) {
        sheet.deleteRow((deletingRow[i] - i));
      }
    } catch (exc) {
      result = { "status": "FAILED", "message": exc.toString() };
    }
  } else {
    try {
      var values = JSON.parse(request.parameter.values);
      sheet.getRange(sheet.getLastRow() + 1, 1, values.length, 1).setValues(values);
    } catch (exc) {
      result = { "status": "FAILED", "message": exc.toString() };
    }

  }


  // Return result
  return ContentService
    .createTextOutput(JSON.stringify(result))
    .setMimeType(ContentService.MimeType.JSON);
}


function doGet(request) {

  // Open Google Sheet using ID
  var error = false;
  var result;
  if (request.parameter.spreadsheetId == null) {
    error = true;
    result = { "status": "FAILED", "message": "Invalid Sheet Id" };
  }
  if (request.parameter.sheetName == null) {
    error = true;
    result = { "status": "FAILED", "message": "Please Provide Sheet Name" };
  }

  var sheetId = request.parameter.spreadsheetId;
  var sheetName = request.parameter.sheetName;
  if (sheetId != '16gg_KvyPgXYrKzt12JtIZm4DVgNkxarzVlRHfXMyy5Y') {
    error = true;
    result = { "status": "FAILED", "message": "Please Provide Correct Sheet Id" };
  }
  if (sheetName != 'Sheet1') {
    error = true;
    result = { "status": "FAILED", "message": "Please Provide Correct Sheet Name" };
  }
  if (error) {
    return ContentService
      .createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);
  }
  var column = request.parameter.column;
  var row = request.parameter.row;
  var all = request.parameter.all ?? 'false';

  var sheet = SpreadsheetApp.openById(sheetId).getSheetByName(sheetName);
  var rowNumbers = request.parameter.rowNumbers ?? sheet.getLastRow();
  var columnNumbers = request.parameter.columnNumbers ?? 1;

  var result = { "status": "SUCCESS" };
  var values;
  if (all == 'false') {
    values = sheet.getRange(row, column, rowNumbers, columnNumbers).getValues();
  } else {
    values = sheet.getDataRange().getValues();
  }
  result['data'] = values;
  // Return result
  return ContentService
    .createTextOutput(JSON.stringify(result))
    .setMimeType(ContentService.MimeType.JSON);
}
```


Add this to your pubspec.yaml file and replace your sheet id, sheet name and url from Apps script.
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