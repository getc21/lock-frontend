class User {
  final String? id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String passwordHash;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;
  final String? phone;
  final Map<String, dynamic>? permissions;
  final List<Map<String, dynamic>>? stores;
  final String? brandId;
  final Map<String, dynamic>? brand;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.profileImageUrl,
    this.phone,
    this.permissions,
    this.stores,
    this.brandId,
    this.brand,
  });

  // Getters de conveniencia
  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
  bool get isSuperAdmin => role == UserRole.superadmin;
  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isCashier => role == UserRole.cashier;
  // Alias para compatibilidad
  bool get isEmployee => isCashier;

  // Conversión a Map para la base de datos
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) '_id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'passwordHash': passwordHash,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'permissions': permissions,
      'stores': stores,
      'brandId': brandId,
      'brand': brand,
    };
  }

  // Crear desde Map de la base de datos
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id']?.toString() ?? map['id']?.toString(),
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? map['first_name'] ?? '',
      lastName: map['lastName'] ?? map['last_name'] ?? '',
      passwordHash: map['passwordHash'] ?? map['password_hash'] ?? '',
      role: UserRole.values.firstWhere(
        (UserRole role) => role.name == map['role'],
        orElse: () => UserRole.cashier,
      ),
      isActive: map['isActive'] ?? map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? map['created_at'] ?? '') ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] ?? map['last_login_at']) != null 
          ? DateTime.tryParse(map['lastLoginAt'] ?? map['last_login_at'])
          : null,
      profileImageUrl: map['profileImageUrl'] ?? map['profile_image_url'],
      phone: map['phone'],
      permissions: map['permissions'] is String 
          ? _jsonToMap(map['permissions'])
          : map['permissions'],
      stores: map['stores'] != null 
          ? List<Map<String, dynamic>>.from(map['stores'] as List)
          : null,
      brandId: map['brandId']?.toString(),
      brand: map['brand'] is Map<String, dynamic> ? map['brand'] : null,
    );
  }

  // Métodos para verificar permisos
  bool hasPermission(String permission) {
    if (isSuperAdmin || isAdmin) return true; // SuperAdmin y Admin tienen todos los permisos
    if (permissions == null) return false;
    return permissions![permission] == true;
  }

  bool canManageUsers() => hasPermission('manage_users') || isAdmin;
  bool canManageProducts() => hasPermission('manage_products') || isAdmin || isManager;
  bool canManageOrders() => hasPermission('manage_orders') || isAdmin || isManager;
  bool canManageCustomers() => hasPermission('manage_customers') || isAdmin || isManager;
  bool canManageDiscounts() => hasPermission('manage_discounts') || isAdmin || isManager;
  bool canViewReports() => hasPermission('view_reports') || isAdmin || isManager;
  bool canManageInventory() => hasPermission('manage_inventory') || isAdmin || isManager;
  bool canManageCash() => hasPermission('manage_cash') || isAdmin || isManager;

  // Copiar con cambios
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? passwordHash,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? profileImageUrl,
    String? phone,
    Map<String, dynamic>? permissions,
    List<Map<String, dynamic>>? stores,
    String? brandId,
    Map<String, dynamic>? brand,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      permissions: permissions ?? this.permissions,
      stores: stores ?? this.stores,
      brandId: brandId ?? this.brandId,
      brand: brand ?? this.brand,
    );
  }

  static Map<String, dynamic> _jsonToMap(String json) {
    // Simple implementación, en producción usar dart:convert
    // Por ahora devolvemos mapa vacío
    return <String, dynamic>{};
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, fullName: $fullName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum UserRole {
  superadmin('Super Administrador'),
  admin('Administrador'),
  manager('Gerente'),
  cashier('Cajero');

  const UserRole(this.displayName);
  final String displayName;

  // Permisos por defecto según el rol
  Map<String, bool> get defaultPermissions {
    switch (this) {
      case UserRole.superadmin:
        return <String, bool>{
          'manage_users': true,
          'manage_products': true,
          'manage_orders': true,
          'manage_customers': true,
          'manage_discounts': true,
          'view_reports': true,
          'manage_inventory': true,
          'manage_cash': true,
          'manage_settings': true,
          'manage_brands': true,
        };
      case UserRole.admin:
        return <String, bool>{
          'manage_users': true,
          'manage_products': true,
          'manage_orders': true,
          'manage_customers': true,
          'manage_discounts': true,
          'view_reports': true,
          'manage_inventory': true,
          'manage_cash': true,
          'manage_settings': true,
        };
      case UserRole.manager:
        return <String, bool>{
          'manage_users': false,
          'manage_products': true,
          'manage_orders': true,
          'manage_customers': true,
          'manage_discounts': true,
          'view_reports': true,
          'manage_inventory': true,
          'manage_cash': true,
          'manage_settings': false,
        };
      case UserRole.cashier:
        return <String, bool>{
          'manage_users': false,
          'manage_products': false,
          'manage_orders': true,
          'manage_customers': true,
          'manage_discounts': false,
          'view_reports': false,
          'manage_inventory': false,
          'manage_cash': false,
          'manage_settings': false,
        };
    }
  }

  String get description {
    switch (this) {
      case UserRole.superadmin:
        return 'Acceso completo a la plataforma';
      case UserRole.admin:
        return 'Acceso completo al sistema';
      case UserRole.manager:
        return 'Gestión de operaciones y reportes';
      case UserRole.cashier:
        return 'Operaciones básicas de venta';
    }
  }
}
