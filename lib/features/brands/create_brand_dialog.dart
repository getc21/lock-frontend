import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/providers/riverpod/brand_notifier.dart';
import '../../shared/services/web_image_compression_service.dart';
import '../../core/utils/responsive.dart';

class CreateBrandDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingBrand;

  const CreateBrandDialog({super.key, this.existingBrand});

  @override
  ConsumerState<CreateBrandDialog> createState() => _CreateBrandDialogState();
}

class _CreateBrandDialogState extends ConsumerState<CreateBrandDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Brand fields
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _maxStoresCtrl;

  // Logo image
  List<XFile>? _selectedImage;
  String? _imageBytes; // base64 data URI para web
  String? _imagePreview; // URL para mostrar preview (base64 o URL existente)

  // Admin fields (solo para crear)
  final _adminFirstNameCtrl = TextEditingController();
  final _adminLastNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();
  bool _showPassword = false;

  bool get isEditing => widget.existingBrand != null;

  @override
  void initState() {
    super.initState();
    final brand = widget.existingBrand;

    _nameCtrl = TextEditingController(text: brand?['name'] ?? '');
    _slugCtrl = TextEditingController(text: brand?['slug'] ?? '');
    _emailCtrl = TextEditingController(text: brand?['contactEmail'] ?? '');
    _phoneCtrl = TextEditingController(text: brand?['phone'] ?? '');
    _addressCtrl = TextEditingController(text: brand?['address'] ?? '');
    _maxStoresCtrl = TextEditingController(text: (brand?['maxStores'] ?? 3).toString());

    // Si la marca existente tiene logo, mostrarlo como preview
    final existingLogo = brand?['logo'] as String?;
    if (existingLogo != null && existingLogo.isNotEmpty) {
      _imagePreview = existingLogo;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _maxStoresCtrl.dispose();
    _adminFirstNameCtrl.dispose();
    _adminLastNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  void _autoGenerateSlug(String name) {
    if (!isEditing) {
      final slug = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-')
          .trim();
      _slugCtrl.text = slug;
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        // Comprimir para web
        final compressed = await WebImageCompressionService.compressImage(
          imageFile: image,
        );
        setState(() {
          _selectedImage = [image];
          _imageBytes = compressed['base64'];
          _imagePreview = _imageBytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _imagePreview = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (isEditing) {
        final brandId = widget.existingBrand!['_id'] ?? widget.existingBrand!['id'];
        await ref.read(brandProvider.notifier).updateBrand(brandId, {
          'name': _nameCtrl.text.trim(),
          'contactEmail': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'maxStores': int.tryParse(_maxStoresCtrl.text.trim()) ?? 3,
        },
          imageFile: _selectedImage?.isNotEmpty == true ? _selectedImage![0] : null,
          imageBytes: _imageBytes,
        );
      } else {
        final brandData = <String, dynamic>{
          'name': _nameCtrl.text.trim(),
          'slug': _slugCtrl.text.trim(),
          'contactEmail': _emailCtrl.text.trim(),
          'maxStores': int.tryParse(_maxStoresCtrl.text.trim()) ?? 3,
        };
        if (_phoneCtrl.text.trim().isNotEmpty) {
          brandData['phone'] = _phoneCtrl.text.trim();
        }
        if (_addressCtrl.text.trim().isNotEmpty) {
          brandData['address'] = _addressCtrl.text.trim();
        }

        await ref.read(brandProvider.notifier).createBrand(
          brandData: brandData,
          adminData: {
            'username': _adminEmailCtrl.text.trim().split('@').first,
            'firstName': _adminFirstNameCtrl.text.trim(),
            'lastName': _adminLastNameCtrl.text.trim(),
            'email': _adminEmailCtrl.text.trim(),
            'password': _adminPasswordCtrl.text,
          },
          imageFile: _selectedImage?.isNotEmpty == true ? _selectedImage![0] : null,
          imageBytes: _imageBytes,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // El notifier ya maneja el error en el state
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Dialog(
      child: Container(
        width: r.dialogWidth(preferred: 700),
        constraints: BoxConstraints(maxHeight: r.dialogMaxHeight(preferred: 700)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_business,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Editar Marca' : 'Nueva Marca',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand Info Section
                      Text(
                        'Información de la Marca',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la marca *',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Requerido'
                            : null,
                        onChanged: _autoGenerateSlug,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email de contacto *',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Requerido';
                                if (!v.contains('@')) return 'Email inválido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Dirección',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maxStoresCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Límite sucursales *',
                                prefixIcon: Icon(Icons.store_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Requerido';
                                final n = int.tryParse(v.trim());
                                if (n == null || n < 1) return 'Mín. 1';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Logo — Image Picker
                      Text(
                        'Logo (opcional)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Preview / Selector
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: _imagePreview != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.network(
                                        _imagePreview!,
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            size: 32, color: Colors.grey[500]),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Subir logo',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Actions
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.upload, size: 18),
                                label: Text(_imagePreview != null ? 'Cambiar' : 'Seleccionar'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                              if (_imagePreview != null) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      // Admin Section (solo para crear)
                      if (!isEditing) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Administrador de la Marca',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Se creará un usuario administrador con acceso a esta marca',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _adminFirstNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre *',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => !isEditing && (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _adminLastNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Apellido *',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => !isEditing && (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _adminEmailCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Email del admin *',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (!isEditing) {
                                    if (v == null || v.trim().isEmpty) return 'Requerido';
                                    if (!v.contains('@')) return 'Email inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _adminPasswordCtrl,
                                obscureText: !_showPassword,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña *',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () =>
                                        setState(() => _showPassword = !_showPassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (!isEditing) {
                                    if (v == null || v.isEmpty) return 'Requerido';
                                    if (v.length < 6) return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isEditing ? Icons.save : Icons.add),
                    label: Text(isEditing ? 'Guardar' : 'Crear Marca'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
