import 'dart:io';

String? supabaseIntegrationSkipReason() {
  return Platform.environment['RUN_SUPABASE_INTEGRATION'] == 'true'
      ? null
      : 'Set RUN_SUPABASE_INTEGRATION=true to run Supabase integration tests.';
}
