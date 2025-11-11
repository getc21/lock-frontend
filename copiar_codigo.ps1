# Script para copiar codigo de la app movil a la web
# Ejecutar desde: bellezapp-frontend/

$sourcePath = "..\bellezapp\lib"
$destPath = ".\lib\shared"

Write-Host "Copiando codigo de app movil a web dashboard..." -ForegroundColor Cyan
Write-Host ""

# Crear directorios si no existen
Write-Host "Creando estructura de carpetas..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$destPath\models" | Out-Null
New-Item -ItemType Directory -Force -Path "$destPath\controllers" | Out-Null
New-Item -ItemType Directory -Force -Path "$destPath\database" | Out-Null
New-Item -ItemType Directory -Force -Path "$destPath\services" | Out-Null

# Copiar Modelos
Write-Host ""
Write-Host "Copiando modelos..." -ForegroundColor Green
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
        Write-Host "  OK $model copiado" -ForegroundColor Green
    } else {
        Write-Host "  AVISO $model no encontrado" -ForegroundColor Yellow
    }
}

# Copiar Controllers
Write-Host ""
Write-Host "Copiando controllers..." -ForegroundColor Green
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
        Write-Host "  OK $controller copiado" -ForegroundColor Green
    } else {
        Write-Host "  AVISO $controller no encontrado" -ForegroundColor Yellow
    }
}

# Copiar Database Helper
Write-Host ""
Write-Host "Copiando database helper..." -ForegroundColor Green
$dbFile = "$sourcePath\database\database_helper.dart"
if (Test-Path $dbFile) {
    Copy-Item $dbFile "$destPath\database\database_helper.dart" -Force
    Write-Host "  OK database_helper.dart copiado" -ForegroundColor Green
} else {
    Write-Host "  AVISO database_helper.dart no encontrado" -ForegroundColor Yellow
}

# Copiar Servicios
Write-Host ""
Write-Host "Copiando servicios..." -ForegroundColor Green
$services = @(
    "pdf_service.dart",
    "excel_service.dart",
    "backup_service.dart"
)

foreach ($service in $services) {
    $sourceFile = "$sourcePath\services\$service"
    if (Test-Path $sourceFile) {
        Copy-Item $sourceFile "$destPath\services\$service" -Force
        Write-Host "  OK $service copiado" -ForegroundColor Green
    } else {
        Write-Host "  AVISO $service no encontrado (opcional)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Copia completada!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Verificar imports en los archivos copiados"
Write-Host "  2. Inicializar controllers en main.dart"
Write-Host "  3. Reemplazar datos hardcoded por controllers"
Write-Host ""
Write-Host "Ver guia completa en: REUTILIZAR_CODIGO_MOVIL.md" -ForegroundColor Cyan
