import 'dart:async';

import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/memories/data/memory.dart';
import 'package:arryuwu/features/memories/data/memory_service.dart';
import 'package:arryuwu/features/memories/ui/add_memory_page.dart';
import 'package:arryuwu/features/memories/ui/auth_image.dart';
import 'package:arryuwu/features/memories/ui/memory_detail_page.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Línea del tiempo de recuerdos de la pareja (los míos y los de mi pareja vinculada).
class MemoriesPage extends StatefulWidget {
  const MemoriesPage({super.key});

  @override
  State<MemoriesPage> createState() => _MemoriesPageState();
}

class _MemoriesPageState extends State<MemoriesPage> {
  List<Memory>? _memories;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final memories = await MemoryService.list();
      if (!mounted) return;
      setState(() {
        _memories = memories;
        _error = null;
      });
      // Si alguno sigue generando su 3D, vuelve a preguntar en unos segundos.
      _poll?.cancel();
      if (memories.any((m) => m.depthPending)) {
        _poll = Timer(const Duration(seconds: 4), _load);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMemoryPage()),
    );
    if (saved == true) {
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Recuerdo guardado. Estamos creando su versión 3D ✨'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _open(Memory memory) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MemoryDetailPage(memory: memory)),
    );
    _load(); // el estado del 3D o la lista pudieron cambiar
    if (deleted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recuerdo borrado'), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        title: const Text('Nuestros recuerdos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.lavenderDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Agregar recuerdo'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final text = Theme.of(context).textTheme;

    if (_error != null && _memories == null) {
      return _CenteredMessage(
        title: 'No pudimos cargar sus recuerdos',
        subtitle: _error!,
        action: FilledButton(onPressed: _load, child: const Text('Reintentar')),
      );
    }
    if (_memories == null) {
      return Center(child: Lottie.asset('assets/lottie/loading_animation.json', width: 160));
    }
    if (_memories!.isEmpty) {
      return _CenteredMessage(
        lottie: 'assets/lottie/heart.json',
        title: 'Aún no tienen recuerdos',
        subtitle: 'Agreguen la foto de una cita y véanla cobrar vida en 3D.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.72,
        ),
        itemCount: _memories!.length,
        itemBuilder: (context, i) {
          final m = _memories![i];
          return Semantics(
            button: true,
            label: 'Recuerdo del ${formatFecha(m.memoryDate)}',
            child: GestureDetector(
              onTap: () => _open(m),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: AppSpacing.softShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(tag: 'memory-${m.id}', child: AuthImage(m.photoUrl)),
                          Positioned(top: AppSpacing.sm, right: AppSpacing.sm, child: _DepthChip(m)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatFecha(m.memoryDate),
                              style: text.labelSmall?.copyWith(color: AppColors.lavenderDeep)),
                          if (m.description != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(m.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodyMedium?.copyWith(color: AppColors.ink)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DepthChip extends StatelessWidget {
  final Memory memory;

  const _DepthChip(this.memory);

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (memory.depthStatus) {
      'READY' => ('3D', Icons.threed_rotation),
      'PENDING' => ('Creando 3D', Icons.hourglass_top),
      _ => ('Sin 3D', Icons.image_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final String? lottie;
  final String title;
  final String subtitle;
  final Widget? action;

  const _CenteredMessage({this.lottie, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottie != null) Lottie.asset(lottie!, width: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: AppColors.inkMuted)),
            if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}
