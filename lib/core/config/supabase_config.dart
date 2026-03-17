/// Supabase backend configuration.
///
/// Replace the placeholders below with your project's URL and anon key
/// from: Supabase Dashboard → Project Settings → API.
/// See SUPABASE_SETUP.md for step-by-step setup.
class SupabaseConfig {
  static const String supabaseUrl = 'https://rdeixwtjateysiraqojn.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkZWl4d3RqYXRleXNpcmFxb2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MjUwNTEsImV4cCI6MjA4OTMwMTA1MX0.oRy3bNMjnHRW4QsJV3cL8nrTRbZqPq28DdQC4H9ct3I';

  /// True when URL and key have been set (not the placeholders).
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.startsWith('YOUR_') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.startsWith('YOUR_');
}

