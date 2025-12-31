import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // IP de tu computadora en la red local
  static const String _localIP = '192.168.0.48';
  
  // Puerto del backend
  static const String _port = '3000';
  
  // Detecta automáticamente si estamos en emulador, web o dispositivo físico
  static String get baseUrl {
    // Para Web, usar URL local para desarrollo
    if (kIsWeb) {
      // Desarrollo local
      return 'http://localhost:$_port/api';
      // Producción (descomentar para usar)
      // return 'https://naturalmarket.onrender.com/api';
      // Si necesitas acceder desde otra computadora en la red:
      // return 'http://$_localIP:$_port/api';
    }
    
    // Para dispositivos móviles (código original conservado)
    return 'http://$_localIP:$_port/api';
  }
  
  // Método para cambiar manualmente la configuración (útil para debugging)
  static String getUrlForMode({required bool useLocalhost}) {
    if (useLocalhost) {
      return 'http://localhost:$_port/api';
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
