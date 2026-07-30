abstract final class SupabaseConfig {
  static const projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wcssuruygqextigpobcb.supabase.co',
  );

  /// Supabase publishable keys are designed for public clients. Database
  /// access is still restricted by the signed-in user's JWT and table RLS.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_hqAfIQmiPqYArUDtn4U8IQ_B_AWmRiC',
  );
}
