import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'lib/core/networking/supabase_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  final client = SupabaseConfig.client;

  try {
    // We try to call the rpc
    final response = await client.rpc('get_user_email_by_phone', params: {'p_phone': '01234567890'});
    print('RPC SUCCESS! Response: \$response');
  } catch (e) {
    print('RPC FAILED: \$e');
  }

  try {
    final response2 = await client.rpc('get_driver_email_by_phone', params: {'p_phone': '01234567890'});
    print('RPC 2 SUCCESS! Response: \$response2');
  } catch (e) {
    print('RPC 2 FAILED: \$e');
  }
}
