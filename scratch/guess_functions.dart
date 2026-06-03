import 'package:http/http.dart' as http;

void main() async {
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/functions/v1';

  final guesses = [
    'scan-pay',
    'scan_pay',
    'scanpay',
    'ScanPay',
    'Scan-Pay',
    'scan-qr',
    'pay-ticket',
  ];

  print('Guessing function names...\\n');
  for (final fn in guesses) {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$fn'),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: '{}',
      );
      if (response.statusCode != 404) {
        print('✅ FOUND: $fn (status: ${response.statusCode})');
      }
    } catch (e) {
      // ignore
    }
  }
}
