import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // IP de tu computadora en la red local (para desarrollo)
  static const String _localIP = '192.168.0.48';
  
  // Puerto del backend (desarrollo local)
  static const String _port = '3000';
  
  // Detecta automáticamente si estamos en emulador, web o dispositivo físico
  static String get baseUrl {
    // Para Web, usar URL de producción
    if (kIsWeb) {
      return 'https://api.naturalmarkets.net';
    }
    
    // Para dispositivos móviles (en desarrollo usa IP local, en producción usa URL remota)
    return 'http://$_localIP:$_port/api';
  }
  
  // Método para cambiar manualmente la configuración (útil para debugging)
  static String getUrlForMode({required bool useProduction}) {
    if (useProduction) {
      return 'https://api.naturalmarkets.net';
    } else {
      return 'http://$_localIP:$_port/api';
    }
  }
  
  // Información de debug
  static Map<String, dynamic> getDebugInfo() {
    return <String, dynamic>{
      'isWeb': kIsWeb,
      'baseUrl': baseUrl,
      'localIP': _localIP,
      'port': _port,
    };
  }
}
