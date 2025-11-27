import 'firebase/functions_service.dart';

class ContractService {
  final FunctionsService _functions = FunctionsService();

  Future<String> generateContract(Map<String, dynamic> contractData) async {
    final result = await _functions.callFunction('generateContract', contractData);
    return result['contractUrl'];
  }
}
