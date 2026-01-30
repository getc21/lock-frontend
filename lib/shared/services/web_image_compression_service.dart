import 'dart:convert';
import 'dart:async';
import 'package:web/web.dart';
import 'dart:js_interop';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Servicio para comprimir imágenes en Flutter Web
/// Utiliza la API Canvas del navegador para redimensionar y comprimir imágenes
class WebImageCompressionService {
  /// Calidad de compresión (0-1)
  /// 0.85 = buena calidad con reducción de ~40-50% del tamaño
  /// 0.75 = calidad media con reducción de ~50-60% del tamaño
  static const double defaultQuality = 0.85;

  /// Ancho máximo de la imagen (mantiene aspecto)
  static const int maxWidth = 1200;

  /// Alto máximo de la imagen (mantiene aspecto)
  static const int maxHeight = 1200;

  /// Comprime una imagen desde XFile (seleccionada por ImagePicker)
  /// Retorna el base64 de la imagen comprimida y un blob para upload
  /// [imageFile] - archivo de imagen original (XFile)
  /// [quality] - calidad de compresión (0-1, default 0.85)
  /// [maxWidth] - ancho máximo (default 1200)
  /// [maxHeight] - alto máximo (default 1200)
  static Future<Map<String, dynamic>> compressImage({
    required XFile imageFile,
    double quality = defaultQuality,
    int width = maxWidth,
    int height = maxHeight,
  }) async {
    try {
      if (kDebugMode) {
        print('🖼️ [WEB COMPRESS] Iniciando compresión de imagen...');
        print('   - Archivo original: ${imageFile.name}');
      }

      // Leer bytes de la imagen
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final int originalSize = imageBytes.length;

      if (kDebugMode) {
        print('   - Tamaño original: ${_formatBytes(originalSize)}');
      }

      // Crear blob y URL para cargar la imagen en canvas
      final blob = Blob([imageBytes.toJS].toJS);
      final String imageUrl = URL.createObjectURL(blob);

      // Crear elemento de imagen para obtener dimensiones
      final img = HTMLImageElement();
      img.src = imageUrl;

      // Esperar a que la imagen se cargue
      await _waitForImageLoad(img);

      // Calcular nuevas dimensiones manteniendo aspecto
      final newSize = _calculateDimensions(
        img.width,
        img.height,
        width,
        height,
      );

      // Crear canvas y redimensionar imagen
      final canvas = HTMLCanvasElement();
      canvas.width = newSize['width'] as int;
      canvas.height = newSize['height'] as int;

      final ctx = canvas.getContext('2d') as CanvasRenderingContext2D?;
      
      if (ctx == null) {
        throw Exception('Failed to get canvas context');
      }
      
      // Dibujar imagen escalada en el canvas
      ctx.drawImage(img, 0, 0);

      // Convertir canvas a blob comprimido
      final compressedBlob = await _canvasToBlob(canvas, quality);
      final int compressedSize = compressedBlob.size.toInt();

      // Crear URL para el blob comprimido
      final String compressedUrl = URL.createObjectURL(compressedBlob);

      // Convertir a base64
      final String base64String = await _blobToBase64(compressedBlob);

      // Limpiar URLs
      URL.revokeObjectURL(imageUrl);

      final double reduction =
          double.parse(((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1));

      if (kDebugMode) {
        print('✅ [WEB COMPRESS] Imagen comprimida exitosamente');
        print('   - Dimensiones: ${newSize['width']} x ${newSize['height']}');
        print('   - Tamaño comprimido: ${_formatBytes(compressedSize)}');
        print('   - Reducción: $reduction%');
      }

      return {
        'base64': 'data:image/jpeg;base64,$base64String',
        'blob': compressedBlob,
        'url': compressedUrl,
        'originalSize': originalSize,
        'compressedSize': compressedSize,
        'reduction': reduction,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WEB COMPRESS] Error comprimiendo imagen: $e');
      }
      // Si hay error, retornar la imagen original en base64
      return {
        'base64': 'data:image/jpeg;base64,${base64Encode(await imageFile.readAsBytes())}',
        'blob': Blob([(await imageFile.readAsBytes()).toJS].toJS),
        'url': null,
        'originalSize': (await imageFile.readAsBytes()).length,
        'compressedSize': (await imageFile.readAsBytes()).length,
        'reduction': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Calcula las nuevas dimensiones manteniendo el aspecto
  static Map<String, int> _calculateDimensions(
    int originalWidth,
    int originalHeight,
    int maxW,
    int maxH,
  ) {
    double width = originalWidth.toDouble();
    double height = originalHeight.toDouble();

    // Si la imagen es más pequeña que los máximos, no redimensionar
    if (width <= maxW && height <= maxH) {
      return {'width': width.toInt(), 'height': height.toInt()};
    }

    // Calcular razón de aspecto
    final double aspectRatio = width / height;

    // Redimensionar según el eje más restrictivo
    if (width / maxW > height / maxH) {
      // Ancho es el factor limitante
      width = maxW.toDouble();
      height = width / aspectRatio;
    } else {
      // Alto es el factor limitante
      height = maxH.toDouble();
      width = height * aspectRatio;
    }

    return {'width': width.toInt(), 'height': height.toInt()};
  }

  /// Convierte un Blob a base64
  static Future<String> _blobToBase64(Blob blob) async {
    final completer = Completer<String>();
    final reader = FileReader();
    
    reader.addEventListener('load', ((JSObject event) {
      try {
        final List<int> bytes = List<int>.from(
          (reader.result as JSUint8Array).toDart,
        );
        completer.complete(base64Encode(bytes));
      } catch (e) {
        completer.completeError(e);
      }
    }).toJS as EventListener);
    
    reader.addEventListener('error', ((JSObject event) {
      completer.completeError('Failed to read blob');
    }).toJS as EventListener);
    
    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  /// Convierte un canvas a blob de forma asincrónica
  static Future<Blob> _canvasToBlob(HTMLCanvasElement canvas, double quality) {
    final completer = Completer<Blob>();
    
    canvas.toBlob(
      ((JSObject? blob) {
        if (blob != null) {
          completer.complete(blob as Blob);
        } else {
          completer.completeError('Failed to convert canvas to blob');
        }
      }).toJS,
      'image/jpeg',
      quality.toJS,
    );
    
    return completer.future;
  }

  /// Espera a que una imagen HTML se cargue
  static Future<void> _waitForImageLoad(HTMLImageElement img) {
    final completer = Completer<void>();
    late EventListener onLoadListener;
    late EventListener onErrorListener;
    
    onLoadListener = (((JSObject event) {
      img.removeEventListener('load', onLoadListener);
      img.removeEventListener('error', onErrorListener);
      completer.complete();
    }).toJS as EventListener);
    
    onErrorListener = (((JSObject event) {
      img.removeEventListener('load', onLoadListener);
      img.removeEventListener('error', onErrorListener);
      completer.completeError('Failed to load image');
    }).toJS as EventListener);
    
    img.addEventListener('load', onLoadListener);
    img.addEventListener('error', onErrorListener);
    
    return completer.future;
  }

  /// Formatea bytes a formato legible
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
