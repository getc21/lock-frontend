import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class SupplierFormState {
  final XFile? selectedImage;
  final String imageBytes;
  final String imagePreview;
  final bool isLoading;
  final bool isDeleting;
  
  final String name;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String address;
  
  // Para edición
  final String? supplierId;

  SupplierFormState({
    this.selectedImage,
    this.imageBytes = '',
    this.imagePreview = '',
    this.isLoading = false,
    this.isDeleting = false,
    this.name = '',
    this.contactName = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.address = '',
    this.supplierId,
  });

  SupplierFormState copyWith({
    XFile? selectedImage,
    String? imageBytes,
    String? imagePreview,
    bool? isLoading,
    bool? isDeleting,
    String? name,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? address,
    String? supplierId,
  }) {
    return SupplierFormState(
      selectedImage: selectedImage ?? this.selectedImage,
      imageBytes: imageBytes ?? this.imageBytes,
      imagePreview: imagePreview ?? this.imagePreview,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      supplierId: supplierId ?? this.supplierId,
    );
  }

  bool get isFormValid {
    return name.isNotEmpty && contactName.isNotEmpty;
  }

  bool get hasImage {
    return imagePreview.isNotEmpty;
  }

  bool get isCreating => supplierId == null;
}

class SupplierFormNotifier extends StateNotifier<SupplierFormState> {
  final Ref ref;
  late final ImagePicker _imagePicker;

  SupplierFormNotifier(
    this.ref, {
    Map<String, dynamic>? initialSupplier,
  }) : super(SupplierFormState(
    name: initialSupplier?['name'] ?? '',
    contactName: initialSupplier?['contactName'] ?? '',
    contactPhone: initialSupplier?['contactPhone'] ?? '',
    contactEmail: initialSupplier?['contactEmail'] ?? '',
    address: initialSupplier?['address'] ?? '',
    imagePreview: initialSupplier?['foto'] ?? '',
    supplierId: initialSupplier?['_id'],
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

  /// Actualizar nombre del proveedor
  void setName(String name) {
    state = state.copyWith(name: name);
  }

  /// Actualizar nombre de contacto
  void setContactName(String contactName) {
    state = state.copyWith(contactName: contactName);
  }

  /// Actualizar teléfono de contacto
  void setContactPhone(String phone) {
    state = state.copyWith(contactPhone: phone);
  }

  /// Actualizar email de contacto
  void setContactEmail(String email) {
    state = state.copyWith(contactEmail: email);
  }

  /// Actualizar dirección
  void setAddress(String address) {
    state = state.copyWith(address: address);
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

    state = SupplierFormState();
  }

  /// Limpiar el estado (para cuando se cierra el dialog)
  @override
  void dispose() {
    // Eliminar archivo temporal si existe
    state.selectedImage?.delete().ignore();
    super.dispose();
  }
}

final supplierFormProvider =
    StateNotifierProvider.family<SupplierFormNotifier, SupplierFormState, Map<String, dynamic>?>(
  (ref, initialSupplier) {
    return SupplierFormNotifier(ref, initialSupplier: initialSupplier);
  },
);
