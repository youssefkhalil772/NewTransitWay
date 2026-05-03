import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_init.dart';
import 'api_constants.dart';

class ApiService {
  final SupabaseClient _client = SupabaseConfig.client;

  // ── SELECT (GET equivalent) ─────────────────────────────────────
  Future<List<dynamic>> getAll(
    String table, {
    String select = '*',
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = _client.from(table).select(select);

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      final response = await query;
      return response as List<dynamic>;
    } catch (e) {
      debugPrint("🛑 Supabase getAll($table) Error: $e");
      rethrow;
    }
  }

  // ── SELECT single row ───────────────────────────────────────────
  Future<Map<String, dynamic>> getOne(
    String table, {
    String select = '*',
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = _client.from(table).select(select);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.single();
      return response;
    } catch (e) {
      debugPrint("🛑 Supabase getOne($table) Error: $e");
      rethrow;
    }
  }

  // ── SELECT with maybeSingle (can return null) ───────────────────
  Future<Map<String, dynamic>?> getOneOrNull(
    String table, {
    String select = '*',
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = _client.from(table).select(select);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.maybeSingle();
      return response;
    } catch (e) {
      debugPrint("🛑 Supabase getOneOrNull($table) Error: $e");
      rethrow;
    }
  }

  // ── INSERT (POST equivalent) ────────────────────────────────────
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      debugPrint("🛑 Supabase insert($table) Error: $e");
      rethrow;
    }
  }

  // ── UPDATE (PUT equivalent) ─────────────────────────────────────
  Future<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = _client.from(table).update(data);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.select().single();
      return response;
    } catch (e) {
      debugPrint("🛑 Supabase update($table) Error: $e");
      rethrow;
    }
  }

  // ── UPDATE multiple rows ────────────────────────────────────────
  Future<void> updateMany(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = _client.from(table).update(data);

      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query;
    } catch (e) {
      debugPrint("🛑 Supabase updateMany($table) Error: $e");
      rethrow;
    }
  }

  // ── UPSERT ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.from(table).upsert(data).select().single();
      return response;
    } catch (e) {
      debugPrint("🛑 Supabase upsert($table) Error: $e");
      rethrow;
    }
  }

  // ── RPC (Remote Procedure Call) ─────────────────────────────────
  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _client.rpc(functionName, params: params ?? {});
      return response;
    } catch (e) {
      debugPrint("🛑 Supabase rpc($functionName) Error: $e");
      rethrow;
    }
  }

  // ── File Upload to Supabase Storage ─────────────────────────────
  Future<String?> uploadFile(String bucket, String path, File file) async {
    try {
      await _client.storage
          .from(bucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint("🛑 Supabase uploadFile($bucket/$path) Error: $e");
      rethrow;
    }
  }

  // ── PUT with file upload (profile update replacement) ───────────
  Future<Map<String, dynamic>> updateProfile({
    required String table,
    required Map<String, dynamic> fields,
    required Map<String, dynamic> filters,
    File? file,
    String fileKey = 'photo',
  }) async {
    try {
      // Upload photo if provided
      if (file != null) {
        // Generate unique path
        final String filtersKey = filters.values.join('_');
        final String ext = file.path.split('.').last;
        final String storagePath =
            '$table/$filtersKey/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';

        final photoUrl = await uploadFile(
          ApiConstants.avatarsBucket,
          storagePath,
          file,
        );
        if (photoUrl != null) {
          fields[fileKey] = photoUrl;
        }
      }

      // Update the table
      return await update(table, fields, filters: filters);
    } catch (e) {
      debugPrint("🛑 Supabase updateProfile($table) Error: $e");
      rethrow;
    }
  }
}
