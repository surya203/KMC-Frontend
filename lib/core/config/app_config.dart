import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get env => dotenv.env['ENV'] ?? 'development';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  static String get apiPrefix => dotenv.env['API_PREFIX'] ?? '/api/v1';

  static String get apiV1Url => '$apiBaseUrl$apiPrefix';

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';

  static String get storageBucket =>
      dotenv.env['SUPABASE_STORAGE_BUCKET'] ?? 'verification-documents';
}
