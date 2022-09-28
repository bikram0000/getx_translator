import 'package:flutter/material.dart';

class CheckWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'testing'.tr,
    );
  }
}

extension ScreenName on String {
  String get tr {
    return this;
  }

  String get trArgs {
    return this;
  }
}
