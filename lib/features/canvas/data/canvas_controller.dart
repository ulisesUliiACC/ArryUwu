import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un trazo terminado: sus puntos, color y grosor. Inmutable.
class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;

  Stroke({required List<Offset> points, required this.color, required this.width})
      : points = List.unmodifiable(points);
}

/// Nota tipo post-it que se puede arrastrar por el lienzo.
class StickyNote {
  final int id;
  final String text;
  final Offset position;
  final Color color;

  const StickyNote({required this.id, required this.text, required this.position, required this.color});

  StickyNote copyWith({String? text, Offset? position, Color? color}) => StickyNote(
        id: id,
        text: text ?? this.text,
        position: position ?? this.position,
        color: color ?? this.color,
      );
}

/// Colores para dibujar (todos de la marca).
const canvasInkColors = <Color>[
  AppColors.ink,
  AppColors.lavenderDeep,
  AppColors.lavender,
  AppColors.pinkDeep,
  AppColors.pink,
  AppColors.success,
];

const canvasInkNames = <String>['Tinta', 'Lavanda intenso', 'Lavanda', 'Rosa intenso', 'Rosa', 'Verde'];

/// Grosores: fino, medio y grueso.
const canvasWidths = <double>[3, 7, 14];
const canvasWidthNames = <String>['Fino', 'Medio', 'Grueso'];

/// Fondos suaves para los post-it (opacos, el texto en tinta se lee bien).
final noteColors = <Color>[
  AppColors.lavenderSoft,
  Color.alphaBlend(AppColors.pink.withValues(alpha: 0.4), Colors.white),
  Color.alphaBlend(AppColors.success.withValues(alpha: 0.14), Colors.white),
  Color.alphaBlend(AppColors.lavender.withValues(alpha: 0.32), Colors.white),
];

class CanvasState {
  final List<Stroke> strokes;
  final List<StickyNote> notes;

  const CanvasState({this.strokes = const [], this.notes = const []});

  bool get isEmpty => strokes.isEmpty && notes.isEmpty;

  CanvasState copyWith({List<Stroke>? strokes, List<StickyNote>? notes}) =>
      CanvasState(strokes: strokes ?? this.strokes, notes: notes ?? this.notes);
}

/// Estado del lienzo en memoria (sin backend). Cada cambio crea listas nuevas,
/// así los pintores comparan por identidad y solo repintan cuando algo cambió.
class CanvasController extends Notifier<CanvasState> {
  int _nextId = 0;

  @override
  CanvasState build() => const CanvasState();

  void addStroke(Stroke stroke) {
    if (stroke.points.isEmpty) return;
    state = state.copyWith(strokes: [...state.strokes, stroke]);
  }

  void undo() {
    if (state.strokes.isEmpty) return;
    state = state.copyWith(strokes: state.strokes.sublist(0, state.strokes.length - 1));
  }

  void clear() => state = const CanvasState();

  void addNote(String text, Color color, Offset position) {
    state = state.copyWith(notes: [
      ...state.notes,
      StickyNote(id: _nextId++, text: text, position: position, color: color),
    ]);
  }

  void updateNote(int id, {String? text, Color? color, Offset? position}) {
    state = state.copyWith(notes: [
      for (final n in state.notes) n.id == id ? n.copyWith(text: text, color: color, position: position) : n,
    ]);
  }

  void removeNote(int id) {
    state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());
  }
}

final canvasProvider = NotifierProvider<CanvasController, CanvasState>(CanvasController.new);
