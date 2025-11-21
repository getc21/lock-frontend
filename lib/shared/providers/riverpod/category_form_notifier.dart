import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CategoryFormState {
  final XFile? selectedImage;
  final String imageBytes;
  final String imagePreview;
  final bool isLoading;
  final bool isDeleting;

  final String name;
  final String description;

  // Para edición
  final String? categoryId;

  CategoryFormState({
    this.selectedImage,
    this.imageBytes = '',
    this.imagePreview = '',
    this.isLoading = false,
    this.isDeleting = false,
    this.name = '',
    this.description = '',
    this.categoryId,
  });

  CategoryFormState copyWith({
    XFile? selectedImage,
    String? imageBytes,
    String? imagePreview,
    bool? isLoading,
    bool? isDeleting,
    String? name,
    String? description,
    String? categoryId,
  }) {
    return CategoryFormState(
      selectedImage: selectedImage ?? this.selectedImage,
      imageBytes: imageBytes ?? this.imageBytes,
      imagePreview: imagePreview ?? this.imagePreview,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  bool get isFormValid {
    return name.isNotEmpty;
  }

  bool get hasImage {
    return imagePreview.isNotEmpty;
  }

  bool get isCreating => categoryId == null;
}

class CategoryFormNotifier extends StateNotifier<CategoryFormState> {
  final Ref ref;
  late final ImagePicker _imagePicker;

  CategoryFormNotifier(
    this.ref, {
    Map<String, dynamic>? initialCategory,
  }) : super(CategoryFormState(
    name: initialCategory?['name'] ?? '',
    description: initialCategory?['description'] ?? '',
    imagePreview: initialCategory?['foto'] ?? initialCategory?['image'] ?? '',
    categoryId: initialCategory?['_id'],
  )) {
    _imagePicker = ImagePicker();
  }

  /// Seleccionar imagen de galería
  Future<void> selectImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        state = state.copyWith(
          selectedImage: image,
          imageBytes: base64String,
          imagePreview: base64String,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Limpiar imagen seleccionada
  void clearImage() {
    // Si hay imagen local, eliminar el archivo temporal
    state.selectedImage?.delete().ignore();

    state = state.copyWith(
      selectedImage: null,
      imageBytes: '',
      imagePreview: '',
    );
  }

  /// Actualizar nombre de categoría
  void setName(String name) {
    state = state.copyWith(name: name);
  }

  /// Actualizar descripción
  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  /// Establecer estado de carga
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Establecer estado de eliminación
  void setDeleting(bool deleting) {
    state = state.copyWith(isDeleting: deleting);
  }

  /// Resetear el formulario
  void reset() {
    // Limpiar imagen
    state.selectedImage?.delete().ignore();

    state = CategoryFormState();
  }

  /// Limpiar el estado (para cuando se cierra el dialog)
  @override
  void dispose() {
    // Eliminar archivo temporal si existe
    state.selectedImage?.delete().ignore();
    super.dispose();
  }
}

final categoryFormProvider =
    StateNotifierProvider.family<CategoryFormNotifier, CategoryFormState, Map<String, dynamic>?>(
  (ref, initialCategory) {
    return CategoryFormNotifier(ref, initialCategory: initialCategory);
  },
);
