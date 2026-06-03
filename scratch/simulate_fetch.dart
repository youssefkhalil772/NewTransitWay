import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  final currentDriverId = "00e816bb-a117-46af-b420-c0bb179e1a77"; // ahmedabden2@gmail.com
  final currentEmail = "ahmedabden2@gmail.com";

  print('1. Get driver by ID: $currentDriverId');
  final res1 = await http.get(Uri.parse('$baseUrl/rest/v1/drivers?id=eq.$currentDriverId'), headers: headers);
  print(res1.body);

  print('2. Get driver by email: $currentEmail');
  final res2 = await http.get(Uri.parse('$baseUrl/rest/v1/drivers?email=eq.$currentEmail'), headers: headers);
  print(res2.body);

}
