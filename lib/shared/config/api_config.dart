import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // IP de tu computadora en la red local (para desarrollo)
  static const String _localIP = '192.168.0.48';
  
  // Puerto del backend (desarrollo local)
  static const String _port = '3000';
  
  // URL de producción - CAMBIAR SEGÚN TU DOMINIO
  static const String _productionUrl = 'https://naturalmarket.onrender.com/api';
  
  // Detecta automáticamente si estamos en emulador, web o dispositivo físico
  static String get baseUrl {
    // Para Web, usar localhost para desarrollo
    if (kIsWeb) {
      // DESARROLLO LOCAL
      return 'http://localhost:$_port/api';
      // Producción (comentado)
      // return _productionUrl;
      // Si necesitas acceder desde otra computadora en la red:
      // return 'http://$_localIP:$_port/api';
    }
    
    // Para dispositivos móviles (en desarrollo usa IP local, en producción usa URL remota)
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
