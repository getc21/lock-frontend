import 'package:flutter_riverpod/flutter_riverpod.dart';
import './store_detail_notifier.dart';

final storeSelector = Provider.family<Map<String, dynamic>?, String>(
  (ref, id) => ref.watch(storeDetailProvider(id)).store,
);

final isStoreLoadingSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(storeDetailProvider(id)).isLoading,
);

final storeErrorSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(storeDetailProvider(id)).error,
);

final storeNameSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(storeSelector(id))?['name'],
);

final storeAddressSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(storeSelector(id))?['address'],
);

final storePhoneSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(storeSelector(id))?['phone'],
);

final storeCitySelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(storeSelector(id))?['city'],
);

final storeManagerSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(storeSelector(id))?['manager'],
);
