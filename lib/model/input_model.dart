class InputModel {
  String? path;
  String? outputPath;
  String? sheetUrl;
  String? sheetId;
  String? sheetName;
  int? column;
  int? row;
  bool? all;
  String? keyName;

  InputModel(
      {this.path = 'lib',
      this.outputPath = 'assets/language',
      this.sheetUrl,
      this.sheetId,
      this.sheetName,
      this.column = 1,
      this.row = 1,
      this.all = true,
      this.keyName = 'key-getx-translator'});

  InputModel.fromJson(Map<String, dynamic> json) {
    if (json["path"] is String) {
      path = json["path"];
    } else {
      path = 'lib';
    }
    if (json["output_path"] is String) {
      outputPath = json["output_path"];
    } else {
      outputPath = 'assets/language';
    }
    if (json["sheet_url"] is String) {
      sheetUrl = json["sheet_url"];
    }
    if (json["sheet_id"] is String) {
      sheetId = json["sheet_id"];
    }
    if (json["sheet_name"] is String) {
      sheetName = json["sheet_name"];
    }
    if (json["column"] is int) {
      column = json["column"];
    }
    if (json["row"] is int) {
      row = json["row"];
    }
    if (json["all"] is bool) {
      all = json["all"];
    }
    if (json["key_name"] is String) {
      keyName = json["key_name"];
    }
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};
    data["path"] = path!;
    data["output_path"] = outputPath!;
    if (sheetUrl != null) {
      data["sheet_url"] = sheetUrl!;
    }
    if (sheetId != null) {
      data["sheet_id"] = sheetId!;
    }
    if (sheetName != null) {
      data["sheet_name"] = sheetName!;
    }

    data["column"] = (column ?? 1).toString();
    data["row"] = (row ?? 1).toString();
    data["all"] = '${all ?? false}';
    data["key_name"] = keyName ?? 'key-getx-translator';
    return data;
  }

  InputModel copyWith({
    String? path,
    String? outputPath,
    String? sheetUrl,
    String? sheetId,
    String? sheetName,
    int? column,
    int? row,
    bool? all,
    String? keyName,
  }) =>
      InputModel(
        path: path ?? this.path,
        outputPath: outputPath ?? this.outputPath,
        sheetUrl: sheetUrl ?? this.sheetUrl,
        sheetId: sheetId ?? this.sheetId,
        sheetName: sheetName ?? this.sheetName,
        column: column ?? this.column,
        row: row ?? this.row,
        all: all ?? this.all,
        keyName: keyName ?? this.keyName,
      );
}
