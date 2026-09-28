import 'package:web/web.dart' as web;

String? getRecoveryCode() {
  return web.window.sessionStorage.getItem('supabase_recovery_code');
}

String? getRecoveryUrl() {
  return web.window.sessionStorage.getItem('supabase_recovery_url');
}

void removeRecoveryData() {
  web.window.sessionStorage.removeItem('supabase_recovery_code');

  web.window.sessionStorage.removeItem('supabase_recovery_url');
}
