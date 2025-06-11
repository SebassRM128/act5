import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  String? id;
  final String title;
  final String content;
  final Timestamp timestamp; // Para ordenar y saber cuándo se creó

  Note({this.id, required this.title, required this.content, required this.timestamp});

  // Constructor para crear un objeto Note desde un documento de Firestore
  factory Note.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  // Método para convertir un objeto Note a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'timestamp': timestamp,
    };
  }
}