import 'dart:typed_data';

import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/memories/data/memory_service.dart';
import 'package:arryuwu/features/places/ui/place_picker_page.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Nuevo recuerdo: foto de la galería, fecha y una frase. Devuelve true si se guardó.
class AddMemoryPage extends StatefulWidget {
  const AddMemoryPage({super.key});

  @override
  State<AddMemoryPage> createState() => _AddMemoryPageState();
}

class _AddMemoryPageState extends State<AddMemoryPage> {
  final _descriptionController = TextEditingController();
  Uint8List? _photo;
  String _filename = 'recuerdo.jpg';
  DateTime _date = DateTime.now();
  MemoryPlace? _place;
  bool _saving = false;

  Future<void> _pickPlace() async {
    final picked = await Navigator.push<MemoryPlace>(
      context,
      MaterialPageRoute(builder: (_) => PlacePickerPage(initial: _place)),
    );
    if (picked != null) setState(() => _place = picked);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    // Se reduce en el celular: menos datos que subir y el 3D se genera más rápido.
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photo = bytes;
      _filename = file.name;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha del recuerdo',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_photo == null) return;
    setState(() => _saving = true);
    try {
      await MemoryService.create(
        photo: _photo!,
        filename: _filename,
        date: _date,
        description: _descriptionController.text,
        place: _place,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        title: const Text('Nuevo recuerdo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Foto
            Semantics(
              button: true,
              label: _photo == null ? 'Elegir foto' : 'Cambiar foto',
              child: InkWell(
                onTap: _saving ? null : _pickPhoto,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.lavenderSoft, width: 2),
                      boxShadow: AppSpacing.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _photo == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined,
                                  size: 56, color: AppColors.lavenderDeep),
                              const SizedBox(height: AppSpacing.md),
                              Text('Elige una foto de su cita',
                                  style: text.titleMedium?.copyWith(color: AppColors.ink)),
                              const SizedBox(height: AppSpacing.xs),
                              Text('La convertiremos en 3D ✨',
                                  style: text.bodyMedium?.copyWith(color: AppColors.inkMuted)),
                            ],
                          )
                        : Image.memory(_photo!, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Fecha
            ListTile(
              onTap: _saving ? null : _pickDate,
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              leading: const Icon(Icons.calendar_month_outlined, color: AppColors.lavenderDeep),
              title: const Text('Fecha'),
              subtitle: Text(formatFecha(_date)),
              trailing: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: AppSpacing.md),

            // Lugar
            ListTile(
              onTap: _saving ? null : _pickPlace,
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              leading: const Icon(Icons.place_outlined, color: AppColors.pinkDeep),
              title: const Text('Lugar'),
              subtitle: Text(_place == null ? 'Agregar dónde fue (opcional)' : _place!.label),
              trailing: _place == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      tooltip: 'Quitar lugar',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _saving ? null : () => setState(() => _place = null),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Descripción
            TextField(
              controller: _descriptionController,
              enabled: !_saving,
              maxLength: 500,
              maxLines: 4,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: '¿Qué pasó ese día? (opcional)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  borderSide: const BorderSide(color: AppColors.lavenderDeep, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Guardar
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _photo == null || _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lavenderDeep,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar recuerdo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
