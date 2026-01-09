import 'package:bellezapp_web/shared/config/api_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'auth_notifier.dart';

class ExpenseReport {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final double totalExpense;
  final int expenseCount;
  final List<ExpenseCategory> byCategory;
  final double averageExpense;
  final List<ExpenseItem> topExpenses;

  ExpenseReport({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalExpense,
    required this.expenseCount,
    required this.byCategory,
    required this.averageExpense,
    required this.topExpenses,
  });

  factory ExpenseReport.fromJson(Map<String, dynamic> json) {
    return ExpenseReport(
      period: json['period'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      expenseCount: json['expenseCount'] ?? 0,
      byCategory: (json['byCategory'] as List)
          .map((c) => ExpenseCategory.fromJson(c))
          .toList(),
      averageExpense: (json['averageExpense'] as num).toDouble(),
      topExpenses: (json['topExpenses'] as List)
          .map((e) => ExpenseItem.fromJson(e))
          .toList(),
    );
  }
}

class ExpenseCategory {
  final String name;
  final String? icon;
  final double total;
  final int count;
  final List<ExpenseItem> items;

  ExpenseCategory({
    required this.name,
    this.icon,
    required this.total,
    required this.count,
    required this.items,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      name: json['name'] ?? '',
      icon: json['icon'],
      total: (json['total'] as num).toDouble(),
      count: json['count'] ?? 0,
      items: (json['items'] as List)
          .map((i) => ExpenseItem.fromJson(i))
          .toList(),
    );
  }
}

class ExpenseItem {
  final String id;
  final DateTime date;
  final double amount;
  final String? description;

  ExpenseItem({
    required this.id,
    required this.date,
    required this.amount,
    this.description,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      id: json['id'] ?? json['_id'] ?? '',
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
    );
  }
}

class ExpenseState {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> categories;
  final ExpenseReport? report;
  final bool isLoading;
  final String? error;

  ExpenseState({
    this.expenses = const [],
    this.categories = const [],
    this.report,
    this.isLoading = false,
    this.error,
  });

  ExpenseState copyWith({
    List<Map<String, dynamic>>? expenses,
    List<Map<String, dynamic>>? categories,
    ExpenseReport? report,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final Dio _dio;
  late final String _baseUrl;

  ExpenseNotifier(this._dio) : super(ExpenseState()) {
    _baseUrl = '${ApiConfig.baseUrl}/expenses';
  }

  // Cargar categorías de gastos
  Future<void> loadCategories(String storeId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/categories',
        queryParameters: {'storeId': storeId},
      );

      if (response.statusCode == 200) {
        final categories = List<Map<String, dynamic>>.from(response.data['data']['categories']);
        state = state.copyWith(categories: categories);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error cargando categorías: $e');
    }
  }

  // Crear nueva categoría de gastos
  Future<void> createCategory({
    required String storeId,
    required String name,
    String? description,
    String? icon,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/categories',
        data: {
          'storeId': storeId,
          'name': name,
          'description': description ?? 'Categoría personalizada',
          'icon': icon ?? 'tag',
        },
      );

      if (response.statusCode == 201) {
        // Recargar categorías después de crear
        await loadCategories(storeId);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error creando categoría: $e');
      throw e;
    }
  }

  // Crear gasto
  Future<void> createExpense({
    required String storeId,
    required double amount,
    required String? categoryId,
    String? description,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final response = await _dio.post(
        _baseUrl,
        data: {
          'storeId': storeId,
          'amount': amount,
          'categoryId': categoryId,
          'description': description,
        },
      );

      if (response.statusCode == 201) {
        // Recargar gastos
        await loadExpenses(storeId);
        state = state.copyWith(isLoading: false, error: null);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error creando gasto: $e');
    }
  }

  // Obtener gastos
  Future<void> loadExpenses(String storeId, {String? categoryId}) async {
    try {
      state = state.copyWith(isLoading: true);

      final params = {'storeId': storeId};
      if (categoryId != null) params['categoryId'] = categoryId;

      final response = await _dio.get(
        _baseUrl,
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final expenses = List<Map<String, dynamic>>.from(response.data['data']['expenses']);
        state = state.copyWith(expenses: expenses, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error cargando gastos: $e');
    }
  }

  // 📊 Obtener reporte de gastos
  Future<void> loadExpenseReport({
    required String storeId,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final params = {'storeId': storeId};
      if (period != null) {
        params['period'] = period;
      } else if (startDate != null && endDate != null) {
        params['startDate'] = startDate.toIso8601String();
        params['endDate'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '$_baseUrl/reports',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final reportData = response.data['data']['report'];
        final report = ExpenseReport.fromJson(reportData);
        state = state.copyWith(report: report, isLoading: false, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Error: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error cargando reporte: $e');
    }
  }

  // Actualizar gasto
  Future<void> updateExpense({
    required String expenseId,
    required double amount,
    String? description,
    String? categoryId,
    String? status,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      await _dio.patch(
        '$_baseUrl/$expenseId',
        data: {
          'amount': amount,
          'description': description,
          'categoryId': categoryId,
          'status': status,
        },
      );

      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error actualizando gasto: $e');
    }
  }

  // Eliminar gasto
  Future<void> deleteExpense(String expenseId, String storeId) async {
    try {
      state = state.copyWith(isLoading: true);

      await _dio.delete('$_baseUrl/$expenseId');

      await loadExpenses(storeId);
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error eliminando gasto: $e');
    }
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  final dio = ref.watch(dioProvider);
  return ExpenseNotifier(dio);
});

// Dio provider (usa ApiConfig para baseUrl dinámico y agrega token JWT)
final dioProvider = Provider<Dio>((ref) {
  final authState = ref.watch(authProvider);
  
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    contentType: 'application/json',
    validateStatus: (status) => status! < 500,
  ));
  
  // Agregar token JWT a los headers si existe
  if (authState.token != null && authState.token!.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer ${authState.token}';
  }
  
  return dio;
});
