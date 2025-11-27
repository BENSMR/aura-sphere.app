import 'package:cloud_functions/cloud_functions.dart';

class OpenAICrmService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Request CRM insights for current user
  /// contactIds optional to limit scope
  Future<Map<String, dynamic>> generateCrmInsights({
    required String userId,
    List<String>? contactIds,
  }) async {
    final HttpsCallable callable = _functions.httpsCallable(
      'generateCrmInsights',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call({
      'userId': userId,
      'contactIds': contactIds ?? [],
    });

    return Map<String, dynamic>.from(result.data as Map);
  }
}
