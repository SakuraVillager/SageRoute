/// Only public client configuration belongs in this class.
abstract final class ClientConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const amapAndroidKey = String.fromEnvironment('AMAP_ANDROID_KEY');
  static const amapWebKey = String.fromEnvironment('AMAP_WEB_KEY');
  static const amapSecurityCode = String.fromEnvironment(
    'AMAP_WEB_SECURITY_CODE',
  );
  static const amapServiceHost = String.fromEnvironment('AMAP_SERVICE_HOST');
  static Map<String, String> get environment => {
    'SUPABASE_URL': supabaseUrl,
    'SUPABASE_ANON_KEY': supabaseKey,
  };
  static Map<String, dynamic> get mapConfig => {
    'key': amapWebKey,
    'securityJsCode': amapSecurityCode,
    'serviceHost': amapServiceHost,
  };
}
