import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/app_storage.dart';

/// Owns the selected [ThemeMode] and persists it across restarts.
///
/// The first launch follows the device setting; once the shopper picks a mode
/// explicitly that choice is stored and restored on the next start.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(AppStorage storage) : _storage = storage, super(_read(storage));

  /// Non-persisting variant for previews and tests.
  ThemeCubit.inMemory([super.initial = ThemeMode.system]) : _storage = null;

  static const String storageKey = 'mini_store.theme_mode.v1';

  final AppStorage? _storage;

  static ThemeMode _read(AppStorage storage) {
    return switch (storage.read<String>(storageKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> select(ThemeMode mode) async {
    if (mode == state) {
      return;
    }

    emit(mode);
    final storage = _storage;
    if (storage == null) {
      return;
    }

    await storage.write(storageKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
