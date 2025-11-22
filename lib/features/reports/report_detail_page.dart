import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/report_detail_notifier.dart';
import '../../shared/providers/riverpod/report_detail_selectors.dart';

class ReportDetailPage extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailPage({Key? key, required this.reportId}) : super(key: key);

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reportDetailProvider(widget.reportId).notifier).loadItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isReportLoadingSelector(widget.reportId));
    final error = ref.watch(reportErrorSelector(widget.reportId));
    final report = ref.watch(reportSelector(widget.reportId));

    return DashboardLayout(
      title: 'Detalle de Reporte',
      currentRoute: '/reports',
      child: isLoading
          ? const Center(child: LoadingIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(reportDetailProvider(widget.reportId).notifier).loadItem();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : report != null
                  ? _ReportDetailContent(report: report, reportId: widget.reportId)
                  : const Center(child: Text('No se encontró el reporte')),
    );
  }
}

class _ReportDetailContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> report;
  final String reportId;

  const _ReportDetailContent({Key? key, required this.report, required this.reportId}) : super(key: key);

  @override
  ConsumerState<_ReportDetailContent> createState() => _ReportDetailContentState();
}

class _ReportDetailContentState extends ConsumerState<_ReportDetailContent> {
  late TextEditingController _nameController;
  late TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.report['name'] ?? '');
    _typeController = TextEditingController(text: widget.report['type'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(reportNameSelector(widget.reportId));
    final type = ref.watch(reportTypeSelector(widget.reportId));
    final date = ref.watch(reportDateSelector(widget.reportId));
    final status = ref.watch(reportStatusSelector(widget.reportId));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? 'Cargando...', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Tipo: ${type ?? 'N/A'}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Estado: ${status ?? 'N/A'}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Fecha: ${date ?? 'N/A'}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Información General', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reporte actualizado'), backgroundColor: Colors.green),
                    );
                  },
                  child: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
