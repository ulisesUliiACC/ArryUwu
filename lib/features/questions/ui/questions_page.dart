import 'dart:math';

import 'package:arryuwu/features/questions/data/question_bank.dart';
import 'package:arryuwu/features/questions/data/questions_controller.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/app_text_field.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/pressable.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preguntas tipo carta: se baraja, se responde y queda un historial tipo chat.
class QuestionsPage extends ConsumerStatefulWidget {
  const QuestionsPage({super.key});

  @override
  ConsumerState<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends ConsumerState<QuestionsPage> {
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _shuffle() {
    HapticFeedback.selectionClick();
    ref.read(questionsProvider.notifier).next();
  }

  void _save() {
    final saved = ref.read(questionsProvider.notifier).answer(_answerController.text);
    if (!saved) return;
    HapticFeedback.lightImpact();
    _answerController.clear();
    FocusScope.of(context).unfocus();
    showAppSnack(context, 'Respuesta guardada 💜');
  }

  Future<void> _askOwn() async {
    final text = await showDialog<String>(context: context, builder: (_) => const _AskDialog());
    if (text != null) ref.read(questionsProvider.notifier).ask(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionsProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas'),
        actions: [
          IconButton(
            tooltip: 'Escribir mi propia pregunta',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _askOwn,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Entrance(
              child: _QuestionDeck(
                question: state.current,
                flip: state.flip,
                counter: state.current.topic == QuestionTopic.tuya
                    ? 'Pregunta especial'
                    : 'Carta ${state.position + 1} de ${state.deck.length}',
                onShuffle: _shuffle,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Entrance(
              index: 1,
              child: AppSecondaryButton(label: 'Otra pregunta', onPressed: _shuffle),
            ),
            const SizedBox(height: AppSpacing.xl),
            Entrance(
              index: 2,
              child: AppTextField(
                controller: _answerController,
                label: 'Tu respuesta',
                icon: Icons.chat_bubble_outline_rounded,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Entrance(
              index: 3,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _answerController,
                builder: (_, value, __) => AppPrimaryButton(
                  label: 'Guardar respuesta',
                  icon: Icons.favorite_rounded,
                  onPressed: value.text.trim().isEmpty ? null : _save,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Entrance(
              index: 4,
              child: Row(
                children: [
                  Expanded(child: Text('Sus respuestas', style: text.titleLarge)),
                  if (state.history.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderSoft,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '${state.history.length}',
                        style: text.labelSmall?.copyWith(color: AppColors.lavenderDeep),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.history.isEmpty)
              const Entrance(
                index: 5,
                child: AppMessageView(
                  icon: Icons.forum_rounded,
                  title: 'Aún no hay respuestas',
                  subtitle: 'Respondan la primera carta y aquí irá quedando su conversación.',
                ),
              )
            else
              for (final item in state.history)
                Entrance(
                  key: ObjectKey(item),
                  child: _AnswerThread(
                    item: item,
                    onDelete: () => ref.read(questionsProvider.notifier).remove(item),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// La carta grande. Se voltea al cambiar de pregunta y se puede deslizar para barajar.
class _QuestionDeck extends StatelessWidget {
  final Question question;
  final int flip;
  final String counter;
  final VoidCallback onShuffle;

  const _QuestionDeck({
    required this.question,
    required this.flip,
    required this.counter,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pregunta: ${question.text}',
      hint: 'Desliza para ver otra pregunta',
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0).abs() > 250) onShuffle();
        },
        child: Stack(
          children: [
            // Cartas de atrás: dan la sensación de baraja.
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(0, AppSpacing.md),
                child: Transform.scale(scale: 0.92, child: const _BackCard(alpha: 0.35)),
              ),
            ),
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(0, AppSpacing.sm - 2),
                child: Transform.scale(scale: 0.96, child: const _BackCard(alpha: 0.6)),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              transitionBuilder: (child, animation) => _FlipTransition(
                animation: animation,
                incoming: child.key == ValueKey(flip),
                child: child,
              ),
              child: _FrontCard(key: ValueKey(flip), question: question, counter: counter),
            ),
          ],
        ),
      ),
    );
  }
}

/// Voltea en el eje Y: la carta vieja gira hasta quedar de canto y la nueva aparece desde el otro lado.
class _FlipTransition extends AnimatedWidget {
  final bool incoming;
  final Widget child;

  const _FlipTransition({required Animation<double> animation, required this.incoming, required this.child})
      : super(listenable: animation);

  static const _half = Interval(0.5, 1, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final t = _half.transform((listenable as Animation<double>).value);
    final angle = (1 - t) * (pi / 2) * (incoming ? -1 : 1);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(angle),
      child: child,
    );
  }
}

class _BackCard extends StatelessWidget {
  final double alpha;

  const _BackCard({required this.alpha});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.lavender.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      );
}

class _FrontCard extends StatelessWidget {
  final Question question;
  final String counter;

  const _FrontCard({super.key, required this.question, required this.counter});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final soft = text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.9));

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: question.topic == QuestionTopic.tuya
              ? const [AppColors.pinkDeep, AppColors.lavenderDeep]
              : const [AppColors.lavenderDeep, AppColors.pinkDeep],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text('${question.topic.emoji}  ${question.topic.label}',
                    style: text.labelSmall?.copyWith(color: Colors.white)),
              ),
              const Spacer(),
              Text(counter, style: soft),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            question.text,
            style: text.titleLarge?.copyWith(color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(Icons.swipe_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: AppSpacing.xs),
              Text('Desliza para barajar', style: soft),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pregunta (izquierda) y respuesta (derecha) como burbujas de chat. Se borra deslizando.
class _AnswerThread extends StatelessWidget {
  final AnsweredQuestion item;
  final VoidCallback onDelete;

  const _AnswerThread({required this.item, required this.onDelete});

  static String _time(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const r = Radius.circular(AppSpacing.radiusMd);
    const tail = Radius.circular(AppSpacing.xs);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Dismissible(
      key: ObjectKey(item),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, semanticLabel: 'Borrar'),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.lavenderSoft,
                    borderRadius: BorderRadius.only(topLeft: r, topRight: r, bottomRight: r, bottomLeft: tail),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.question.topic.emoji} ${item.question.topic.label}',
                          style: text.labelSmall?.copyWith(color: AppColors.lavenderDeep)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.question.text, style: text.bodyMedium?.copyWith(color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Pressable(
                  pressedScale: 0.98,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lavenderDeep,
                      borderRadius:
                          const BorderRadius.only(topLeft: r, topRight: r, bottomLeft: r, bottomRight: tail),
                      boxShadow: AppSpacing.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item.answer, style: text.bodyLarge?.copyWith(color: Colors.white)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(_time(item.at),
                            style: text.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para escribir una pregunta propia.
class _AskDialog extends StatefulWidget {
  const _AskDialog();

  @override
  State<_AskDialog> createState() => _AskDialogState();
}

class _AskDialogState extends State<_AskDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      title: const Text('Tu propia pregunta'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: '¿Qué le quieres preguntar?'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _submit, child: const Text('Usar pregunta')),
      ],
    );
  }
}
