import 'package:flutter/material.dart';

class DrawingBoard extends StatefulWidget {
  const DrawingBoard({super.key});

  @override
  _DrawingBoardState createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  List<Offset> points = []; // Almacena los puntos dibujados
  List<Map<String, dynamic>> notes = []; // Almacena las notitas

  final TextEditingController _noteController = TextEditingController();

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Agregar Nota"),
          content: TextField(
            controller: _noteController,
            decoration: const InputDecoration(hintText: "Escribe tu nota"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  notes.add({
                    "text": _noteController.text,
                    "position": Offset(50, 50), // Posición inicial
                  });
                });
                _noteController.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Agregar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lienzo Interactivo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: _addNote, // Agregar una nueva nota
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                points.clear(); // Limpiar los dibujos
                notes.clear(); // Limpiar las notas
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                points.add(details.localPosition); // Añadir puntos al dibujo
              });
            },
            onPanEnd: (details) {
              points.add(Offset.zero); // Marca el final de un trazo
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: DrawingPainter(points),
            ),
          ),
          // Mostrar notitas en la pantalla
          ...notes.map((note) {
            return Positioned(
              left: note["position"].dx,
              top: note["position"].dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    note["position"] += details.delta; // Mover la nota
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.yellow[200],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(note["text"]),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint); // Dibuja las líneas
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
