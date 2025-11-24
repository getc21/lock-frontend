import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModel {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;

  ThemeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
  });
}

class ThemeState {
  final String currentThemeId;
  final ThemeMode themeMode;
  final bool isInitialized;

  ThemeState({
    required this.currentThemeId,
    required this.themeMode,
    required this.isInitialized,
  });

  ThemeState copyWith({
    String? currentThemeId,
    ThemeMode? themeMode,
    bool? isInitialized,
  }) {
    return ThemeState(
      currentThemeId: currentThemeId ?? this.currentThemeId,
      themeMode: themeMode ?? this.themeMode,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  // Temas disponibles
  static final List<ThemeModel> _availableThemes = [
    ThemeModel(
      id: 'beauty',
      name: 'Belleza Rosada',
      description: 'Tema elegante con tonos rosados',
      primaryColor: const Color(0xFFEC407A),
      accentColor: const Color(0xFFF06292),
    ),
    ThemeModel(
      id: 'ocean',
      name: 'Océano Azul',
      description: 'Tema fresco y profesional',
      primaryColor: const Color(0xFF1565C0),
      accentColor: const Color(0xFF1976D2),
    ),
    ThemeModel(
      id: 'nature',
      name: 'Naturaleza Verde',
      description: 'Tema natural y relajante',
      primaryColor: const Color(0xFF2E7D32),
      accentColor: const Color(0xFF43A047),
    ),
    ThemeModel(
      id: 'sunset',
      name: 'Atardecer Naranja',
      description: 'Tema cálido y energético',
      primaryColor: const Color(0xFFE65100),
      accentColor: const Color(0xFFFF6D00),
    ),
  ];

  ThemeNotifier() : super(ThemeState(
    currentThemeId: 'beauty',
    themeMode: ThemeMode.system,
    isInitialized: false,
  ));

  List<ThemeModel> get availableThemes => _availableThemes;

  // Tema actual
  ThemeModel get currentTheme {
    return _availableThemes.firstWhere(
      (theme) => theme.id == state.currentThemeId,
      orElse: () => _availableThemes.first,
    );
  }

  // Inicializar tema desde preferencias
  Future<void> initializeTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeId = prefs.getString('theme_id') ?? 'beauty';
      final savedThemeMode = prefs.getString('theme_mode') ?? 'system';

      state = state.copyWith(
        currentThemeId: savedThemeId,
        themeMode: _parseThemeMode(savedThemeMode),
        isInitialized: true,
      );
    } catch (e) {

      state = state.copyWith(isInitialized: true);
    }
  }

  // Cambiar tema
  Future<void> changeTheme(String themeId) async {
    if (themeId == state.currentThemeId) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_id', themeId);

      state = state.copyWith(currentThemeId: themeId);
    } catch (e) {

    }
  }

  // Cambiar modo de tema
  Future<void> changeThemeMode(ThemeMode mode) async {
    if (mode == state.themeMode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', _themeModeToString(mode));

      state = state.copyWith(themeMode: mode);
    } catch (e) {

    }
  }

  // Resetear a tema por defecto
  Future<void> resetTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('theme_id');
      await prefs.remove('theme_mode');

      state = state.copyWith(
        currentThemeId: 'beauty',
        themeMode: ThemeMode.system,
      );
    } catch (e) {

    }
  }

  // Verificar si es el tema actual
  bool isCurrentTheme(String themeId) => state.currentThemeId == themeId;

  // Verificar si es el modo actual
  bool isCurrentThemeMode(ThemeMode mode) => state.themeMode == mode;

  // Parsear string a ThemeMode
  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Convertir ThemeMode a string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

// Provider del tema
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

// Provider para obtener los colores del tema actual
final themeColorsProvider = Provider<ThemeModel>((ref) {
  final themeState = ref.watch(themeProvider);
  final notifier = ref.watch(themeProvider.notifier);
  
  return notifier.availableThemes.firstWhere(
    (t) => t.id == themeState.currentThemeId,
    orElse: () => notifier.availableThemes.first,
  );
});

