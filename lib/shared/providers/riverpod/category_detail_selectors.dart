import 'package:flutter_riverpod/flutter_riverpod.dart';
import './category_detail_notifier.dart';

final categorySelector = Provider.family<Map<String, dynamic>?, String>(
  (ref, id) => ref.watch(categoryDetailProvider(id)).category,
);

final isCategoryLoadingSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(categoryDetailProvider(id)).isLoading,
);

final categoryErrorSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(categoryDetailProvider(id)).error,
);

final categoryNameSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(categorySelector(id))?['name'],
);

final categoryDescriptionSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(categorySelector(id))?['description'],
);

final categoryImageSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(categorySelector(id))?['image'],
);

final categoryIsActiveSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(categorySelector(id))?['isActive'] ?? false,
);
