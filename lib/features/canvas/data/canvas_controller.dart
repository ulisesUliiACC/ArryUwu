import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/core/api_config.dart';
import 'package:arryuwu/core/token_storage.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';

/// Coordenadas RELATIVAS al ancho del lienzo: x de 0 a 1 y y en "anchos" (0 arriba).
/// Así un dibujo hecho en un celular se ve igual en otro de distinto tamaño.

/// Un trazo: puntos relativos, color, grosor relativo y quién lo hizo.
class Stroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double width;
  final String? by;

  Stroke({required this.id, required List<Offset> points, required this.color, required this.width, this.by})
      : points = List.unmodifiable(points);

  Stroke withMore(List<Offset> more) => Stroke(id: id, points: [...points, ...more], color: color, width: width, by: by);
}

/// Nota tipo post-it (posición relativa).
class StickyNote {
  final String id;
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

/// Grosores en píxeles de referencia (se guardan relativos al ancho del lienzo).
const canvasWidths = <double>[3, 7, 14];
const canvasWidthNames = <String>['Fino', 'Medio', 'Grueso'];

/// Fondos suaves para los post-it (opacos, el texto en tinta se lee bien).
final noteColors = <Color>[
  AppColors.lavenderSoft,
  Color.alphaBlend(AppColors.pink.withValues(alpha: 0.4), Colors.white),
  Color.alphaBlend(AppColors.success.withValues(alpha: 0.14), Colors.white),
  Color.alphaBlend(AppColors.lavender.withValues(alpha: 0.32), Colors.white),
];

enum SyncStatus { connecting, live, offline }

class CanvasState {
  final List<Stroke> strokes;
  final List<StickyNote> notes;
  final SyncStatus status;
  final String? me;
  final List<String> online;
  final DateTime? partnerDrawingAt; // última vez que llegó un trazo de la pareja

  const CanvasState({
    this.strokes = const [],
    this.notes = const [],
    this.status = SyncStatus.connecting,
    this.me,
    this.online = const [],
    this.partnerDrawingAt,
  });

  bool get isEmpty => strokes.isEmpty && notes.isEmpty;

  /// Usuario de la pareja conectado ahora mismo (si lo hay).
  String? get partnerOnline => online.where((u) => u != me).firstOrNull;

  bool get partnerIsDrawing =>
      partnerDrawingAt != null && DateTime.now().difference(partnerDrawingAt!) < const Duration(milliseconds: 1500);

  CanvasState copyWith({
    List<Stroke>? strokes,
    List<StickyNote>? notes,
    SyncStatus? status,
    String? me,
    List<String>? online,
    DateTime? partnerDrawingAt,
  }) =>
      CanvasState(
        strokes: strokes ?? this.strokes,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        me: me ?? this.me,
        online: online ?? this.online,
        partnerDrawingAt: partnerDrawingAt ?? this.partnerDrawingAt,
      );
}

/// Lienzo compartido en vivo con la pareja por WebSocket (/ws/canvas).
///
/// - Los cambios propios se aplican al instante en pantalla y se envían al servidor.
/// - Los puntos de un trazo en curso se agrupan y se mandan cada ~50 ms, así la pareja
///   ve el trazo crecer mientras se dibuja.
/// - Si se cae la conexión, las operaciones se guardan en cola y se reintenta con espera creciente;
///   al reconectar llega el estado del servidor y se reenvía la cola.
class CanvasController extends Notifier<CanvasState> {
  IOWebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  Timer? _flushTimer;
  int _attempt = 0;
  bool _disposed = false;

  final List<Map<String, dynamic>> _outbox = [];
  final Map<String, List<Offset>> _pendingPoints = {}; // id → puntos aún sin enviar
  final Map<String, (int, double)> _pendingStyle = {}; // id → (color, grosor) del primer envío

  static final _rand = math.Random();

  @override
  CanvasState build() {
    ref.onDispose(() {
      _disposed = true;
      _reconnectTimer?.cancel();
      _flushTimer?.cancel();
      _sub?.cancel();
      _channel?.sink.close();
    });
    Future.microtask(_connect);
    return const CanvasState();
  }

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rand.nextInt(1 << 30).toRadixString(36)}';

  // ---------------------------------------------------------------- conexión

  Future<void> _connect() async {
    if (_disposed) return;
    state = state.copyWith(status: SyncStatus.connecting);
    try {
      final token = await TokenStorage.accessToken;
      final uri = Uri.parse('${ApiConfig.baseUrl.replaceFirst('http', 'ws')}/ws/canvas');
      final channel = IOWebSocketChannel.connect(
        uri,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        pingInterval: const Duration(seconds: 20),
      );
      await channel.ready;
      if (_disposed) {
        channel.sink.close();
        return;
      }
      _channel = channel;
      _attempt = 0;
      _sub = channel.stream.listen(_onMessage, onDone: _onDrop, onError: (_) => _onDrop());
    } catch (_) {
      // Puede ser token vencido: una llamada normal a la API lo renueva antes del siguiente intento.
      try {
        await ApiClient.instance.get('/api/me');
      } catch (_) {}
      _onDrop();
    }
  }

  void _onDrop() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (_disposed) return;
    state = state.copyWith(status: SyncStatus.offline, online: const []);
    final seconds = math.min(15, 1 << _attempt++);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: seconds), _connect);
  }

  void retryNow() {
    _attempt = 0;
    _reconnectTimer?.cancel();
    if (_channel == null) _connect();
  }

  void _onMessage(dynamic raw) {
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    _apply(m, fromServer: true);
  }

  void _apply(Map<String, dynamic> m, {required bool fromServer}) {
    switch (m['t']) {
      case 'snapshot':
        state = state.copyWith(
          status: SyncStatus.live,
          me: m['me'] as String?,
          strokes: [for (final s in (m['strokes'] as List? ?? const [])) _strokeFromJson(s)],
          notes: [for (final n in (m['notes'] as List? ?? const [])) _noteFromJson(n)],
        );
        _replayOutbox();
      case 'presence':
        state = state.copyWith(online: [for (final u in (m['online'] as List? ?? const [])) u as String]);
      case 'draw':
        final id = m['id'] as String;
        final pts = _points(m['pts']);
        final idx = state.strokes.indexWhere((s) => s.id == id);
        final strokes = [...state.strokes];
        if (idx >= 0) {
          strokes[idx] = strokes[idx].withMore(pts);
        } else {
          strokes.add(Stroke(
            id: id,
            points: pts,
            color: Color(((m['color'] as num?) ?? 0xFF2B2840).toInt()),
            width: ((m['width'] as num?) ?? 0.01).toDouble(),
            by: m['by'] as String?,
          ));
        }
        state = state.copyWith(strokes: strokes, partnerDrawingAt: fromServer ? DateTime.now() : null);
      case 'remove':
        state = state.copyWith(strokes: state.strokes.where((s) => s.id != m['id']).toList());
      case 'clear':
        state = state.copyWith(strokes: const [], notes: const []);
      case 'note':
        final note = _noteFromJson(m['note']);
        final others = state.notes.where((n) => n.id != note.id);
        state = state.copyWith(notes: [...others, note]);
      case 'unnote':
        state = state.copyWith(notes: state.notes.where((n) => n.id != m['id']).toList());
    }
  }

  void _send(Map<String, dynamic> op) {
    final ch = _channel;
    if (ch != null && state.status == SyncStatus.live) {
      ch.sink.add(jsonEncode(op));
    } else {
      _outbox.add(op);
    }
  }

  /// Tras reconectar: vuelve a aplicar sobre el estado del servidor lo que se hizo sin conexión y lo envía.
  void _replayOutbox() {
    final pending = List.of(_outbox);
    _outbox.clear();
    for (final op in pending) {
      _apply({...op, 'by': state.me}, fromServer: false);
      _send(op);
    }
  }

  // ---------------------------------------------------------------- trazos

  /// Empieza un trazo propio. Mientras se dibuja vive en la capa del trazo en curso de la pantalla
  /// (más fluido); aquí solo se van enviando sus puntos (relativos) a la pareja.
  void startStroke(String id, Offset first, Color color, double width) {
    _pendingPoints[id] = [first];
    _pendingStyle[id] = (color.toARGB32(), width);
    _scheduleFlush();
  }

  void extendStroke(String id, Offset p) {
    (_pendingPoints[id] ??= []).add(p);
    _scheduleFlush();
  }

  /// Termina el trazo: envía lo pendiente y lo agrega a la lista de trazos.
  void finishStroke(Stroke stroke) {
    _flush();
    state = state.copyWith(strokes: [...state.strokes, stroke]);
  }

  void _scheduleFlush() {
    _flushTimer ??= Timer(const Duration(milliseconds: 50), _flush);
  }

  void _flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pendingPoints.forEach((id, pts) {
      if (pts.isEmpty) return;
      // El servidor acepta hasta 500 puntos por mensaje.
      for (var i = 0; i < pts.length; i += 400) {
        final chunk = pts.sublist(i, math.min(i + 400, pts.length));
        final style = _pendingStyle.remove(id);
        _send({
          't': 'draw',
          'id': id,
          if (style != null) 'color': style.$1,
          if (style != null) 'width': style.$2,
          'pts': [
            for (final p in chunk) [_r(p.dx), _r(p.dy)],
          ],
        });
      }
    });
    _pendingPoints.clear();
  }

  bool _isMine(Stroke s) => s.by == null || s.by == state.me;

  /// Deshace mi último trazo (no borra los de mi pareja).
  void undo() {
    final mine = state.strokes.where(_isMine).lastOrNull;
    if (mine == null) return;
    state = state.copyWith(strokes: state.strokes.where((s) => s.id != mine.id).toList());
    _send({'t': 'remove', 'id': mine.id});
  }

  void clear() {
    state = state.copyWith(strokes: const [], notes: const []);
    _send({'t': 'clear'});
  }

  // ---------------------------------------------------------------- notas

  void upsertNote(StickyNote note, {bool send = true}) {
    final others = state.notes.where((n) => n.id != note.id);
    state = state.copyWith(notes: [...others, note]);
    if (send) _send({'t': 'note', 'note': _noteToJson(note)});
  }

  /// Mientras se arrastra solo se mueve en pantalla; al soltar se envía con [commitNote].
  void moveNoteLocal(StickyNote note) => upsertNote(note, send: false);

  void commitNote(String id) {
    final note = state.notes.where((n) => n.id == id).firstOrNull;
    if (note != null) _send({'t': 'note', 'note': _noteToJson(note)});
  }

  void removeNote(String id) {
    state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());
    _send({'t': 'unnote', 'id': id});
  }

  // ---------------------------------------------------------------- JSON

  static double _r(double v) => (v * 10000).roundToDouble() / 10000;

  static List<Offset> _points(dynamic pts) => [
        for (final p in (pts as List? ?? const []))
          Offset(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()),
      ];

  static Stroke _strokeFromJson(dynamic j) => Stroke(
        id: j['id'] as String,
        points: _points(j['pts']),
        color: Color((j['color'] as num).toInt()),
        width: (j['width'] as num).toDouble(),
        by: j['by'] as String?,
      );

  static StickyNote _noteFromJson(dynamic j) => StickyNote(
        id: j['id'] as String,
        text: j['text'] as String? ?? '',
        position: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
        color: Color((j['color'] as num).toInt()),
      );

  static Map<String, dynamic> _noteToJson(StickyNote n) => {
        'id': n.id,
        'text': n.text,
        'x': _r(n.position.dx),
        'y': _r(n.position.dy),
        'color': n.color.toARGB32(),
      };
}

/// Se desconecta al salir del lienzo (autoDispose) y se reconecta al volver.
final canvasProvider = NotifierProvider.autoDispose<CanvasController, CanvasState>(CanvasController.new);
