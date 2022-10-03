class LocalModel {
  String? title;
  String? title2;
  String? languageCode;
  String? countryCode;
  String? local;
  String? fileName;

  LocalModel(
      {this.title,
      this.title2,
      this.languageCode,
      this.countryCode,
      this.local,
      this.fileName});

  LocalModel.fromJson(Map<String, dynamic> json) {
    if (json["title"] is String) {
      title = json["title"];
    }
    if (json["title2"] is String) {
      title2 = json["title2"];
    }
    if (json["language_code"] is String) {
      languageCode = json["language_code"];
    }
    if (json["country_code"] is String) {
      countryCode = json["country_code"];
    }
    if (json["local"] is String) {
      local = json["local"];
    }
    if (json["file_name"] is String) {
      fileName = json["file_name"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["title"] = title;
    data["title2"] = title2;
    data["language_code"] = languageCode;
    data["country_code"] = countryCode;
    data["local"] = local;
    data["file_name"] = fileName;
    return data;
  }

  LocalModel copyWith({
    String? title,
    String? title2,
    String? languageCode,
    String? countryCode,
    String? local,
    String? fileName,
  }) =>
      LocalModel(
        title: title ?? this.title,
        title2: title2 ?? this.title2,
        languageCode: languageCode ?? this.languageCode,
        countryCode: countryCode ?? this.countryCode,
        local: local ?? this.local,
        fileName: fileName ?? this.fileName,
      );
}
