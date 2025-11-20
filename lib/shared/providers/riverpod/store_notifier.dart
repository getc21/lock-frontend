import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../store_provider.dart' as store_api;
import 'auth_notifier.dart';

// Estado de tiendas
class StoreState {
  final List<Map<String, dynamic>> stores;
  final Map<String, dynamic>? currentStore;
  final bool isLoading;
  final String errorMessage;

  StoreState({
    this.stores = const [],
    this.currentStore,
    this.isLoading = false,
    this.errorMessage = '',
  });

  StoreState copyWith({
    List<Map<String, dynamic>>? stores,
    Map<String, dynamic>? currentStore,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StoreState(
      stores: stores ?? this.stores,
      currentStore: currentStore ?? this.currentStore,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier para tiendas
class StoreNotifier extends StateNotifier<StoreState> {
  final Ref ref;

  StoreNotifier(this.ref) : super(StoreState());

  late store_api.StoreProvider _storeProvider;

  // Inicializar el provider con el token del auth
  void _initStoreProvider() {
    final authState = ref.read(authProvider);
    _storeProvider = store_api.StoreProvider(authState.token);
  }

  // Cargar tiendas
  Future<void> loadStores({bool autoSelect = true}) async {
    _initStoreProvider();

    final authState = ref.read(authProvider);
    if (authState.token.isEmpty) {
      state = state.copyWith(
        errorMessage: 'No hay sesión activa',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _storeProvider.getStores();

      if (result['success']) {
        final stores = List<Map<String, dynamic>>.from(result['data']);
        state = state.copyWith(stores: stores);

        if (autoSelect) {
          await _selectInitialStore();
        } else {
          if (kDebugMode) {
            print('🔵 StoreNotifier: Tiendas cargadas sin auto-selección');
          }
        }
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando tiendas',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Seleccionar tienda inicial
  Future<void> _selectInitialStore() async {
    if (state.stores.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStoreId = prefs.getString('selected_store_id');

      if (savedStoreId != null) {
        final savedStore = state.stores.firstWhere(
          (store) => store['_id'].toString() == savedStoreId,
          orElse: () => {},
        );

        if (savedStore.isNotEmpty) {
          state = state.copyWith(currentStore: savedStore);
          return;
        }
      }

      // Si no hay tienda guardada, seleccionar la primera
      state = state.copyWith(currentStore: state.stores.first);
      await _saveSelectedStore(state.stores.first);
    } catch (e) {
      if (kDebugMode) {
        print('Error en _selectInitialStore: $e');
      }
      if (state.stores.isNotEmpty) {
        state = state.copyWith(currentStore: state.stores.first);
      }
    }
  }

  // Guardar tienda seleccionada
  Future<void> _saveSelectedStore(Map<String, dynamic> store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_store_id', store['_id'].toString());
    } catch (e) {
      if (kDebugMode) {
        print('Error guardando tienda seleccionada: $e');
      }
    }
  }

  // Seleccionar tienda
  void selectStore(Map<String, dynamic> store) {
    final previousStore = state.currentStore;
    state = state.copyWith(currentStore: store);
    _saveSelectedStore(store);

    // Si la tienda cambió, notificar a otros providers
    if (previousStore?['_id'] != store['_id']) {
      _onStoreChanged();
    }
  }

  // Callback cuando cambia la tienda
  void _onStoreChanged() {
    // Esto puede ser usado para refrescar otros datos
    if (kDebugMode) {
      print('🔵 Store changed to ${state.currentStore?['name']}');
    }
  }

  // Limpiar tiendas
  void clearStores() {
    state = StoreState();
  }

  // Obtener tienda por ID
  Future<Map<String, dynamic>?> getStoreById(String id) async {
    _initStoreProvider();
    state = state.copyWith(isLoading: true);

    try {
      final result = await _storeProvider.getStoreById(id);

      if (result['success']) {
        state = state.copyWith(isLoading: false);
        return result['data'];
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error obteniendo tienda',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return null;
    }
  }
}

// Provider
final storeProvider = StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  return StoreNotifier(ref);
});
