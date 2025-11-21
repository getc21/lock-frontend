import 'package:flutter_riverpod/flutter_riverpod.dart';
import './supplier_detail_notifier.dart';

/// Selectores para supplier
final supplierSelector = Provider.family<Map<String, dynamic>?, String>(
  (ref, id) => ref.watch(supplierDetailProvider(id)).supplier,
);

final isSupplierLoadingSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(supplierDetailProvider(id)).isLoading,
);

final supplierErrorSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(supplierDetailProvider(id)).error,
);

final supplierNameSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(supplierSelector(id))?['name'],
);

final supplierEmailSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(supplierSelector(id))?['email'],
);

final supplierPhoneSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(supplierSelector(id))?['phone'],
);

final supplierCitySelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(supplierSelector(id))?['city'],
);

final supplierIsActiveSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(supplierSelector(id))?['isActive'] ?? false,
);
