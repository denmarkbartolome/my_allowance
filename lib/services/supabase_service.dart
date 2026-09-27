import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allowance_settings.dart';
import '../models/transaction_model.dart';

/// Every call to Supabase lives here (auth, settings, transactions).
class SupabaseService {
  SupabaseClient get _c => Supabase.instance.client;

  // ---- Auth ----
  User? get currentUser => _c.auth.currentUser;
  Session? get currentSession => _c.auth.currentSession;
  Stream<AuthState> get authChanges => _c.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) =>
      _c.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(String email, String password, {String? name}) =>
      _c.auth.signUp(
        email: email,
        password: password,
        data: {if (name != null && name.isNotEmpty) 'name': name},
      );

  Future<void> signOut() => _c.auth.signOut();

  // ---- Transactions (CRUD) ----
  Future<List<TransactionModel>> fetchTransactions() async {
    final rows = await _c
        .from('transactions')
        .select()
        .order('date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map<TransactionModel>(TransactionModel.fromMap).toList();
  }

  Future<TransactionModel> insertTransaction(TransactionModel tx) async {
    final payload = tx.toMap()..['user_id'] = currentUser!.id;
    final row = await _c.from('transactions').insert(payload).select().single();
    return TransactionModel.fromMap(row);
  }

  Future<TransactionModel> updateTransaction(TransactionModel tx) async {
    final row = await _c
        .from('transactions')
        .update(tx.toMap())
        .eq('id', tx.id!)
        .select()
        .single();
    return TransactionModel.fromMap(row);
  }

  Future<void> deleteTransaction(String id) async {
    await _c.from('transactions').delete().eq('id', id);
  }

  // ---- Allowance settings ----
  Future<AllowanceSettings> fetchSettings() async {
    final row = await _c.from('allowance_settings').select().maybeSingle();
    return row == null ? AllowanceSettings.empty : AllowanceSettings.fromMap(row);
  }

  Future<void> saveSettings(AllowanceSettings s) async {
    await _c.from('allowance_settings').upsert({
      'user_id': currentUser!.id,
      'amount': s.amount,
      'period': s.period.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}