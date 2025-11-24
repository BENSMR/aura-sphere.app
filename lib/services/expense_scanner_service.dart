import 'dart:io';
import 'functions_service.dart';
import '../models/expense_model.dart';

class ExpenseScannerService {
  final FunctionsService _functions = FunctionsService();

  Future<ExpenseModel> scanReceipt(File imageFile) async {
    // TODO: Upload image to Storage first, then call OCR function
    final result = await _functions.callFunction('ocrProcessor', {
      'imageUrl': 'path/to/image',
    });
    
    return ExpenseModel.fromJson(result);
  }
}
