import 'package:flutter_riverpod/flutter_riverpod.dart';
import './user_detail_notifier.dart';

final userSelector = Provider.family<Map<String, dynamic>?, String>(
  (ref, id) => ref.watch(userDetailProvider(id)).user,
);

final isUserLoadingSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(userDetailProvider(id)).isLoading,
);

final userErrorSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(userDetailProvider(id)).error,
);

final userNameSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(userSelector(id))?['name'],
);

final userEmailSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(userSelector(id))?['email'],
);

final userPhoneSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(userSelector(id))?['phone'],
);

final userRoleSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(userSelector(id))?['role'],
);

final userIsActiveSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(userSelector(id))?['isActive'] ?? false,
);

final userAvatarSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(userSelector(id))?['avatar'],
);
