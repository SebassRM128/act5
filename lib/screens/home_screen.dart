import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Definición de la clase Note (Modelo)
// En una aplicación real, esto estaría en models/note.dart
class Note {
  String? id; // El ID de Firestore es opcional al crear una nota nueva
  final String title;
  final String content;
  final Timestamp timestamp;

  Note({this.id, required this.title, required this.content, required this.timestamp});

  // Método para crear una instancia de Note desde un mapa (usado al leer de Firestore)
  factory Note.fromMap(Map<String, dynamic> data, String id) {
    return Note(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  // Método para convertir una instancia de Note a un mapa (usado al escribir en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'timestamp': timestamp,
    };
  }
}

// Definición de la clase FirestoreService (Servicio para interactuar con Firestore)
// En una aplicación real, esto estaría en services/firestore_service.dart
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Colección donde se guardarán las notas
  late final CollectionReference _notesCollection;

  FirestoreService() {
    _notesCollection = _db.collection('notes');
  }

  // Añadir una nueva nota
  Future<void> addNote(Note note) async {
    await _notesCollection.add(note.toMap());
  }

  // Obtener todas las notas como un stream (para actualizaciones en tiempo real)
  Stream<List<Note>> getNotes() {
    return _notesCollection.orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Note.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  // Eliminar una nota por su ID
  Future<void> deleteNote(String id) async {
    await _notesCollection.doc(id).delete();
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instanciamos el servicio de Firestore
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Función para guardar una nota
  void _saveNote() {
    if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
      final newNote = Note(
        title: _titleController.text,
        content: _contentController.text,
        timestamp: Timestamp.now(),
      );
      _firestoreService.addNote(newNote); // Llama al servicio para añadir la nota
      _titleController.clear(); // Limpia los campos de texto
      _contentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota de reloj guardada!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena ambos campos.')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relojería de Notas', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent, // Añadido un color de fondo para el AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Añade una Nota de Reloj',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87), // Ajustado color
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Marca o Modelo del Reloj',
                hintText: 'Ej: Rolex Submariner',
                border: OutlineInputBorder(), // Añadido un borde
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Características o Detalles',
                hintText: 'Ej: Movimiento automático, resistente al agua...',
                border: OutlineInputBorder(), // Añadido un borde
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Color del botón
                foregroundColor: Colors.white, // Color del texto del botón
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Guardar Nota del Reloj'),
            ),
            const SizedBox(height: 30),
            Text(
              'Mis Notas de Relojes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87), // Ajustado color
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<List<Note>>(
                stream: _firestoreService.getNotes(), // Obtiene las notas en tiempo real
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aún no hay notas de relojes. ¡Añade una!',
                        style: TextStyle(color: Colors.black54), // Ajustado color
                      ),
                    );
                  }

                  final notes = snapshot.data!;
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2, // Añadido un poco de elevación
                        child: ListTile(
                          title: Text(
                            note.title,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold), // Ajustado color
                          ),
                          subtitle: Text(
                            note.content,
                            style: const TextStyle(color: Colors.black54), // Ajustado color
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent), // Icono de bote de basura
                            onPressed: () {
                              _firestoreService.deleteNote(note.id!); // Elimina la nota
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nota de reloj eliminada.')),
                              );
                            },
                          ),
                          // Opcional: Para mostrar la fecha/hora
                          leading: Text(
                            '${note.timestamp.toDate().day}/${note.timestamp.toDate().month}',
                            style: const TextStyle(color: Colors.black45, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}