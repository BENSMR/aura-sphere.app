import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Service for managing user profiles in Supabase
/// Extends Supabase Auth with public.users table for application data
class UserService {
  final _supabase = Supabase.instance.client;

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user's profile from public.users table
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user');

    return await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
  }

  /// Watch user profile changes in real-time
  Stream<Map<String, dynamic>?> watchUserProfile(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String displayName,
    required String timezone,
    required String locale,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user');

    await _supabase.from('users').update({
      'display_name': displayName,
      'timezone': timezone,
      'locale': locale,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Get user's AuraToken balance
  Future<BigInt> getAuraTokenBalance(String userId) async {
    final data = await _supabase
        .from('users')
        .select('aura_tokens')
        .eq('id', userId)
        .single();
    return BigInt.from(data['aura_tokens'] as int);
  }

  /// Credit AuraTokens to user (admin only)
  Future<void> creditAuraTokens({
    required String userId,
    required BigInt amount,
    required String reason,
  }) async {
    // Start transaction
    final currentData = await _supabase
        .from('users')
        .select('aura_tokens')
        .eq('id', userId)
        .single();

    final currentBalance = BigInt.from(currentData['aura_tokens'] as int);
    final newBalance = currentBalance + amount;

    // Update balance
    await _supabase
        .from('users')
        .update({'aura_tokens': newBalance.toInt()})
        .eq('id', userId);

    // Log transaction
    await _supabase.from('aura_token_transactions').insert({
      'user_id': userId,
      'amount': amount.toInt(),
      'reason': reason,
      'balance_after': newBalance.toInt(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get user's role
  Future<String> getUserRole(String userId) async {
    final data = await _supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();
    return data['role'] as String;
  }

  /// List all users (admin only)
  Future<List<Map<String, dynamic>>> listAllUsers() async {
    return await _supabase
        .from('users')
        .select()
        .order('created_at', ascending: false);
  }
}
