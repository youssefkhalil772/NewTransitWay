import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/networking/supabase_init.dart';
import '../../../core/networking/api_constants.dart';

class LoginWebServices {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw "Login failed. Please check your credentials.";
      }

      // Fetch user profile data from users table
      final userData = await _client
          .from(ApiConstants.usersTable)
          .select()
          .eq('email', email)
          .maybeSingle();

      return {
        'token': response.session?.accessToken ?? '',
        'userId': userData?['id'] ?? response.user!.id,
        'fullName': userData?['fullName'] ?? userData?['full_name'] ?? '',
        'email': email,
        'phone': userData?['phone_number'] ?? userData?['phone'] ?? userData?['phoneNumber'] ?? '',
        'photo': userData?['photo'] ?? '',
        'userPoints': userData?['balance'] ?? userData?['points'] ?? 0,
        ...?userData,
      };
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      if (e is String) rethrow;
      throw "Check your internet connection and try again";
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      debugPrint("Server Google Login User: ${response.user?.id}");

      if (response.user == null) {
        throw "Google authentication failed";
      }

      // Fetch or create user profile
      final email = response.user!.email ?? '';
      var userData = await _client
          .from(ApiConstants.usersTable)
          .select()
          .eq('email', email)
          .maybeSingle();

      userData ??= await _client.from(ApiConstants.usersTable).insert({
          'id': response.user!.id,
          'email': email,
          'full_name': response.user!.userMetadata?['full_name'] ?? '',
          'photo': response.user!.userMetadata?['avatar_url'] ?? '',
        }).select().single();

      return {
        'token': response.session?.accessToken ?? '',
        'userId': userData['id'] ?? response.user!.id,
        'fullName': userData['fullName'] ?? userData['full_name'] ?? '',
        'email': email,
        'phone': userData['phone_number'] ?? userData['phone'] ?? '',
        'photo': userData['photo'] ?? '',
        ...userData,
      };
    } on AuthException catch (e) {
      throw "Google authentication error: ${e.message}";
    } catch (e) {
      if (e is String) rethrow;
      throw "Google authentication error: $e";
    }
  }
}
