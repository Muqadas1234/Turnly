import 'package:intl/intl.dart';

class Helpers {
  static String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String formatTime(DateTime d) => DateFormat('hh:mm a').format(d);
}
