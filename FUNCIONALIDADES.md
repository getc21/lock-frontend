# Guía de Funcionalidades - BellezApp Web

## 🏠 Dashboard Principal

El dashboard muestra un resumen completo del negocio en tiempo real:

### KPI Cards (Indicadores Clave)
- **Ventas Hoy**: Muestra el total de ventas del día con porcentaje de cambio vs mes anterior
- **Órdenes**: Cantidad total de órdenes con indicador de crecimiento
- **Clientes**: Total de clientes registrados con porcentaje de incremento
- **Productos**: Inventario total de productos

Cada card incluye:
- Icono representativo con color temático
- Valor principal en grande
- Indicador de tendencia (↑ verde / ↓ rojo)
- Comparación con período anterior

### Gráfico de Ventas
- **Tipo**: Línea con área rellena
- **Período**: Últimos 7 días
- **Datos**: Ventas diarias en USD
- **Interactivo**: Hover para ver valores exactos
- **Colores**: Gradiente primary (indigo)

### Top Productos
Panel lateral con los 5 productos más vendidos:
- Imagen/ícono del producto
- Nombre del producto
- Cantidad de ventas
- Revenue total en USD
- Ordenados por mayor ingreso

### Órdenes Recientes
Tabla con las últimas 5 órdenes:
- ID de orden (clickeable)
- Cliente
- Cantidad de productos
- Total en USD
- Estado (Completado, Pendiente, Procesando)
- Fecha de creación
- Botón "Ver todas" para ir a página completa

## 📦 Gestión de Productos

### Características Principales
1. **Búsqueda en Tiempo Real**
   - Campo de búsqueda en header
   - Filtra mientras escribes
   - Busca en nombre y código de producto

2. **Tabla de Productos**
   - **Código**: ID único del producto (PROD-XXX)
   - **Producto**: Nombre con ícono
   - **Categoría**: Cuidado Capilar, Coloración, Tratamientos, etc.
   - **Stock**: Cantidad disponible con indicadores de color:
     - Verde: Stock normal (≥10 unidades)
     - Amarillo: Stock bajo (<10 unidades)
     - Rojo: Sin stock (0 unidades)
   - **Precio**: En formato USD con 2 decimales
   - **Estado**: Activo/Inactivo con chip de color
   - **Acciones**: Editar (✏️) y Eliminar (🗑️)

3. **Agregar Producto**
   - Botón "Nuevo Producto" en header
   - Abre modal con formulario (pendiente implementación)

### Ordenamiento
- Click en headers de columna para ordenar
- Orden ascendente/descendente
- Multi-columna

## 🧾 Gestión de Órdenes

### Filtros
Dropdown en header para filtrar por estado:
- Todos (sin filtro)
- Pendiente (amarillo)
- Procesando (azul)
- Completado (verde)
- Cancelado (rojo)

### Información de Órdenes
- **ID**: Identificador único (ORD-XXX) con color primary
- **Cliente**: Avatar + nombre
- **Productos**: Cantidad de items ("X items")
- **Subtotal**: Monto antes de descuentos
- **Descuento**: Monto descontado (en verde si hay descuento)
- **Total**: Monto final en negrita
- **Estado**: Chip de color según status
- **Fecha**: Formato DD/MM/YYYY

### Acciones
- **Ver detalles** (👁️): Abre modal con información completa
- **Imprimir** (🖨️): Genera ticket/factura (pendiente)

### Botón Nueva Orden
- Header superior derecha
- Abre wizard de creación de orden

## 👥 Gestión de Clientes

### Características de Cliente
1. **Avatar Personalizado**
   - Inicial del nombre en círculo
   - Color primary de fondo
   - Badge VIP (⭐) para clientes frecuentes (≥10 órdenes)

2. **Información Principal**
   - Nombre completo
   - Email
   - Teléfono
   - Badge "Cliente VIP" si aplica

3. **Métricas del Cliente**
   - **Órdenes**: Total de compras realizadas (chip azul)
   - **Total Gastado**: Suma de todas las órdenes en USD (bold primary)
   - **Última Compra**: Fecha de última orden

### Búsqueda Avanzada
- Busca por nombre o email
- Filtrado en tiempo real
- Case-insensitive

### Acciones
- Ver detalles completos
- Editar información
- Eliminar cliente

## 📊 Reportes y Analytics

### Selector de Período
Dropdown con opciones:
- Hoy
- Semana
- Mes Actual
- Mes Anterior
- Año

### Tarjetas de Métricas
4 cards con información clave:
1. **Ventas Totales**: Total en USD con % de cambio
2. **Total Órdenes**: Cantidad con tendencia
3. **Ticket Promedio**: Valor promedio por orden
4. **Nuevos Clientes**: Cantidad de altas en período

### Gráfico de Ventas Mensuales
- **Tipo**: Barras verticales
- **Período**: Últimos 6 meses
- **Eje Y**: Ventas en miles de USD
- **Eje X**: Nombre del mes
- **Color**: Primary (indigo)
- **Interactivo**: Hover para valor exacto

### Ventas por Categoría
- **Tipo**: Gráfico de torta (Pie Chart)
- **Datos**: Porcentaje por categoría de producto
- **Colores**: Primary, Info, Success, Warning
- **Leyenda**: Debajo del gráfico con nombre y color

### Top Vendedores
Ranking de empleados:
- Posición (1-5)
- Nombre del vendedor
- Total de ventas en USD
- Destacado dorado para top 3

### Exportar Datos
Botones en header:
- **Exportar PDF**: Descarga reporte completo
- **Exportar Excel**: Descarga datos en XLS

## 🎨 Sistema de Colores por Estado

### Estados de Órdenes
- **Completado**: Verde (#10B981)
- **Pendiente**: Amarillo (#F59E0B)
- **Procesando**: Azul (#3B82F6)
- **Cancelado**: Rojo (#EF4444)

### Estados de Stock
- **Normal**: Verde (≥10 unidades)
- **Bajo**: Amarillo (<10 unidades)
- **Agotado**: Rojo (0 unidades)

### Estados de Producto
- **Activo**: Verde
- **Inactivo**: Rojo

## 🔐 Sistema de Navegación

### Sidebar (Desktop)
- Logo BellezApp en header
- Menú de navegación con iconos:
  - 📊 Dashboard
  - 📦 Productos
  - 🧾 Órdenes
  - 👥 Clientes
  - 📈 Reportes
- Item activo con fondo primary claro
- Botón de colapsar sidebar (←/→)
- Perfil de usuario en footer
- Botón de logout

### TopBar
- Título de página actual
- Botón de notificaciones (🔔)
- Botón de configuración (⚙️)
- Avatar de usuario

### NavigationRail (Tablet/Mobile)
- Versión compacta de sidebar
- Solo iconos (sin texto)
- Mismo comportamiento de navegación

## 🎯 Mejores Prácticas Implementadas

1. **Responsive Design**: Adaptación automática a diferentes pantallas
2. **Loading States**: Indicadores de carga en operaciones asíncronas
3. **Error Handling**: Manejo de errores con mensajes claros
4. **Validación de Formularios**: Inputs con validación en tiempo real
5. **Feedback Visual**: Animaciones y transiciones suaves
6. **Accesibilidad**: Tooltips, labels y contraste adecuado
7. **Performance**: Lazy loading y optimización de renders

## 🚀 Atajos de Teclado (Futuro)

Planeados para implementar:
- `Ctrl+N`: Nueva orden
- `Ctrl+P`: Nuevo producto
- `Ctrl+K`: Búsqueda global
- `Ctrl+S`: Guardar cambios
- `Esc`: Cerrar modal

---

**Nota**: Las funcionalidades marcadas como "(pendiente)" están en la arquitectura pero requieren implementación de backend.
