import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/networking/supabase_init.dart';
import '../../../../core/networking/api_constants.dart';
import '../models/sign_up_request_body.dart';

class SignUpWebServices {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> signUp(
    SignUpRequestBody signUpRequestBody,
    File? photo,
  ) async {
    try {
      // 1. Create auth user
      final authResponse = await _client.auth.signUp(
        email: signUpRequestBody.email,
        password: signUpRequestBody.password,
      );

      if (authResponse.user == null) {
        throw "Registration failed. Please try again.";
      }

      // 2. Upload photo if provided
      String? photoUrl;
      if (photo != null) {
        final String ext = photo.path.split('.').last;
        final String storagePath =
            'users/${authResponse.user!.id}/profile.$ext';

        await _client.storage
            .from(ApiConstants.avatarsBucket)
            .upload(
              storagePath,
              photo,
              fileOptions: const FileOptions(upsert: true),
            );
        photoUrl = _client.storage
            .from(ApiConstants.avatarsBucket)
            .getPublicUrl(storagePath);
      }

      final userData = await _client
          .from(ApiConstants.usersTable)
          .insert({
            'id': authResponse.user!.id,
            'full_name': signUpRequestBody.fullName,
            'email': signUpRequestBody.email,
            'phone_number': signUpRequestBody.phone,
            if (photoUrl != null) 'photo': photoUrl,
          })
          .select()
          .single();

      return {
        'userId': userData['id'],
        'token': authResponse.session?.accessToken ?? '',
        ...userData,
      };
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      debugPrint("🛑 SignUp Error: $e");
      if (e is String) rethrow;
      throw "Registration failed: $e";
    }
  }
}
