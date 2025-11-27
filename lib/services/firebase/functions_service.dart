import 'package:cloud_functions/cloud_functions.dart';
import '../../core/utils/logger.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<dynamic> callFunction(String name, [Map<String, dynamic>? parameters]) async {
    try {
      final callable = _functions.httpsCallable(name);
      final result = await callable.call(parameters);
      return result.data;
    } catch (e) {
      Logger.error('Failed to call function: $name', error: e);
      rethrow;
    }
  }
}
