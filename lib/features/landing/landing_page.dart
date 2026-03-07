import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as html;
import '../../core/constants/app_colors.dart';

/// Página principal de SynergyApp que describe todas las funcionalidades
/// y características de la plataforma.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _heroAnimController;
  late final AnimationController _pulseController;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  bool _showTopBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _heroFade = CurvedAnimation(
      parent: _heroAnimController,
      curve: Curves.easeOut,
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroAnimController,
      curve: Curves.easeOutCubic,
    ));

    _heroAnimController.forward();
  }

  void _onScroll() {
    final show = _scrollController.offset > 80;
    if (show != _showTopBar) setState(() => _showTopBar = show);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 640 && size.width < 1024;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ─── NAV BAR ───
              SliverToBoxAdapter(child: _buildNavBar(context, isDesktop)),
              // ─── HERO ───
              SliverToBoxAdapter(
                  child: _buildHeroSection(context, isDesktop, isTablet)),
              // ─── STATS BAR ───
              SliverToBoxAdapter(child: _buildStatsBar(context, isDesktop)),
              // ─── FEATURES GRID ───
              SliverToBoxAdapter(
                  child: _buildFeaturesSection(context, isDesktop, isTablet)),
              // ─── MÓDULOS DESTACADOS ───
              SliverToBoxAdapter(
                  child:
                      _buildHighlightModules(context, isDesktop, isTablet)),
              // ─── CTA ───
              SliverToBoxAdapter(
                  child: _buildCtaSection(context, isDesktop)),
              // ─── FOOTER ───
              SliverToBoxAdapter(child: _buildFooter(context, isDesktop)),
            ],
          ),
          // Floating top bar on scroll
          if (_showTopBar) _buildFloatingBar(context),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NAV BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildNavBar(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 20,
      ),
      child: Row(
        children: [
          // Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'SynergyApp',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // CTA
          FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Iniciar Sesión'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showTopBar ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('SynergyApp',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.gray900)),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Iniciar Sesión',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeroSection(
      BuildContext context, bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 48 : 24),
        vertical: isDesktop ? 80 : 48,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.03),
            AppColors.secondary.withValues(alpha: 0.04),
            AppColors.white,
          ],
        ),
      ),
      child: SlideTransition(
        position: _heroSlide,
        child: FadeTransition(
          opacity: _heroFade,
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: _heroText(context, isDesktop)),
                    const SizedBox(width: 64),
                    Expanded(flex: 4, child: _heroVisual()),
                  ],
                )
              : Column(
                  children: [
                    _heroText(context, isDesktop),
                    const SizedBox(height: 40),
                    _heroVisual(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _heroText(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Sistema Integral de Gestión',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Todo lo que necesitas\npara gestionar tu negocio',
          style: TextStyle(
            fontSize: isDesktop ? 48 : 32,
            fontWeight: FontWeight.w900,
            color: AppColors.gray900,
            height: 1.1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'SynergyApp te da el control total de tu negocio: punto de venta, '
          'inventario, finanzas, sucursales y equipo de trabajo — '
          'todo integrado en una sola plataforma.',
          style: TextStyle(
            fontSize: isDesktop ? 18 : 16,
            color: AppColors.gray500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text('Comenzar Ahora'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                _scrollController.animateTo(
                  600,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                );
              },
              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              label: const Text('Ver Funcionalidades'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gray700,
                side: const BorderSide(color: AppColors.gray300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroVisual() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 0.95 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: pulse,
          child: child,
        );
      },
      child: Container(
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard_rounded,
                      size: 56, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Dashboard Inteligente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Métricas en tiempo real, reportes\ny control total de tu negocio',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Mini stat cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _miniStatCard(Icons.trending_up, '\$12.4K', 'Ventas'),
                      const SizedBox(width: 12),
                      _miniStatCard(Icons.shopping_bag, '234', 'Órdenes'),
                      const SizedBox(width: 12),
                      _miniStatCard(Icons.people, '89', 'Clientes'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATS BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsBar(BuildContext context, bool isDesktop) {
    final stats = [
      _StatItem(icon: Icons.inventory_2_rounded, value: '+18', label: 'Módulos'),
      _StatItem(
          icon: Icons.store_rounded, value: 'Multi', label: 'Tienda'),
      _StatItem(
          icon: Icons.devices_rounded, value: 'Web & Móvil', label: 'Plataformas'),
      _StatItem(
          icon: Icons.security_rounded, value: 'JWT', label: 'Seguridad'),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 24),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48 : 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats.map((s) => _statWidget(s)).toList(),
            )
          : Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 24,
              runSpacing: 20,
              children: stats.map((s) => _statWidget(s)).toList(),
            ),
    );
  }

  Widget _statWidget(_StatItem stat) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(stat.icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat.value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.gray900)),
            Text(stat.label,
                style: const TextStyle(
                    color: AppColors.gray500, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FEATURES GRID
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFeaturesSection(
      BuildContext context, bool isDesktop, bool isTablet) {
    final features = [
      _Feature(
        icon: Icons.point_of_sale_rounded,
        title: 'Punto de Venta (POS)',
        description:
            'Crea y gestiona órdenes de venta de manera rápida e intuitiva. '
            'Soporte para múltiples métodos de pago, descuentos y notas.',
        color: AppColors.primary,
      ),
      _Feature(
        icon: Icons.inventory_rounded,
        title: 'Gestión de Productos',
        description:
            'Catálogo completo con imágenes, variantes, precios, stock '
            'y organización por categorías. Carga masiva y búsqueda avanzada.',
        color: AppColors.success,
      ),
      _Feature(
        icon: Icons.analytics_rounded,
        title: 'Reportes y Analíticas',
        description:
            'Dashboard con métricas en tiempo real. Reportes de ventas, '
            'productos más vendidos, ingresos por período y exportación de datos.',
        color: AppColors.info,
      ),
      _Feature(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Control de Gastos',
        description:
            'Registra y categoriza gastos del negocio. Reportes detallados '
            'de egresos, filtros por fecha y categoría, y comparativas mensuales.',
        color: AppColors.warning,
      ),
      _Feature(
        icon: Icons.receipt_long_rounded,
        title: 'Cotizaciones',
        description:
            'Genera cotizaciones profesionales para tus clientes. '
            'Conversión directa a orden de venta con un clic.',
        color: AppColors.secondary,
      ),
      _Feature(
        icon: Icons.assignment_return_rounded,
        title: 'Devoluciones',
        description:
            'Gestión completa de devoluciones vinculadas a órdenes. '
            'Registro de motivos, reembolsos y ajuste automático de inventario.',
        color: AppColors.error,
      ),
      _Feature(
        icon: Icons.point_of_sale,
        title: 'Caja Registradora',
        description:
            'Apertura y cierre de caja con montos iniciales y finales. '
            'Movimientos de entrada/salida y cuadre automático diario.',
        color: const Color(0xFF8B5CF6),
      ),
      _Feature(
        icon: Icons.receipt_rounded,
        title: 'Comprobantes',
        description:
            'Generación automática de recibos y comprobantes de venta. '
            'Formato personalizable con los datos de tu marca.',
        color: const Color(0xFF14B8A6),
      ),
      _Feature(
        icon: Icons.people_alt_rounded,
        title: 'Clientes',
        description:
            'Base de datos de clientes con historial de compras, '
            'datos de contacto, notas y segmentación para campañas.',
        color: const Color(0xFFF97316),
      ),
      _Feature(
        icon: Icons.local_shipping_rounded,
        title: 'Proveedores',
        description:
            'Directorio de proveedores con información de contacto, '
            'productos asociados y seguimiento de abastecimiento.',
        color: const Color(0xFF06B6D4),
      ),
      _Feature(
        icon: Icons.category_rounded,
        title: 'Categorías',
        description:
            'Organización jerárquica de productos por categorías '
            'con iconos, descripciones y filtros inteligentes.',
        color: const Color(0xFFD946EF),
      ),
      _Feature(
        icon: Icons.location_on_rounded,
        title: 'Ubicaciones',
        description:
            'Gestión de ubicaciones de almacén y estantes. '
            'Control de inventario por zona y optimización de espacios.',
        color: const Color(0xFF84CC16),
      ),
    ];

    final crossCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 48 : 24),
        vertical: 72,
      ),
      child: Column(
        children: [
          _sectionHeader(
            badge: 'Funcionalidades',
            title: '12 módulos integrados\npara tu operación diaria',
            subtitle:
                'Cada módulo está diseñado para optimizar un aspecto clave '
                'de tu negocio, desde la venta hasta las finanzas.',
          ),
          const SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              mainAxisExtent: 210,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemBuilder: (context, i) => _featureCard(features[i]),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(_Feature f) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: f.color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(f.icon, color: f.color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            f.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              f.description,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HIGHLIGHT MODULES
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHighlightModules(
      BuildContext context, bool isDesktop, bool isTablet) {
    final modules = [
      _HighlightModule(
        icon: Icons.groups_rounded,
        title: 'Gestión de Usuarios y Roles',
        description:
            'Controla quién puede hacer qué en tu negocio. '
            'Asigna roles diferenciados a tu equipo para '
            'garantizar seguridad y eficiencia operativa.',
        features: [
          'Administrador: control completo del negocio',
          'Manager: supervisión de tienda y equipo',
          'Cajero: operaciones de venta rápidas',
          'Permisos específicos por cada rol',
        ],
        gradient: [AppColors.primary, const Color(0xFF8B5CF6)],
      ),
      _HighlightModule(
        icon: Icons.store_mall_directory_rounded,
        title: 'Multi-Sucursal',
        description:
            'Gestiona todas tus sucursales desde una sola cuenta. '
            'Cada tienda tiene su propio inventario, equipo y reportes '
            'independientes.',
        features: [
          'Sucursales con inventario separado',
          'Usuarios asignados por tienda',
          'Reportes individuales por sucursal',
          'Cambio rápido entre tiendas',
        ],
        gradient: [AppColors.success, const Color(0xFF06B6D4)],
      ),
      _HighlightModule(
        icon: Icons.palette_rounded,
        title: 'Tu Marca, Tu Identidad',
        description:
            'La plataforma se adapta a tu negocio: sube tu logo, '
            'personaliza la experiencia y haz que tus empleados '
            'trabajen con la imagen de tu marca.',
        features: [
          'Logo propio en toda la interfaz',
          'Identidad visual personalizada',
          'Tema claro/oscuro según preferencia',
          'Comprobantes con tu branding',
        ],
        gradient: [AppColors.secondary, const Color(0xFFF97316)],
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 48 : 24),
        vertical: 72,
      ),
      color: AppColors.gray50,
      child: Column(
        children: [
          _sectionHeader(
            badge: 'Potencia',
            title: 'Diseñado para escalar\ncon tu negocio',
            subtitle:
                'Desde un emprendimiento hasta una red de sucursales, '
                'SynergyApp crece contigo.',
          ),
          const SizedBox(height: 48),
          ...modules.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final isReversed = i.isOdd;
            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _highlightCard(m, isDesktop, isReversed),
            );
          }),
        ],
      ),
    );
  }

  Widget _highlightCard(
      _HighlightModule m, bool isDesktop, bool isReversed) {
    final visual = Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: m.gradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Transform.rotate(
              angle: math.pi / 6,
              child: Icon(m.icon,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Center(
            child: Icon(m.icon, size: 64, color: Colors.white),
          ),
        ],
      ),
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(m.title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: AppColors.gray900)),
        const SizedBox(height: 12),
        Text(m.description,
            style: const TextStyle(
                color: AppColors.gray500, fontSize: 15, height: 1.6)),
        const SizedBox(height: 20),
        ...m.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: m.gradient.first, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f,
                        style: const TextStyle(
                            color: AppColors.gray700,
                            fontSize: 14,
                            height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    );

    if (!isDesktop) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          children: [visual, const SizedBox(height: 24), text],
        ),
      );
    }

    final children = isReversed
        ? [Expanded(flex: 5, child: text), const SizedBox(width: 40), Expanded(flex: 4, child: visual)]
        : [Expanded(flex: 4, child: visual), const SizedBox(width: 40), Expanded(flex: 5, child: text)];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(children: children),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CTA SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCtaSection(BuildContext context, bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : 24, vertical: 40),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 32,
        vertical: isDesktop ? 56 : 40,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF8B5CF6), AppColors.secondary],
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.rocket_launch_rounded,
              size: 48, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            '¿Listo para llevar tu\nnegocio al siguiente nivel?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 36 : 26,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Contáctanos por WhatsApp y te ayudamos a comenzar '
            'con la solución perfecta para tu negocio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: isDesktop ? 17 : 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  html.window.open(
                    'https://wa.me/59177446390?text=Hola%2C%20me%20interesa%20SynergyApp%20para%20mi%20negocio',
                    '_blank',
                  );
                },
                icon: const Icon(Icons.chat_rounded, size: 20),
                label: const Text('Contactar por WhatsApp'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  textStyle:
                      const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login_rounded, size: 20),
                label: const Text('Iniciar Sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  textStyle:
                      const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFooter(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 40,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: isDesktop
          ? Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hub_rounded,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text('SynergyApp',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray700)),
                  ],
                ),
                const Spacer(),
                Text(
                  '© 2026 SynergyApp. Todos los derechos reservados.',
                  style: TextStyle(
                      color: AppColors.gray400, fontSize: 13),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hub_rounded,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text('SynergyApp',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray700)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '© 2026 SynergyApp. Todos los derechos reservados.',
                  style: TextStyle(
                      color: AppColors.gray400, fontSize: 13),
                ),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionHeader({
    required String badge,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(badge,
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.gray900,
            height: 1.15,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gray500,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem(
      {required this.icon, required this.value, required this.label});
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _Feature(
      {required this.icon,
      required this.title,
      required this.description,
      required this.color});
}

class _HighlightModule {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final List<Color> gradient;
  const _HighlightModule({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.gradient,
  });
}
