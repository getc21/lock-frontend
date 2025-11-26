import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/user_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/models/user.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        ref.read(userProvider.notifier).loadUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final storeState = ref.watch(storeProvider);

    return DashboardLayout(
      currentRoute: '/users',
      title: 'Usuarios',
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usuarios',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing8),
                    Text(
                      '${userState.users.length} usuarios registrados',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUserDialog(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nuevo Usuario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing24,
                      vertical: AppSizes.spacing16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing24),

            // Data Table
            if (userState.isLoading)
              SizedBox(
                height: 600,
                child: Card(
                  child: Center(
                    child: LoadingIndicator(
                      message: 'Cargando usuarios...',
                    ),
                  ),
                ),
              )
            else if (userState.users.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.spacing48),
                  child: Text(
                    'No hay usuarios registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 600,
                  child: DataTable2(
                    columnSpacing: AppSizes.spacing12,
                    horizontalMargin: AppSizes.spacing12,
                    minWidth: 900,
                    columns: const [
                      DataColumn2(
                        label: Text('Nombre'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Email'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Rol'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Tienda'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Acciones'),
                        size: ColumnSize.S,
                      ),
                    ],
                    rows: _buildUserRows(userState.users, storeState),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DataRow2> _buildUserRows(List<Map<String, dynamic>> users, StoreState storeState) {
    return users.map((userMap) {
      final user = User.fromMap(userMap);
      return DataRow2(
        cells: [
          DataCell(Text(user.fullName)),
          DataCell(Text(user.email)),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role.name).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Text(
                _getRoleName(user.role),
                style: TextStyle(
                  color: _getRoleColor(user.role.name),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          DataCell(
            user.stores != null && user.stores!.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: user.stores!.map((store) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          store['name'] ?? 'Sin nombre',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  )
                : user.role == UserRole.admin
                    ? const Text('Todas las tiendas', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic))
                    : TextButton.icon(
                        onPressed: () => _showAssignStoreDialog(context, user, storeState),
                        icon: const Icon(Icons.add_business, size: 16),
                        label: const Text('Asignar tienda', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _showUserDialog(context, user: user),
                  tooltip: 'Editar',
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _showDeleteDialog(context, user.id ?? '', user.fullName),
                  tooltip: 'Eliminar',
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      case 'employee':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.manager:
        return 'Gerente';
      case UserRole.employee:
        return 'Empleado';
    }
  }

  void _showUserDialog(BuildContext context, {User? user}) {
    final usernameController = TextEditingController(text: user?.username ?? '');
    final firstNameController = TextEditingController(text: user?.firstName ?? '');
    final lastNameController = TextEditingController(text: user?.lastName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    var selectedRole = user?.role.name ?? 'employee';
    final isLoading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (ctx, loading, _) => AlertDialog(
            title: Text(user == null ? 'Nuevo Usuario' : 'Editar Usuario'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      enabled: user == null && !loading,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: const OutlineInputBorder(),
                        hintText: 'Ej: carlos',
                        filled: user != null,
                        fillColor: user != null ? Colors.grey[200] : null,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: firstNameController,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Carlos',
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: lastNameController,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Pérez',
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: emailController,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: passwordController,
                      enabled: !loading,
                      decoration: InputDecoration(
                        labelText: user == null ? 'Contraseña' : 'Nueva Contraseña (opcional)',
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                        DropdownMenuItem(value: 'manager', child: Text('Gerente')),
                        DropdownMenuItem(value: 'employee', child: Text('Empleado')),
                      ],
                      onChanged: loading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => selectedRole = value);
                              }
                            },
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final username = usernameController.text.trim();
                        final firstName = firstNameController.text.trim();
                        final lastName = lastNameController.text.trim();
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();

                        if (username.isEmpty || firstName.isEmpty || email.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Username, nombre y email son requeridos')),
                            );
                          }
                          return;
                        }

                        if (user == null && password.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('La contraseña es requerida para nuevos usuarios')),
                            );
                          }
                          return;
                        }

                        if (context.mounted) {
                          isLoading.value = true;
                        }

                        try {
                          bool success;
                          if (user == null) {
                            success = await ref.read(userProvider.notifier).createUser(
                              username: username,
                              firstName: firstName,
                              lastName: lastName,
                              email: email,
                              password: password,
                              role: selectedRole,
                            );
                          } else {
                            success = await ref.read(userProvider.notifier).updateUser(
                              id: user.id ?? '',
                              username: username,
                              firstName: firstName,
                              lastName: lastName,
                              email: email,
                              role: selectedRole,
                              password: password.isEmpty ? null : password,
                            );
                          }

                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } finally {
                          if (context.mounted) {
                            isLoading.value = false;
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(user == null ? 'Crear' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String userId,
    String userName,
  ) {
    final isLoading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: isLoading,
        builder: (ctx, loading, _) => AlertDialog(
          title: const Text('Eliminar Usuario'),
          content: Text('¿Está seguro de que desea eliminar al usuario "$userName"?'),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                if (context.mounted) {
                  isLoading.value = true;
                }

                try {
                  final success = await ref.read(userProvider.notifier).deleteUser(userId);

                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                  }
                } finally {
                  if (context.mounted) {
                    isLoading.value = false;
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignStoreDialog(
    BuildContext context,
    User user,
    StoreState storeState,
  ) {
    var selectedStoreId = '';
    final isLoading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (ctx, loading, _) => AlertDialog(
            title: const Text('Asignar Tienda'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asignar tienda a: ${user.fullName}'),
                  const SizedBox(height: AppSizes.spacing16),
                  if (storeState.stores.isEmpty)
                    const Text('No hay tiendas disponibles')
                  else
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Tienda',
                        border: OutlineInputBorder(),
                      ),
                      items: storeState.stores.map((store) {
                        return DropdownMenuItem<String>(
                          value: store['_id'],
                          child: Text(store['name'] ?? 'Sin nombre'),
                        );
                      }).toList(),
                      onChanged: loading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => selectedStoreId = value);
                              }
                            },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (selectedStoreId.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Debe seleccionar una tienda')),
                            );
                          }
                          return;
                        }

                        if (context.mounted) {
                          isLoading.value = true;
                        }

                        try {
                          final success = await ref.read(userProvider.notifier).assignStoreToUser(
                            user.id ?? '',
                            selectedStoreId,
                          );

                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } finally {
                          if (context.mounted) {
                            isLoading.value = false;
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Asignar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

