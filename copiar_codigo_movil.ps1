# Script para copiar código de la app móvil a la web
# Ejecutar desde: bellezapp-frontend/

$sourcePath = "..\bellezapp\lib"
$destPath = ".\lib\shared"

Write-Host "🔄 Copiando código de app móvil a web dashboard..." -ForegroundColor Cyan
Write-Host ""

# Crear directorios si no existen
Write-Host "📁 Creando estructura de carpetas..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$destPath\models" | Out-Null
New-Item -ItemType Directory -Force -Path "$destPath\controllers" | Out-Null
New-Item -ItemType Directory -Force -Path "$destPath\database" | Out-Null
New-Item -ItemType Directory -Force -Path "$destPath\services" | Out-Null

# Copiar Modelos
Write-Host ""
Write-Host "📦 Copiando modelos..." -ForegroundColor Green
$models = @(
    "product.dart",
    "order.dart",
    "customer.dart",
    "discount.dart",
    "user.dart",
    "store.dart",
    "order_product.dart",
    "category.dart"
)

foreach ($model in $models) {
    $sourceFile = "$sourcePath\models\$model"
    if (Test-Path $sourceFile) {
        Copy-Item $sourceFile "$destPath\models\$model" -Force
        Write-Host "  ✅ $model copiado" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ $model no encontrado" -ForegroundColor Yellow
    }
}

# Copiar Controllers
Write-Host ""
Write-Host "🎮 Copiando controllers..." -ForegroundColor Green
$controllers = @(
    "product_controller.dart",
    "order_controller.dart",
    "customer_controller.dart",
    "discount_controller.dart",
    "user_controller.dart",
    "store_controller.dart"
)

foreach ($controller in $controllers) {
    $sourceFile = "$sourcePath\controllers\$controller"
    if (Test-Path $sourceFile) {
        Copy-Item $sourceFile "$destPath\controllers\$controller" -Force
        Write-Host "  ✅ $controller copiado" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ $controller no encontrado" -ForegroundColor Yellow
    }
}

# Copiar Database Helper
Write-Host ""
Write-Host "💾 Copiando database helper..." -ForegroundColor Green
$dbFile = "$sourcePath\database\database_helper.dart"
if (Test-Path $dbFile) {
    Copy-Item $dbFile "$destPath\database\database_helper.dart" -Force
    Write-Host "  ✅ database_helper.dart copiado" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ database_helper.dart no encontrado" -ForegroundColor Yellow
}

# Copiar Servicios (opcionales)
Write-Host ""
Write-Host "🛠️ Copiando servicios..." -ForegroundColor Green
$services = @(
    "pdf_service.dart",
    "excel_service.dart",
    "backup_service.dart"
)

foreach ($service in $services) {
    $sourceFile = "$sourcePath\services\$service"
    if (Test-Path $sourceFile) {
        Copy-Item $sourceFile "$destPath\services\$service" -Force
        Write-Host "  ✅ $service copiado" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ $service no encontrado (opcional)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "✨ ¡Copia completada!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Próximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Verificar imports en los archivos copiados"
Write-Host "  2. Agregar dependencias faltantes al pubspec.yaml si es necesario"
Write-Host "  3. Inicializar controllers en main.dart:"
Write-Host ""
Write-Host '     await DatabaseHelper.instance.database;' -ForegroundColor Gray
Write-Host '     Get.put(ProductController());' -ForegroundColor Gray
Write-Host '     Get.put(OrderController());' -ForegroundColor Gray
Write-Host '     Get.put(CustomerController());' -ForegroundColor Gray
Write-Host ""
Write-Host '  4. Reemplazar datos hardcoded por Obx(() => controller.data)'
Write-Host ""
Write-Host "Ver guía completa en: REUTILIZAR_CODIGO_MOVIL.md" -ForegroundColor Cyan
