import 'package:flutter/material.dart';

import '../../themes/colors.dart';

class ProgressIndicaror {
  static showProgressIndicator(BuildContext context) {
    return showDialog(

      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            color: ColorsManager.mainBlue,
          ),
        );
      },
    );
  }
}
