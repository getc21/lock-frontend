import 'package:flutter_riverpod/flutter_riverpod.dart';
import './location_detail_notifier.dart';

final locationSelector = Provider.family<Map<String, dynamic>?, String>(
  (ref, id) => ref.watch(locationDetailProvider(id)).location,
);

final isLocationLoadingSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(locationDetailProvider(id)).isLoading,
);

final locationErrorSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(locationDetailProvider(id)).error,
);

final locationNameSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(locationSelector(id))?['name'],
);

final locationAddressSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(locationSelector(id))?['address'],
);

final locationCitySelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(locationSelector(id))?['city'],
);

final locationStateSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(locationSelector(id))?['state'],
);

final locationZipSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(locationSelector(id))?['zip'],
);
