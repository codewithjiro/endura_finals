import 'package:flutter/cupertino.dart';

// Database constants
const String kBoxDatabase = 'database';

// Color constants - Grape Purple
const Color kPrimary = Color(0xFF6F2DA8);

// Dialog helper
Future<T?> showThemedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

