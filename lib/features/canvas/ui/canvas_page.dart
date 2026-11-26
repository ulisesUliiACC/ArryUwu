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

  Color get _color => canvasInkColors[_colorIndex];

  @override
  void dispose() {
    _active.dispose();
    super.dispose();
  }

  // --- Dibujo ---

  void _onPanStart(DragStartDetails d) => _active.start(d.localPosition, _color, canvasWidths[_widthIndex]);

  void _onPanUpdate(DragUpdateDetails d) => _active.add(d.localPosition);

  void _onPanEnd([Object? _]) {
    final stroke = _active.finish();
    if (stroke != null) ref.read(canvasProvider.notifier).addStroke(stroke);
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
    ref.read(canvasProvider.notifier).addNote(result.text, result.color, start);
    HapticFeedback.lightImpact();
  }

  Future<void> _editNote(StickyNote note) async {
    final result = await _showNoteSheet(context, note: note);
    if (result == null) return;
    final notifier = ref.read(canvasProvider.notifier);
    if (result.delete || result.text.isEmpty) {
      notifier.removeNote(note.id);
    } else {
      notifier.updateNote(note.id, text: result.text, color: result.color);
    }
  }

  void _moveNote(StickyNote note, Offset delta) {
    final p = note.position + delta;
    final maxX = (_canvasSize.width - 48).clamp(0.0, double.infinity);
    final maxY = (_canvasSize.height - 48).clamp(0.0, double.infinity);
    ref
        .read(canvasProvider.notifier)
        .updateNote(note.id, position: Offset(p.dx.clamp(0.0, maxX), p.dy.clamp(0.0, maxY)));
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
      appBar: AppBar(title: const Text('Lienzo')),
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
                        _NotesLayer(onMove: _moveNote, onTap: _editNote),
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

  void add(Offset p) {
    if (points.isEmpty) return;
    // Ignora movimientos mínimos: menos puntos, mismo dibujo.
    if ((p - points.last).distanceSquared < 1.5) return;
    points.add(p);
    notifyListeners();
  }

  Stroke? finish() {
    if (points.isEmpty) return null;
    final stroke = Stroke(points: points, color: color, width: width);
    points.clear();
    notifyListeners();
    return stroke;
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
    for (final s in strokes) {
      _paintStroke(canvas, s.points, s.color, s.width);
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
  final void Function(StickyNote note, Offset delta) onMove;
  final ValueChanged<StickyNote> onTap;

  const _NotesLayer({required this.onMove, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(canvasProvider.select((s) => s.notes));
    return Stack(
      children: [
        for (final note in notes)
          Positioned(
            key: ValueKey(note.id),
            left: note.position.dx,
            top: note.position.dy,
            child: _NoteCard(
              note: note,
              onPan: (d) => onMove(note, d.delta),
              onTap: () => onTap(note),
            ),
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StickyNote note;
  final GestureDragUpdateCallback onPan;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onPan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Una leve inclinación distinta por nota, como post-its pegados a mano.
    final tilt = ((note.id % 5) - 2) * 0.025;
    return Semantics(
      button: true,
      label: 'Nota: ${note.text}',
      hint: 'Toca para editar, arrastra para mover',
      child: GestureDetector(
        onPanUpdate: onPan,
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
    final canUndo = ref.watch(canvasProvider.select((s) => s.strokes.isNotEmpty));
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
