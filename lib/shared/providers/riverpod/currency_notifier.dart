import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyModel {
  final String id;
  final String name;
  final String symbol;
  final String code;

  CurrencyModel({
    required this.id,
    required this.name,
    required this.symbol,
    required this.code,
  });
}

class CurrencyState {
  final String currentCurrencyId;
  final bool isInitialized;

  CurrencyState({
    required this.currentCurrencyId,
    required this.isInitialized,
  });

  CurrencyState copyWith({
    String? currentCurrencyId,
    bool? isInitialized,
  }) {
    return CurrencyState(
      currentCurrencyId: currentCurrencyId ?? this.currentCurrencyId,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  CurrencyNotifier() : super(CurrencyState(
    currentCurrencyId: 'usd',
    isInitialized: false,
  )) {
    _initializeCurrency();
  }

  // Monedas disponibles
  static final List<CurrencyModel> _availableCurrencies = [
    CurrencyModel(
      id: 'usd',
      name: 'Dólar Estadounidense',
      symbol: '\$',
      code: 'USD',
    ),
    CurrencyModel(
      id: 'eur',
      name: 'Euro',
      symbol: '€',
      code: 'EUR',
    ),
    CurrencyModel(
      id: 'gbp',
      name: 'Libra Esterlina',
      symbol: '£',
      code: 'GBP',
    ),
    CurrencyModel(
      id: 'jpy',
      name: 'Yen Japonés',
      symbol: '¥',
      code: 'JPY',
    ),
    CurrencyModel(
      id: 'mxn',
      name: 'Peso Mexicano',
      symbol: '\$',
      code: 'MXN',
    ),
    CurrencyModel(
      id: 'ars',
      name: 'Peso Argentino',
      symbol: '\$',
      code: 'ARS',
    ),
    CurrencyModel(
      id: 'cop',
      name: 'Peso Colombiano',
      symbol: '\$',
      code: 'COP',
    ),
    CurrencyModel(
      id: 'clp',
      name: 'Peso Chileno',
      symbol: '\$',
      code: 'CLP',
    ),
  ];

  List<CurrencyModel> get availableCurrencies => _availableCurrencies;

  // Moneda actual
  CurrencyModel get currentCurrency {
    return _availableCurrencies.firstWhere(
      (currency) => currency.id == state.currentCurrencyId,
      orElse: () => _availableCurrencies.first,
    );
  }

  // Inicializar moneda desde preferencias
  Future<void> _initializeCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getString('currency_id') ?? 'usd';

      state = state.copyWith(
        currentCurrencyId: savedCurrencyId,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(isInitialized: true);
    }
  }

  // Cambiar moneda
  Future<void> changeCurrency(String currencyId) async {
    if (currencyId == state.currentCurrencyId) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency_id', currencyId);

      state = state.copyWith(currentCurrencyId: currencyId);
    } catch (e) {
      debugPrint('Error changing currency: $e');
    }
  }

  // Formatear valor monetario
  String formatCurrency(double value) {
    return '${currentCurrency.symbol}${value.toStringAsFixed(2)}';
  }

  // Obtener símbolo de moneda actual
  String get symbol => currentCurrency.symbol;

  // Obtener código de moneda actual
  String get code => currentCurrency.code;
}

// Provider de la moneda
final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  return CurrencyNotifier();
});

// Provider para obtener la moneda actual
final currentCurrencyProvider = Provider<CurrencyModel>((ref) {
  final currencyState = ref.watch(currencyProvider);
  final notifier = ref.watch(currencyProvider.notifier);
  
  return notifier.availableCurrencies.firstWhere(
    (c) => c.id == currencyState.currentCurrencyId,
    orElse: () => notifier.availableCurrencies.first,
  );
});
