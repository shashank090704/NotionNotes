import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/note.dart';

class NotesService extends ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> fetchNotes(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(AppConstants.notesEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notes = data.map((json) => Note.fromJson(json)).toList();
      } else {
        print('Failed to fetch notes: ${response.body}');
      }
    } catch (e) {
      print('Error fetching notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNote(String token, Note note) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.notesEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(note.toJson()),
      );

      if (response.statusCode == 201) {
        final newNote = Note.fromJson(jsonDecode(response.body));
        _notes.insert(0, newNote);
        notifyListeners();
        return true;
      } else {
        print('Failed to create note: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating note: $e');
      return false;
    }
  }

  Future<bool> updateNote(String token, Note note) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.notesEndpoint}/${note.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(note.toJson()),
      );

      if (response.statusCode == 200) {
        final updatedNote = Note.fromJson(jsonDecode(response.body));
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = updatedNote;
          notifyListeners();
        }
        return true;
      } else {
        print('Failed to update note: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  Future<bool> deleteNote(String token, String noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.notesEndpoint}/$noteId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _notes.removeWhere((n) => n.id == noteId);
        notifyListeners();
        return true;
      } else {
        print('Failed to delete note: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(String token, Note note) async {
    note.isFavorite = !note.isFavorite;
    note.updatedAt = DateTime.now();
    return await updateNote(token, note);
  }

  void clearNotes() {
    _notes = [];
    notifyListeners();
  }
}