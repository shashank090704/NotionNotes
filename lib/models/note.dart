import 'package:flutter/material.dart';

class Note {
  String? id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  String category;
  String colorValue;
  bool isFavorite;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.colorValue,
    this.isFavorite = false,
  });

  Color get color {
    switch (colorValue) {
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      category: json['category'] ?? 'Personal',
      colorValue: json['color'] ?? 'blue',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category,
      'color': colorValue,
      'isFavorite': isFavorite,
    };
  }

  static String colorToString(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.red) return 'red';
    if (color == Colors.teal) return 'teal';
    return 'blue';
  }
}