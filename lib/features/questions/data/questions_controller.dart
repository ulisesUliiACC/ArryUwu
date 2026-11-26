import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'question_bank.dart';

/// Una pregunta ya respondida (se guarda solo en memoria).
class AnsweredQuestion {
  final Question question;
  final String answer;
  final DateTime at;

  const AnsweredQuestion({required this.question, required this.answer, required this.at});
}

class QuestionsState {
  /// Orden barajado de [questionBank]; se vuelve a barajar al terminar la baraja.
  final List<int> deck;
  final int position;

  /// Pregunta en la carta. Puede ser una escrita por el usuario.
  final Question current;

  /// Cambia cada vez que se baraja: sirve de llave para animar la carta.
  final int flip;

  /// Más reciente primero.
  final List<AnsweredQuestion> history;

  const QuestionsState({
    required this.deck,
    required this.position,
    required this.current,
    required this.flip,
    required this.history,
  });

  QuestionsState copyWith({
    List<int>? deck,
    int? position,
    Question? current,
    int? flip,
    List<AnsweredQuestion>? history,
  }) =>
      QuestionsState(
        deck: deck ?? this.deck,
        position: position ?? this.position,
        current: current ?? this.current,
        flip: flip ?? this.flip,
        history: history ?? this.history,
      );
}

class QuestionsController extends Notifier<QuestionsState> {
  final _random = Random();

  List<int> _shuffled() => List<int>.generate(questionBank.length, (i) => i)..shuffle(_random);

  @override
  QuestionsState build() {
    final deck = _shuffled();
    return QuestionsState(deck: deck, position: 0, current: questionBank[deck.first], flip: 0, history: const []);
  }

  /// Saca la siguiente carta de la baraja.
  void next() {
    var deck = state.deck;
    var position = state.position + 1;
    if (position >= deck.length) {
      final last = deck.last;
      deck = _shuffled();
      // Que no repita justo la misma al volver a barajar.
      if (deck.first == last && deck.length > 1) deck.add(deck.removeAt(0));
      position = 0;
    }
    state = state.copyWith(deck: deck, position: position, current: questionBank[deck[position]], flip: state.flip + 1);
  }

  /// Pone en la carta una pregunta escrita por el usuario.
  void ask(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    state = state.copyWith(current: Question(clean, QuestionTopic.tuya), flip: state.flip + 1);
  }

  /// Guarda la respuesta de la carta actual y pasa a la siguiente.
  bool answer(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return false;
    state = state.copyWith(history: [
      AnsweredQuestion(question: state.current, answer: clean, at: DateTime.now()),
      ...state.history,
    ]);
    next();
    return true;
  }

  void remove(AnsweredQuestion item) {
    state = state.copyWith(history: state.history.where((h) => !identical(h, item)).toList());
  }
}

final questionsProvider = NotifierProvider<QuestionsController, QuestionsState>(QuestionsController.new);
