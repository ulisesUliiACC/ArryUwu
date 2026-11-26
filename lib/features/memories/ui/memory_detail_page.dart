import 'dart:async';
import 'dart:typed_data';

import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/memories/data/memory.dart';
import 'package:arryuwu/features/memories/data/memory_service.dart';
import 'package:arryuwu/features/memories/ui/auth_image.dart';
import 'package:arryuwu/features/memories/ui/parallax_view.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Detalle de un recuerdo: la foto en 3D (si ya está lista) a pantalla casi completa.
class MemoryDetailPage extends StatefulWidget {
  final Memory memory;

  const MemoryDetailPage({super.key, required this.memory});

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  late Memory _memory = widget.memory;
  Future<(Uint8List, Uint8List)>? _images;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    if (_memory.depthReady) {
      _images = Future.wait([
        MemoryService.image(_memory.photoUrl),
        MemoryService.image(_memory.depthUrl!),
      ]).then((r) => (r[0], r[1]));
    } else {
      _images = null; // sin mapa listo se muestra la foto normal
      if (_memory.depthPending) {
        // Mientras se genera el 3D, pregunta cada 3 s.
        _poll ??= Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
      }
    }
  }

  Future<void> _regenerate() async {
    try {
      final updated = await MemoryService.regenerateDepth(_memory.id);
      if (!mounted) return;
      setState(() {
        _memory = updated;
        _setup();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _refresh() async {
    try {
      final updated = await MemoryService.get(_memory.id);
      if (!mounted) return;
      if (!updated.depthPending) {
        _poll?.cancel();
        _poll = null;
      }
      setState(() {
        _memory = updated;
        _setup();
      });
    } on ApiException {
      // se reintenta en el siguiente ciclo
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar este recuerdo?'),
        content: const Text('Se borrará para los dos y no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await MemoryService.delete(_memory.id);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        title: Text(formatFecha(_memory.memoryDate)),
        actions: [
          if (_memory.mine && !_memory.depthPending)
            IconButton(
              tooltip: 'Rehacer efecto 3D',
              icon: const Icon(Icons.auto_fix_high_outlined),
              onPressed: _regenerate,
            ),
          if (_memory.mine)
            IconButton(
              tooltip: 'Borrar recuerdo',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: 'memory-${_memory.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: _buildPhoto(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _StatusLine(memory: _memory),
              if (_memory.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_memory.description!, style: text.bodyLarge?.copyWith(color: AppColors.ink)),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                _memory.mine ? 'Lo subiste tú' : 'Lo subió @${_memory.ownerUserName}',
                style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (_images == null) return AuthImage(_memory.photoUrl);
    return FutureBuilder(
      future: _images,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final (photo, depth) = snapshot.data!;
          return ParallaxView(photo: photo, depth: depth);
        }
        return AuthImage(_memory.photoUrl);
      },
    );
  }
}

class _StatusLine extends StatelessWidget {
  final Memory memory;

  const _StatusLine({required this.memory});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted);
    if (memory.depthReady) {
      return Row(children: [
        const Icon(Icons.threed_rotation, size: 18, color: AppColors.lavenderDeep),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('Inclina el celular o arrastra el dedo para verlo en 3D', style: style)),
      ]);
    }
    if (memory.depthPending) {
      return Row(children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: AppSpacing.sm),
        Text('Creando la versión 3D…', style: style),
      ]);
    }
    return Text('No se pudo crear la versión 3D de esta foto.', style: style);
  }
}
