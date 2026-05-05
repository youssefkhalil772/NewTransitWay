import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandlers {
  static String getErrorMessage(dynamic e) {
    final String errorString = e.toString().toLowerCase();

    if (e is SocketException || errorString.contains('socketexception') || errorString.contains('network_error')) {
      return "Network connection issue. Please check your internet.";
    }

    if (e is PostgrestException) {
      if (errorString.contains('not found')) return "Resource not found.";
      if (errorString.contains('permission denied')) return "Access denied. Please login again.";
      return "Database error. Please try again later.";
    }

    if (errorString.contains('timeout')) {
      return "Request timed out. Please try again.";
    }

    if (errorString.contains('auth')) {
      return "Authentication failed. Please login again.";
    }

    // Default clean message
    return "Something went wrong. Please try again.";
  }
}
