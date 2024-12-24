import 'package:arryuwu/colors/palette.dart';
import 'package:flutter/material.dart';

class CodePage extends StatelessWidget {
  const CodePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Código y Vinculación'),
        backgroundColor:
            Palette.blueAccent, // Usando el azul claro de la paleta
      ),
      body: SingleChildScrollView(
        // Scroll para que sea responsivo
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card para Generar Código
            _buildGenerateCard(),
            const SizedBox(height: 20),
            // Card para Vincular Código
            _buildLinkCard(),
          ],
        ),
      ),
    );
  }

  // Card para Generar Código
  Widget _buildGenerateCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      shadowColor:
          Palette.shadowColor, // Usando la sombra definida en la paleta
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la Card
            const Text(
              "Generar Código",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Palette.blueAccent, // Usando el azul claro de la paleta
              ),
            ),
            const SizedBox(height: 10),
            // Descripción
            const Text(
              "Crea un código único para compartir con tu pareja. El código generado es único y solo se puede usar una vez.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            // Indicador de progreso (simulado)
            const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Generando código..."),
              ],
            ),
            const SizedBox(height: 30),
            // Campo de texto para mostrar el código
            const Text(
              "Código generado:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Mostrar el código generado (simulado aquí)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Palette.blueAccent
                    .withOpacity(0.1), // Usando el azul claro con opacidad
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Palette.blueAccent.withOpacity(0.1),
                    blurRadius: 8.0,
                    spreadRadius: 2.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                "AB1234CD",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      Palette.blueAccent, // Usando el azul claro de la paleta
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Botón para generar código
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Palette.primary, // Usando el azul claro de la paleta
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Generar Nuevo Código",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card para Vincular Código
  Widget _buildLinkCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      shadowColor:
          Palette.shadowColor, // Usando la sombra definida en la paleta
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vincular Código",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                    Palette.pinkAccent, // Usando el rosa definido en la paleta
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Introduce un código para vincular.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            // Campo de texto para ingresar el código
            TextField(
              decoration: InputDecoration(
                hintText: "Introduce tu código aquí",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                fillColor: Colors.grey[100],
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Palette.pinkAccent, // Usando el rosa definido en la paleta
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Vincular Código",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
