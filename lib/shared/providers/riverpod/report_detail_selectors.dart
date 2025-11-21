import 'package:flutter_riverpod/flutter_riverpod.dart';
import './report_detail_notifier.dart';

final reportSelector = Provider.family<Map<String, dynamic>?, String>(
  (ref, id) => ref.watch(reportDetailProvider(id)).report,
);

final isReportLoadingSelector = Provider.family<bool, String>(
  (ref, id) => ref.watch(reportDetailProvider(id)).isLoading,
);

final reportErrorSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(reportDetailProvider(id)).error,
);

final reportNameSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(reportSelector(id))?['name'],
);

final reportTypeSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(reportSelector(id))?['type'],
);

final reportDateSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(reportSelector(id))?['date'],
);

final reportStatusSelector = Provider.family<String?, String>(
  (ref, id) => ref.watch(reportSelector(id))?['status'],
);

final reportDataSelector = Provider.family<Map?, String>(
  (ref, id) => ref.watch(reportSelector(id))?['data'],
);
