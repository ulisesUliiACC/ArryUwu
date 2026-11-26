import 'dart:typed_data';

import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/capsules/data/capsule.dart';
import 'package:arryuwu/features/capsules/ui/drawing_pad.dart';
import 'package:arryuwu/features/memories/data/memory.dart';
import 'package:arryuwu/features/places/ui/place_picker_page.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Nueva cápsula: un dibujo o una foto, un mensaje y el lugar donde quedará escondida.
/// Devuelve true con Navigator.pop si se guardó.
class CreateCapsulePage extends StatefulWidget {
  const CreateCapsulePage({super.key});

  @override
  State<CreateCapsulePage> createState() => _CreateCapsulePageState();
}

enum _Mode { draw, photo }

class _CreateCapsulePageState extends State<CreateCapsulePage> {
  final _pad = DrawingPadController();
  final _message = TextEditingController();
  _Mode _mode = _Mode.draw;
  Uint8List? _photo;
  String _photoName = 'capsula.jpg';
  MemoryPlace? _place;
  bool _saving = false;

  static const _colors = [
    AppColors.pinkDeep,
    AppColors.lavenderDeep,
    AppColors.ink,
    Color(0xFFE65100),
    Color(0xFF00796B),
  ];

  @override
  void dispose() {
    _pad.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      maxHeight: 1400,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photo = bytes;
      _photoName = file.name;
    });
  }

  Future<void> _pickPlace() async {
    final picked = await Navigator.push<MemoryPlace>(
      context,
      MaterialPageRoute(builder: (_) => PlacePickerPage(initial: _place)),
    );
    if (picked != null) setState(() => _place = picked);
  }

  bool get _hasContent => _mode == _Mode.draw ? !_pad.isEmpty : _photo != null;

  Future<void> _save() async {
    if (_place?.point == null) {
      showAppSnack(context, 'Marca en el mapa dónde quedará la cápsula.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final image = _mode == _Mode.draw ? await _pad.exportPng() : _photo!;
      await CapsuleService.create(
        image: image,
        filename: _mode == _Mode.draw ? 'dibujo.png' : _photoName,
        point: _place!.point!,
        message: _message.text,
        placeName: _place!.name,
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva cápsula')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Deja algo escondido en un lugar. Tu pareja solo podrá verlo cuando llegue ahí. 💌',
                style: text.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(value: _Mode.draw, icon: Icon(Icons.brush_rounded), label: Text('Dibujo')),
                ButtonSegment(value: _Mode.photo, icon: Icon(Icons.photo_rounded), label: Text('Foto')),
              ],
              selected: {_mode},
              onSelectionChanged: _saving ? null : (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Contenido
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: AppSpacing.softShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: _mode == _Mode.draw
                    ? ListenableBuilder(
                        listenable: _pad,
                        builder: (_, __) => Stack(children: [
                          DrawingPad(controller: _pad),
                          if (_pad.isEmpty)
                            IgnorePointer(
                              child: Center(child: Text('Dibuja aquí ✏️', style: text.bodyMedium)),
                            ),
                        ]),
                      )
                    : InkWell(
                        onTap: _saving ? null : _pickPhoto,
                        child: _photo == null
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.add_photo_alternate_outlined, size: 56, color: AppColors.lavenderDeep),
                                const SizedBox(height: AppSpacing.sm),
                                Text('Elige una foto', style: text.titleMedium),
                              ])
                            : Image.memory(_photo!, fit: BoxFit.cover),
                      ),
              ),
            ),
            if (_mode == _Mode.draw) ...[
              const SizedBox(height: AppSpacing.md),
              ListenableBuilder(
                listenable: _pad,
                builder: (_, __) => Row(children: [
                  for (final c in _colors)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Semantics(
                        button: true,
                        selected: _pad.color == c,
                        label: 'Color',
                        child: GestureDetector(
                          onTap: () => _pad.setColor(c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _pad.color == c ? AppColors.lavenderSoft : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(tooltip: 'Deshacer', onPressed: _pad.undo, icon: const Icon(Icons.undo_rounded)),
                  IconButton(tooltip: 'Borrar dibujo', onPressed: _pad.clear, icon: const Icon(Icons.delete_outline)),
                ]),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _message,
              enabled: !_saving,
              maxLength: 280,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                prefixIcon: Icon(Icons.favorite_border_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            ListTile(
              onTap: _saving ? null : _pickPlace,
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              leading: const Icon(Icons.place_outlined, color: AppColors.pinkDeep),
              title: const Text('¿Dónde la escondes?'),
              subtitle: Text(_place?.point == null ? 'Toca para marcar el lugar' : _place!.label),
              trailing: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: AppSpacing.xl),

            ListenableBuilder(
              listenable: _pad,
              builder: (_, __) => AppPrimaryButton(
                label: 'Esconder cápsula',
                icon: Icons.card_giftcard_rounded,
                loading: _saving,
                onPressed: _hasContent && _place?.point != null ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
