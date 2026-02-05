#!/bin/bash
# Script de compilación para Flutter Web - Producción
# Uso: ./build_web.sh

echo "🔨 Compilando Flutter Web para producción..."
echo ""

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Compilar para web
echo "🚀 Compilando aplicación web..."
flutter build web --release --dart-define=FLUTTER_APP_ENV=production

# Verificar si fue exitoso
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ¡Compilación exitosa!"
    echo ""
    echo "📁 Archivos compilados en: build/web/"
    echo ""
    echo "📝 Próximos pasos:"
    echo "  1. Copiar build/web a tu servidor"
    echo "  2. Configurar Nginx para servir estos archivos"
    echo "  3. Asegurar que API_URL apunta a tu dominio"
    echo ""
else
    echo ""
    echo "❌ La compilación falló. Revisa los errores arriba."
    exit 1
fi
