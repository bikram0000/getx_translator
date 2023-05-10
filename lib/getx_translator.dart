library getx_translator;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:getx_translator/model/input_model.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:yaml/yaml.dart';

class GetxTranslator {
  InputModel? inputModel;
  List<String> data = [];
  List<String> allData = [];
  List<String> oldData = [];
  Map<String, String> keys = {};
  List<String> keyArguments = [
    'path',
    'output_path',
    'sheet_url',
    'sheet_id',
    'sheet_name',
    'column',
    'row',
    'all',
    'key_name',
  ];
  var logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        noBoxingByDefault: true,
      ));
  static GetxTranslator? _instance;

  GetxTranslator._internal();

  static GetxTranslator get instance => _getInstance();

  static GetxTranslator _getInstance() {
    _instance ??= GetxTranslator._internal();
    return _instance!;
  }

  ///scanning ... generating.. uploading... and removing old keys...
  exec(List<String> arguments) async {
    loadKeys(arguments);
    if ((keys['path'] ?? '').isEmpty) {
      logger.e('[GETX_TRANSLATOR] Directory can not be empty.');
      return;
    }
    Directory directory = Directory(keys['path']!);
    if (await directory.exists()) {
      logger.i(
          '[GETX_TRANSLATOR] creating.. Output Directory ${keys['output_path']}');
      await createOutputDir();
      await getOldKey(directory);
      await filesInDirectory(directory, shouldAll: true);
      await uploadKey(directory);
      await removeOldUnusedKey();
      logger.i('[GETX_TRANSLATOR] Successfully Uploaded ... :)');
      logger.i(
          '[GETX_TRANSLATOR] Go to Sheet and Generate Translation file ... than run [getx_translator:update]..');
    } else {
      logger.e('[GETX_TRANSLATOR] Directory not exists :: ${directory.path}');
    }
  }

  ///get key and update....
  update(List<String> arguments) async {
    loadKeys(arguments);
    if ((keys['output_path'] ?? '').isEmpty) {
      logger.e('[GETX_TRANSLATOR] "output_path" directory can not be empty.');
      return;
    }
    Directory directory = Directory(keys['output_path']!);
    if (await directory.exists()) {
      await updateLanguage(directory);
      logger.i('[GETX_TRANSLATOR] Completed ... :)');
    } else {
      logger.i('[GETX_TRANSLATOR] Directory not exists :: ${directory.path}');
    }
  }

  ///remove old unused key...
  remove(List<String> arguments) async {
    loadKeys(arguments);
    if ((keys['path'] ?? '').isEmpty) {
      logger.e('[GETX_TRANSLATOR] Directory can not be empty.');
      return;
    }
    Directory directory = Directory(keys['path']!);
    if (await directory.exists()) {
      await filesInDirectory(directory, shouldAll: true);
      if (allData.isNotEmpty) {
        await getOldKey(directory);
        if (oldData.isEmpty) {
          logger.e('[GETX_TRANSLATOR] Old strings not found...');
        } else {
          await removeOldUnusedKey();
          logger.i('[GETX_TRANSLATOR] Completed ... :) ');
        }
      } else {
        logger.e('[GETX_TRANSLATOR] Strings not found...');
      }
    } else {
      logger.i('[GETX_TRANSLATOR] Directory not exists :: ${directory.path}');
    }
  }

  void loadKeys(List<String> arguments) {
    if (inputModel != null) {
      keys = inputModel!.toJson();
    }
    if (arguments.isEmpty) {
      keys = loadConfigFile();
    }
    if (arguments.isNotEmpty) {
      final parser = ArgParser();
      for (var element in keyArguments) {
        parser.addOption(element);
      }
      final parsedArgs = parser.parse(arguments);
      for (var element in keyArguments) {
        checkKeyAndInsert(parsedArgs, element);
      }
    }
    for (var element in keyArguments) {
      if (keys[element] == null) {
        switch (element) {
          case 'key_name':
            keys[element] = 'key-getx-translator';
            break;
          case 'output_path':
            keys[element] = 'assets/language';
            break;
          case 'path':
            keys[element] = 'lib';
            break;
          case 'all':
            keys[element] = 'false';
            break;
          case 'column':
          case 'row':
            keys[element] = '1';
            break;
        }
      }
    }
  }

  Future<void> createOutputDir() async {
    var folders = keys['output_path']!.split('/');
    String dirPath = '';
    if (folders.length > 1) {
      await Future.forEach<String>(folders, (element) async {
        if (dirPath.isNotEmpty) {
          dirPath = '$dirPath/$element';
        } else {
          dirPath = element;
        }
        var directory2 = Directory(dirPath);
        if (!await directory2.exists()) {
          await directory2.create();
        }
      });
    }
  }

  Future<void> updateLanguage(Directory directory) async {
    if (haveSheetDetails()) {
      logger.i('[GETX_TRANSLATOR] Getting language files from sheets....');
      List<List<String>> allData = await getSheetData(
          url: keys['sheet_url']!,
          column: int.parse(keys['column'] ?? '1'),
          row: int.parse(keys['row'] ?? '1'),
          sheetId: keys['sheet_id']!,
          sheetName: keys['sheet_name']!,
          all: 'true');
      if (allData.isEmpty) {
        return;
      }
      logger.i('[GETX_TRANSLATOR] Generating language files from sheets....');
      List<File> languageFile = [];
      await Future.forEach<String>(allData.first, (element) async {
        File file = File('${directory.path}/$element.json');
        if (!await file.exists()) {
          await file.create();
        } else {
          await file.delete();
        }
        languageFile.add(file);
      });
      allData.removeAt(0);

      ///remove all file name...
      ///creating language model from sheet....
      logger.i('[GETX_TRANSLATOR] Generating Local Model file from sheets....');
      File languageModelFile = File('${directory.path}/Local_model.json');
      if (!await languageModelFile.exists()) {
        await languageModelFile.create();
      } else {
        await languageModelFile.delete();
      }
      int languageIndex = 0;
      await languageModelFile.writeAsString('[',
          mode: FileMode.writeOnlyAppend);
      await Future.forEach<String>(allData.first, (data) async {
        if (languageIndex != 0) {
          dynamic languageMap;
          try {
            languageMap = jsonDecode(data);
          } catch (e) {
            logger.e('[GETX_TRANSLATOR] Can not decode json :: $data');
          }
          if (languageMap != null) {
            await languageModelFile.writeAsString(
                (languageIndex == allData.first.length - 1) ? data : '$data,',
                mode: FileMode.writeOnlyAppend);
          }
        }
        languageIndex++;
      });
      await languageModelFile.writeAsString(']',
          mode: FileMode.writeOnlyAppend);
      allData.removeAt(0);

      ///remove all language Model...
      int rowIndex = 0;
      await Future.forEach<List<String>>(allData, (element) async {
        int index = 0;
        String key = element.first;
        await Future.forEach<String>(element, (data) async {
          if (index == 0) {
            //it is only for key list...
            if (rowIndex == 0) {
              await languageFile[index]
                  .writeAsString('["$data",', mode: FileMode.writeOnlyAppend);
            } else if (rowIndex == allData.length - 1) {
              //if is last
              await languageFile[index]
                  .writeAsString('"$data"]', mode: FileMode.writeOnlyAppend);
            } else {
              await languageFile[index]
                  .writeAsString('"$data",', mode: FileMode.writeOnlyAppend);
            }
          } else {
            //it is a language map file.. not a list..
            //starting..
            if (rowIndex == 0) {
              await languageFile[index]
                  .writeAsString('{', mode: FileMode.writeOnlyAppend);
            }
            if (data.isNotEmpty) {
              await languageFile[index].writeAsString(
                  '"$key":"${data.replaceAll('\$ s', '\$s').replaceAll('"', '\\"').replaceAll("\n", "\\n")}"',
                  mode: FileMode.writeOnlyAppend);
            }
            //ending...
            if (rowIndex == allData.length - 1) {
              await languageFile[index]
                  .writeAsString('}', mode: FileMode.writeOnlyAppend);
            } else {
              await languageFile[index]
                  .writeAsString(',', mode: FileMode.writeOnlyAppend);
            }
          }
          index++;
        });
        rowIndex++;
      });
    } else {
      logger.i(
          '[GETX_TRANSLATOR] Can not Generate language files from local. To get only keys please run [getx_translator:main] ....');
      // var directory = Directory(keys['output_path']!);
      // String keyPath = "${directory.path}/${keys['key_name']}.json";
      // File keyFile = File(keyPath);
      // if (!await keyFile.exists()) {
      //   logger.i(
      //       '[GETX_TRANSLATOR] Not found key file from local.... $keyPath please run main..');
      // }
      // oldData = List<String>.from(jsonDecode(await keyFile.readAsString()));
      // String filePath = "${directory.path}/en_us.json";
      // logger.i(
      //     '[GETX_TRANSLATOR] Generating language files from local.... $filePath');
      // File file = File(filePath);
      // if (!await file.exists()) {
      //   await file.create();
      // } else {
      //   await file.delete();
      // }
      // await file.writeAsString('{', mode: FileMode.append);
      // await Future.forEach<String>(oldData, (element) async {
      //   await file.writeAsString(
      //       '"$element":"${element.replaceAll('\$ s', '\$s')}",',
      //       mode: FileMode.writeOnlyAppend);
      // });
      // await file.writeAsString('}', mode: FileMode.append);
    }
  }

  Future<void> uploadKey(Directory directory) async {
    if (haveSheetDetails()) {
      logger.i('[GETX_TRANSLATOR] Uploading New Keys to sheet ..');
      List<List<String>> newData = [];
      for (var element in data) {
        newData.add([element]);
      }
      if (newData.isNotEmpty) {
        await uploadKeySheet(
            url: keys['sheet_url']!,
            sheetId: keys['sheet_id']!,
            sheetName: keys['sheet_name']!,
            value: newData);
      }
    } else {
      logger.i(
          '[GETX_TRANSLATOR] Uploading New Keys to local directory .. ${directory.path}/${keys['key_name']}.json');
      await uploadToLocalJson();
    }
  }

  Future<void> getOldKey(Directory directory) async {
    if (haveSheetDetails()) {
      logger.i('[GETX_TRANSLATOR] Getting keys from sheet..');
      var sheetData = await getSheetData(
          url: keys['sheet_url']!,
          column: int.parse(keys['column'] ?? '1'),
          row: int.parse(keys['row'] ?? '1'),
          sheetId: keys['sheet_id']!,
          sheetName: keys['sheet_name']!);
      sheetData.removeAt(0); //first will remove that key name
      sheetData.removeAt(0); // it will remove the model name from key row..
      for (var element in sheetData) {
        oldData.add(element.first);
      }
    } else {
      logger.i(
          '[GETX_TRANSLATOR] Getting keys from local directory.. ${directory.path}/${keys['key_name']}.json');
      oldData = await getKeyFromLocal();
    }
  }

  Future<File> uploadToLocalJson() async {
    oldData.addAll(data);
    String csvData = jsonEncode(oldData);
    var directory = Directory(keys['output_path']!);
    String filePath = "${directory.path}/${keys['key_name']}.json";
    File file = File(filePath);
    return await file.writeAsString(csvData);
  }

  Future<List<String>> getKeyFromLocal() async {
    var directory = Directory(keys['output_path']!);
    if (!await directory.exists()) {
      return [];
    }
    String filePath = "${directory.path}/${keys['key_name']}.json";
    File file = File(filePath);
    if (await file.exists()) {
      return List<String>.from(jsonDecode(await file.readAsString()));
    }
    return [];
  }

  Future<void> createLanguageFile(
      {String? name, required Map<String, String> data}) async {
    name ??= data.values.first;
    var directory = Directory(keys['output_path']!);
    if (!await directory.exists()) {
      await directory.create();
    }
    String filePath = "${directory.path}/${name}_lang.json";
    File file = File(filePath);
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> filesInDirectory(Directory dir, {bool shouldAll = false}) async {
    logger.i('[GETX_TRANSLATOR] Scanning Folder .. ${dir.path}');
    var lister = await dir.list(recursive: false, followLinks: false).toList();
    await Future.forEach<FileSystemEntity>(lister, (entity) async {
      FileSystemEntityType type = await FileSystemEntity.type(entity.path);
      if (type == FileSystemEntityType.file) {
        logger.i('[GETX_TRANSLATOR] Processing File .. ${entity.path}');
        File file = File(entity.path);
        var s = await file.readAsString();
        RegExp regExp = RegExp(
          "(?!{)([\"'])([^,\"']+?)\\1(\n|\\s)?.(?:tr|trArgs)(?![a-zA-Z0-9_])",
        );
        var string = regExp.allMatches(s);
        for (var element in string) {
          if (element.group(2) != null) {
            if (shouldAll) {
              allData.add(element.group(2)!);
            }
            if (!oldData.contains(element.group(2)) &&
                !data.contains(element.group(2))) {
              logger
                  .i('[GETX_TRANSLATOR] Found String .. [${element.group(2)}]');
              data.add(element.group(2)!);
            }
          }
        }
      } else if (type == FileSystemEntityType.directory) {
        await filesInDirectory(Directory(entity.path), shouldAll: shouldAll);
      }
    });
  }

  Future<List<FileSystemEntity>> dirContents(Directory dir) {
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: false);
    lister.listen((file) => files.add(file),
        onDone: () => completer.complete(files));
    return completer.future;
  }

  Map<String, String> loadConfigFile() {
    final File file = File('pubspec.yaml');
    final String yamlString = file.readAsStringSync();
    final Map yamlMap = loadYaml(yamlString);

    if (yamlMap['getx_translator'] is! Map) {
      throw Exception('getx_translator was not found');
    }
    final Map<String, String> config = <String, String>{};
    for (MapEntry<dynamic, dynamic> entry
        in yamlMap['getx_translator'].entries) {
      config[entry.key] = entry.value.toString();
    }

    return config;
  }

  Future<void> removeOldUnusedKey() async {
    logger.i('[GETX_TRANSLATOR] Checking old and new keys...');
    List<int> deletingRow = [];
    List<String> deletingRowStr = [];
    int index = 0;
    if (haveSheetDetails()) {
      for (var element in oldData) {
        if (!allData.contains(element)) {
          deletingRow.add(index + 3);

          ///only for online data... first two because sheet start from 1 and heading in that position than model so.
        }
        index++;
      }
      logger.i('[GETX_TRANSLATOR] Removing old unused keys from sheet ...');
      if (deletingRow.isNotEmpty) {
        await removeOldKeySheet(
            url: keys['sheet_url']!,
            sheetId: keys['sheet_id']!,
            sheetName: keys['sheet_name']!,
            value: deletingRow);
      }
    } else {
      for (var element in oldData) {
        if (!allData.contains(element)) {
          deletingRowStr.add(element);
        }
        index++;
      }
      if (deletingRowStr.isEmpty) {
        return;
      }
      logger.i('[GETX_TRANSLATOR] Removing old unused keys from local ...');
      Directory dir = Directory(keys['output_path']!);
      var lister =
          await dir.list(recursive: false, followLinks: false).toList();
      await Future.forEach<FileSystemEntity>(lister, (entity) async {
        FileSystemEntityType type = await FileSystemEntity.type(entity.path);
        if (type == FileSystemEntityType.file) {
          logger.i('[GETX_TRANSLATOR] Processing File .. ${entity.path}');
          File file = File(entity.path);
          var s = await file.readAsString();
          if (entity.path.contains('${keys['key_name']}.json')) {
            List<String> keyFile = List<String>.from(jsonDecode(s));
            for (var element in deletingRowStr) {
              keyFile.remove(element);
            }
            await file.writeAsString(jsonEncode(keyFile));
          } else {
            //if it is not a key file means map..
            Map<String, String> keyFile =
                Map<String, String>.from(jsonDecode(s));
            for (var element in deletingRowStr) {
              keyFile.remove(element);
            }
            await file.writeAsString(jsonEncode(keyFile));
          }
        }
      });
    }
  }

  ///Sheet services...
  Future<List<List<String>>> getSheetData({
    required String url,
    required String sheetId,
    required String sheetName,
    required int column,
    required int row,
    int? columnNumbers,
    int? rowNumbers,
    String? all,
  }) async {
    url =
        '$url?column=$column&row=$row&spreadsheetId=$sheetId&sheetName=$sheetName';
    if (columnNumbers != null) {
      url = '$url&columnNumbers=$columnNumbers';
    }
    if (rowNumbers != null) {
      url = '$url&rowNumbers=$rowNumbers';
    }
    if (all != null) {
      url = '$url&all=$all';
    }
    var response = await http.get(
      Uri.parse(url),
    );
    var map = jsonDecode(response.body);
    if ((map as Map)['status'] == 'success'.toUpperCase()) {
      return List<List<String>>.from(
          map['data'].map<List<String>>((e) => List<String>.from(e)));
    }

    return [];
  }

  Future<bool> uploadKeySheet({
    required String url,
    required String sheetId,
    required String sheetName,
    required List<List<String>> value,
  }) async {
    bool got = false;
    var sendData = {
      'spreadsheetId': sheetId,
      'sheetName': sheetName,
      'values': jsonEncode(value),
    };
    var response = await http.post(Uri.parse(url), body: sendData);
    if (response.isRedirect || response.statusCode == 302) {
      var response2 = await http.get(
        Uri.parse(response.headers['location']!),
      );
      var map = jsonDecode(response2.body);
      if ((map as Map)['status'] == 'success'.toUpperCase()) {
        got = true;
      }
    }

    return got;
  }

  Future<bool> removeOldKeySheet({
    required String url,
    required String sheetId,
    required String sheetName,
    required List<int> value,
  }) async {
    bool got = false;
    var sendData = {
      'spreadsheetId': sheetId,
      'sheetName': sheetName,
      'values': jsonEncode(value),
      'deleteRow': 'true',
    };
    if (value.isNotEmpty) {
      var response = await http.post(Uri.parse(url), body: sendData);
      if (response.isRedirect || response.statusCode == 302) {
        var response2 = await http.get(
          Uri.parse(response.headers['location']!),
        );
        var map = jsonDecode(response2.body);
        if ((map as Map)['status'] == 'success'.toUpperCase()) {
          got = true;
        }
      }
    }
    return got;
  }

  ///miscellaneous
  void checkKeyAndInsert(ArgResults parsedArgs, String s) {
    if (parsedArgs[s] != null) {
      keys[s] = parsedArgs[s];
    }
  }

  bool haveSheetDetails() {
    return !((keys['sheet_url'] ?? '').isEmpty ||
        (keys['sheet_id'] ?? '').isEmpty ||
        (keys['sheet_name'] ?? '').isEmpty);
  }
}
