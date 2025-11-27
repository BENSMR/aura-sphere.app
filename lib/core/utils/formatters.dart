import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, {String symbol = '\$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String date(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String dateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  static String number(int number) {
    return NumberFormat('#,###').format(number);
  }

  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  static String phone(String phone) {
    if (phone.length == 10) {
      return '(${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }
}
