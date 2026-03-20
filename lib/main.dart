import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const ProviderScope(child: AgentFlowApp()));
}
