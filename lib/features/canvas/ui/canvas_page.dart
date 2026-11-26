import 'dart:async';

import 'package:arryuwu/features/canvas/data/canvas_controller.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lienzo de la pareja: dibujar con colores de la marca y pegar notas tipo post-it.
class CanvasPage extends ConsumerStatefulWidget {
  const CanvasPage({super.key});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  final _active = _ActiveStroke();
  int _colorIndex = 1;
  int _widthIndex = 1;
  Size _canvasSize = Size.zero;
  String? _activeId;

  Color get _color => canvasInkColors[_colorIndex];

  /// Unidad de las coordenadas compartidas: el ancho del lienzo en esta pantalla.
  double get _unit => _canvasSize.width <= 0 ? 1 : _canvasSize.width;

  @override
  void dispose() {
    _active.dispose();
    super.dispose();
  }

  // --- Dibujo ---

  void _onPanStart(DragStartDetails d) {
    final id = CanvasController.newId();
    _activeId = id;
    _active.start(d.localPosition, _color, canvasWidths[_widthIndex]);
    ref.read(canvasProvider.notifier).startStroke(id, d.localPosition / _unit, _color, canvasWidths[_widthIndex] / _unit);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final id = _activeId;
    if (id == null || !_active.add(d.localPosition)) return;
    ref.read(canvasProvider.notifier).extendStroke(id, d.localPosition / _unit);
  }

  void _onPanEnd([Object? _]) {
    final id = _activeId;
    final points = _active.finish();
    _activeId = null;
    if (id == null || points == null) return;
    ref.read(canvasProvider.notifier).finishStroke(Stroke(
          id: id,
          points: [for (final p in points) p / _unit],
          color: _active.color,
          width: _active.width / _unit,
          by: ref.read(canvasProvider).me,
        ));
  }

  // --- Notas ---

  Future<void> _addNote() async {
    final result = await _showNoteSheet(context);
    if (result == null || result.text.isEmpty) return;
    final count = ref.read(canvasProvider).notes.length;
    final start = Offset(
      (_canvasSize.width / 2 - 72).clamp(0.0, double.infinity) + (count % 4) * AppSpacing.lg,
      (_canvasSize.height / 4).clamp(0.0, double.infinity) + (count % 4) * AppSpacing.lg,
    );
    ref.read(canvasProvider.notifier).upsertNote(StickyNote(
          id: CanvasController.newId(),
          text: result.text,
          position: start / _unit,
          color: result.color,
        ));
    HapticFeedback.lightImpact();
  }

  Future<void> _editNote(StickyNote note) async {
    final result = await _showNoteSheet(context, note: note);
    if (result == null) return;
    final notifier = ref.read(canvasProvider.notifier);
    if (result.delete || result.text.isEmpty) {
      notifier.removeNote(note.id);
    } else {
      notifier.upsertNote(note.copyWith(text: result.text, color: result.color));
    }
  }

  void _moveNote(StickyNote note, Offset delta) {
    final p = note.position * _unit + delta;
    final maxX = (_canvasSize.width - 48).clamp(0.0, double.infinity);
    final maxY = (_canvasSize.height - 48).clamp(0.0, double.infinity);
    final clamped = Offset(p.dx.clamp(0.0, maxX), p.dy.clamp(0.0, maxY));
    ref.read(canvasProvider.notifier).moveNoteLocal(note.copyWith(position: clamped / _unit));
  }

  // --- Acciones ---

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('¿Borrar todo el lienzo?'),
        content: const Text('Se borrarán los dibujos y las notas. Esto no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(canvasProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lienzo'),
        actions: const [Padding(padding: EdgeInsets.only(right: AppSpacing.md), child: _SyncBadge())],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Entrance(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: AppSpacing.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _canvasSize = constraints.biggest;
                    return Stack(
                      children: [
                        // Trazos guardados + trazo en curso, en capas separadas.
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            onPanCancel: _onPanEnd,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const RepaintBoundary(child: _StrokesLayer()),
                                RepaintBoundary(child: CustomPaint(painter: _ActiveStrokePainter(_active))),
                              ],
                            ),
                          ),
                        ),
                        _EmptyHint(active: _active),
                        _NotesLayer(
                          unit: _unit,
                          onMove: _moveNote,
                          onMoveEnd: (n) => ref.read(canvasProvider.notifier).commitNote(n.id),
                          onTap: _editNote,
                        ),
                        Positioned(
                          left: AppSpacing.sm,
                          right: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: _Toolbar(
                                colorIndex: _colorIndex,
                                widthIndex: _widthIndex,
                                onColor: (i) => setState(() => _colorIndex = i),
                                onWidth: (i) => setState(() => _widthIndex = i),
                                onUndo: () => ref.read(canvasProvider.notifier).undo(),
                                onAddNote: _addNote,
                                onClear: _confirmClear,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dibujo
// ---------------------------------------------------------------------------

/// Trazo que se está dibujando. Avisa a su pintor sin reconstruir widgets.
class _ActiveStroke extends ChangeNotifier {
  final List<Offset> points = [];
  Color color = AppColors.lavenderDeep;
  double width = 7;

  void start(Offset p, Color c, double w) {
    points
      ..clear()
      ..add(p);
    color = c;
    width = w;
    notifyListeners();
  }

  /// Devuelve false si el movimiento fue mínimo y se ignoró (menos puntos, mismo dibujo).
  bool add(Offset p) {
    if (points.isEmpty) return false;
    if ((p - points.last).distanceSquared < 1.5) return false;
    points.add(p);
    notifyListeners();
    return true;
  }

  /// Puntos del trazo terminado (en píxeles de esta pantalla), o null si no había trazo.
  List<Offset>? finish() {
    if (points.isEmpty) return null;
    final done = List<Offset>.of(points);
    points.clear();
    notifyListeners();
    return done;
  }
}

void _paintStroke(Canvas canvas, List<Offset> points, Color color, double width) {
  if (points.isEmpty) return;
  if (points.length == 1) {
    canvas.drawCircle(points.first, width / 2, Paint()..color = color);
    return;
  }
  final paint = Paint()
    ..color = color
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  // Curvas suaves entre los puntos medios.
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final cur = points[i];
    path.quadraticBezierTo(prev.dx, prev.dy, (prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
  }
  path.lineTo(points.last.dx, points.last.dy);
  canvas.drawPath(path, paint);
}

class _StrokesLayer extends ConsumerWidget {
  const _StrokesLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strokes = ref.watch(canvasProvider.select((s) => s.strokes));
    return CustomPaint(painter: _StrokesPainter(strokes));
  }
}

/// Trazos terminados. La lista es inmutable y se reemplaza en cada cambio,
/// así que basta comparar identidad para saber si repintar.
class _StrokesPainter extends CustomPainter {
  final List<Stroke> strokes;

  _StrokesPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    // Las coordenadas guardadas son relativas al ancho: se escalan a esta pantalla.
    final u = size.width;
    for (final s in strokes) {
      _paintStroke(canvas, [for (final p in s.points) p * u], s.color, s.width * u);
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter oldDelegate) => !identical(oldDelegate.strokes, strokes);
}

/// Solo el trazo en curso; repinta al ritmo del dedo vía [repaint].
class _ActiveStrokePainter extends CustomPainter {
  final _ActiveStroke active;

  _ActiveStrokePainter(this.active) : super(repaint: active);

  @override
  void paint(Canvas canvas, Size size) => _paintStroke(canvas, active.points, active.color, active.width);

  @override
  bool shouldRepaint(_ActiveStrokePainter oldDelegate) => !identical(oldDelegate.active, active);
}

class _EmptyHint extends ConsumerWidget {
  final _ActiveStroke active;

  const _EmptyHint({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empty = ref.watch(canvasProvider.select((s) => s.isEmpty));
    final text = Theme.of(context).textTheme;
    return Positioned.fill(
      bottom: 140,
      child: IgnorePointer(
        child: ListenableBuilder(
          listenable: active,
          builder: (_, __) => AnimatedOpacity(
            opacity: empty && active.points.isEmpty ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.brush_rounded, size: 48, color: AppColors.lavender),
                    const SizedBox(height: AppSpacing.md),
                    Text('Un lienzo para los dos', style: text.titleMedium, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Dibuja algo bonito o pega una nota para tu pareja.',
                      style: text.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notas
// ---------------------------------------------------------------------------

class _NotesLayer extends ConsumerWidget {
  final double unit;
  final void Function(StickyNote note, Offset delta) onMove;
  final ValueChanged<StickyNote> onMoveEnd;
  final ValueChanged<StickyNote> onTap;

  const _NotesLayer({required this.unit, required this.onMove, required this.onMoveEnd, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(canvasProvider.select((s) => s.notes));
    return Stack(
      children: [
        for (final note in notes)
          AnimatedPositioned(
            key: ValueKey(note.id),
            // Las notas que mueve la pareja se deslizan suave hasta su nuevo lugar.
            duration: const Duration(milliseconds: 120),
            left: note.position.dx * unit,
            top: note.position.dy * unit,
            child: _NoteCard(
              note: note,
              onPan: (d) => onMove(note, d.delta),
              onPanEnd: () => onMoveEnd(note),
              onTap: () => onTap(note),
            ),
          ),
      ],
    );
  }
}

/// Estado de la sincronización en la barra: en vivo con tu pareja, conectando o sin conexión.
class _SyncBadge extends ConsumerStatefulWidget {
  const _SyncBadge();

  @override
  ConsumerState<_SyncBadge> createState() => _SyncBadgeState();
}

class _SyncBadgeState extends ConsumerState<_SyncBadge> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // "Está dibujando…" depende del tiempo: se revisa cada medio segundo.
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(canvasProvider);
    final (IconData icon, Color color, String label) = switch (s.status) {
      SyncStatus.connecting => (Icons.sync_rounded, AppColors.inkMuted, 'Conectando…'),
      SyncStatus.offline => (Icons.cloud_off_rounded, AppColors.error, 'Sin conexión'),
      SyncStatus.live when s.partnerIsDrawing => (Icons.brush_rounded, AppColors.pinkDeep, '@${s.partnerOnline ?? 'tu pareja'} dibuja…'),
      SyncStatus.live when s.partnerOnline != null => (Icons.circle, AppColors.success, '@${s.partnerOnline} está aquí'),
      SyncStatus.live => (Icons.cloud_done_rounded, AppColors.lavenderDeep, 'Guardado'),
    };
    return Semantics(
      liveRegion: true,
      label: label,
      child: GestureDetector(
        onTap: s.status == SyncStatus.offline ? ref.read(canvasProvider.notifier).retryNow : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(label),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StickyNote note;
  final GestureDragUpdateCallback onPan;
  final VoidCallback onPanEnd;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onPan, required this.onPanEnd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Una leve inclinación distinta por nota (estable en los dos celulares), como post-its pegados a mano.
    final tilt = ((note.id.codeUnits.fold<int>(0, (a, b) => a + b) % 5) - 2) * 0.025;
    return Semantics(
      button: true,
      label: 'Nota: ${note.text}',
      hint: 'Toca para editar, arrastra para mover',
      child: GestureDetector(
        onPanUpdate: onPan,
        onPanEnd: (_) => onPanEnd(),
        onTap: onTap,
        child: Pressable(
          pressedScale: 1.04,
          child: Transform.rotate(
            angle: tilt,
            child: Container(
              constraints: const BoxConstraints(minWidth: 96, maxWidth: 168, minHeight: 72),
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              decoration: BoxDecoration(
                color: note.color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                boxShadow: AppSpacing.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.push_pin_rounded, size: 14, color: AppColors.lavenderDeep),
                  ),
                  Text(
                    note.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteResult {
  final String text;
  final Color color;
  final bool delete;

  const _NoteResult(this.text, this.color, {this.delete = false});
}

Future<_NoteResult?> _showNoteSheet(BuildContext context, {StickyNote? note}) {
  return showModalBottomSheet<_NoteResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (_) => _NoteSheet(note: note),
  );
}

class _NoteSheet extends StatefulWidget {
  final StickyNote? note;

  const _NoteSheet({this.note});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _controller = TextEditingController(text: widget.note?.text ?? '');
  late Color _color = widget.note?.color ?? noteColors.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_NoteResult(_controller.text.trim(), _color));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final editing = widget.note != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(editing ? 'Editar nota' : 'Nueva nota', style: text.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: !editing,
            minLines: 2,
            maxLines: 4,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Escribe algo para tu pareja'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Color', style: text.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < noteColors.length; i++)
                _Swatch(
                  color: noteColors[i],
                  selected: noteColors[i] == _color,
                  label: 'Color de nota ${i + 1}',
                  onTap: () => setState(() => _color = noteColors[i]),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, __) => AppPrimaryButton(
              label: editing ? 'Guardar nota' : 'Pegar nota',
              icon: Icons.push_pin_rounded,
              onPressed: value.text.trim().isEmpty ? null : _save,
            ),
          ),
          if (editing) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.error, minimumSize: const Size(0, 48)),
                onPressed: () => Navigator.of(context).pop(_NoteResult('', _color, delete: true)),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Quitar nota'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barra de herramientas
// ---------------------------------------------------------------------------

class _Toolbar extends ConsumerWidget {
  final int colorIndex;
  final int widthIndex;
  final ValueChanged<int> onColor;
  final ValueChanged<int> onWidth;
  final VoidCallback onUndo;
  final VoidCallback onAddNote;
  final VoidCallback onClear;

  const _Toolbar({
    required this.colorIndex,
    required this.widthIndex,
    required this.onColor,
    required this.onWidth,
    required this.onUndo,
    required this.onAddNote,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo se pueden deshacer los trazos propios, no los de la pareja.
    final canUndo = ref.watch(canvasProvider.select((s) => s.strokes.any((t) => t.by == null || t.by == s.me)));
    final isEmpty = ref.watch(canvasProvider.select((s) => s.isEmpty));
    final color = canvasInkColors[colorIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.lavenderSoft),
        boxShadow: AppSpacing.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < canvasInkColors.length; i++)
                Expanded(
                  child: _Swatch(
                    color: canvasInkColors[i],
                    selected: i == colorIndex,
                    label: 'Color ${canvasInkNames[i]}',
                    onTap: () => onColor(i),
                  ),
                ),
            ],
          ),
          const Divider(height: AppSpacing.xs, color: AppColors.lavenderSoft),
          Row(
            children: [
              for (var i = 0; i < canvasWidths.length; i++)
                _WidthButton(
                  width: canvasWidths[i],
                  color: color,
                  selected: i == widthIndex,
                  label: 'Grosor ${canvasWidthNames[i]}',
                  onTap: () => onWidth(i),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Deshacer',
                color: AppColors.ink,
                icon: const Icon(Icons.undo_rounded),
                onPressed: canUndo ? onUndo : null,
              ),
              IconButton(
                tooltip: 'Agregar nota',
                color: AppColors.lavenderDeep,
                icon: const Icon(Icons.sticky_note_2_rounded),
                onPressed: onAddNote,
              ),
              IconButton(
                tooltip: 'Borrar todo',
                color: AppColors.error,
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: isEmpty ? null : onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Círculo de color con anillo cuando está elegido. Área táctil de 48.
class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _Swatch({required this.color, required this.selected, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Pressable(
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: selected ? 34 : 26,
                height: selected ? 34 : 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.lavenderDeep : AppColors.lavenderSoft,
                    width: selected ? 3 : 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de grosor: un punto del tamaño del trazo, en el color actual.
class _WidthButton extends StatelessWidget {
  final double width;
  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _WidthButton({
    required this.width,
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Pressable(
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.lavenderSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: Container(
                width: width + 4,
                height: width + 4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
