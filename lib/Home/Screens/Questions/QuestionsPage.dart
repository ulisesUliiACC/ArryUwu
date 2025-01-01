import 'dart:math';
import 'package:flutter/material.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({Key? key}) : super(key: key);

  @override
  _QuestionsPageState createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  final List<Map<String, String>> _questions =
      []; // Historial de preguntas y respuestas
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  String? _currentQuestion; // La pregunta actual que espera respuesta

  // Lista de preguntas aleatorias
  final List<String> _randomQuestions = [
    "¿Cuál es tu película favorita?",
    "¿Qué harías si ganaras la lotería?",
    "¿Qué es lo que más te gusta de tu pareja?",
    "¿Cuál es tu recuerdo más feliz?",
    "¿Qué lugar del mundo te gustaría visitar?",
    "¿Cuál es tu mayor miedo?",
    "¿Qué superpoder elegirías y por qué?",
    "¿Qué harías si solo tuvieras un día de vida?",
    "¿Qué te hace sentir realmente feliz?",
    "¿Cuál es tu comida favorita?",
  ];

  void _addQuestion() {
    final question = _questionController.text.trim();
    if (question.isNotEmpty) {
      setState(() {
        _currentQuestion = question; // Establecer la pregunta actual
        _questionController.clear(); // Limpiar el campo de texto
      });
    }
  }

  void _addRandomQuestion() {
    if (_randomQuestions.isNotEmpty) {
      setState(() {
        // Seleccionar una pregunta aleatoria
        _currentQuestion =
            _randomQuestions[Random().nextInt(_randomQuestions.length)];
      });
    }
  }

  void _addAnswer() {
    final answer = _answerController.text.trim();
    if (answer.isNotEmpty && _currentQuestion != null) {
      setState(() {
        // Agregar pregunta y respuesta al historial
        _questions.add({
          'question': _currentQuestion!,
          'answer': answer,
        });
        _currentQuestion = null; // Limpiar la pregunta actual
        _answerController.clear(); // Limpiar el campo de texto
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preguntas')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Historial de Preguntas y Respuestas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final item = _questions[index];
                  return ListTile(
                    title: Text('Pregunta: ${item['question']}'),
                    subtitle: Text('Respuesta: ${item['answer']}'),
                  );
                },
              ),
            ),
            const Divider(),
            if (_currentQuestion == null) ...[
              const Text(
                "Haz una pregunta",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Escribe tu pregunta aquí',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addQuestion,
                      child: const Text('Enviar Pregunta'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addRandomQuestion,
                      child: const Text('Pregunta Aleatoria'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                "Pregunta actual: $_currentQuestion",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Escribe tu respuesta aquí',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addAnswer,
                child: const Text('Responder'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
