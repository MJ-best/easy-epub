import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_env.dart';
import '../../models/app_user.dart';
import '../supabase/supabase_bootstrap.dart';

class AuthService {
  final StreamController<AppUser?> _previewController =
      StreamController<AppUser?>.broadcast();
  AppUser? _previewUser;

  SupabaseClient? get _client => SupabaseBootstrap.client;
  bool get isConfigured => SupabaseBootstrap.isReady;
  bool get supportsPreviewMode => !SupabaseBootstrap.isConfigured;

  Stream<AppUser?> watchAuthState() async* {
    if (_client != null) {
      yield _mapSupabaseUser(_client!.auth.currentUser);
      yield* _client!.auth.onAuthStateChange.map(
        (event) => _mapSupabaseUser(event.session?.user),
      );
      return;
    }

    yield _previewUser;
    yield* _previewController.stream;
  }

  AppUser? get currentUser {
    if (_client != null) {
      return _mapSupabaseUser(_client!.auth.currentUser);
    }
    return _previewUser;
  }

  Future<void> signInWithGoogle() async {
    final client = _client;
    if (client == null) {
      throw StateError(
        SupabaseBootstrap.errorMessage ??
            'Supabase 설정이 없어 Google 로그인을 시작할 수 없습니다.',
      );
    }

    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppEnv.oauthRedirectTo.isEmpty ? null : AppEnv.oauthRedirectTo,
      queryParams: const {
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );
  }

  Future<void> continueWithPreview() async {
    _previewUser = const AppUser(
      id: 'preview-user',
      email: 'preview@flowforge.local',
      displayName: 'Preview Operator',
      isPreview: true,
    );
    _previewController.add(_previewUser);
  }

  Future<void> signOut() async {
    if (_client != null) {
      await _client!.auth.signOut();
      return;
    }

    _previewUser = null;
    _previewController.add(null);
  }

  AppUser? _mapSupabaseUser(User? user) {
    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata ?? const {};
    final displayName = (metadata['full_name'] ??
            metadata['name'] ??
            user.email?.split('@').first ??
            'Workspace User')
        .toString();

    return AppUser(
      id: user.id,
      email: user.email ?? 'unknown@example.com',
      displayName: displayName,
      isPreview: false,
    );
  }
}
