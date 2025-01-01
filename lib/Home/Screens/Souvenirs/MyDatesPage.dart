import 'package:flutter/material.dart';

class MyDatesPage extends StatelessWidget {
  MyDatesPage({Key? key}) : super(key: key);

  // Lista de citas con foto, fecha y descripción
  final List<Map<String, dynamic>> dates = [
    {
      "img": "assets/img/date1.jpeg", // Ruta de la imagen
      "date": "2024-12-10", // Fecha de la cita
      "description":
          "Un día perfecto en el parque, caminamos juntos y hablamos de todo.",
    },
    {
      "img": "assets/img/date2.jpeg", // Ruta de la imagen
      "date": "2024-12-15", // Fecha de la cita
      "description":
          "Cena en un restaurante con vista al mar, todo estuvo increíble.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Citas - Línea del Tiempo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mi Línea del Tiempo de Citas",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Lista de citas (línea del tiempo)
            Expanded(
              child: ListView.builder(
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  return _timelineEvent(context, date);
                },
              ),
            ),
            // Botón para agregar nueva cita
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                    context, '/addDate'); // Navegar para agregar una nueva cita
              },
              child: const Text("Agregar Cita"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineEvent(BuildContext context, Map<String, dynamic> date) {
    return Dismissible(
      key: Key(date["date"]),
      onDismissed: (direction) {
        // Eliminar cita
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cita eliminada")),
        );
        // Aquí puedes agregar la lógica para eliminar la cita de la lista
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: ListTile(
          leading: Hero(
            tag: date["img"], // El tag debe ser único para cada imagen
            child: CircleAvatar(
              backgroundImage: AssetImage(date["img"]),
              radius: 30,
            ),
          ),
          title: Text(date["date"]),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(date["description"]),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Eliminar cita
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cita eliminada")),
              );
              // Aquí puedes agregar la lógica de eliminación
            },
          ),
          onTap: () {
            _showImageDetail(context, date["img"]);
          },
        ),
      ),
    );
  }

  // Mostrar imagen al hacer clic
  void _showImageDetail(BuildContext context, String imgPath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Image.asset(imgPath),
        );
      },
    );
  }
}
