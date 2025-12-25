import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/notes_service.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;

  const NoteEditorPage({
    Key? key,
    this.note,
  }) : super(key: key);

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _category;
  late Color _color;
  bool _isSaving = false;

  final List<String> _categories = ['Personal', 'Work', 'Ideas', 'Shopping'];
  final List<Color> _colors = [
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _category = widget.note?.category ?? 'Personal';
    _color = widget.note?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final notesService = Provider.of<NotesService>(context, listen: false);

    if (authService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error')),
      );
      setState(() => _isSaving = false);
      return;
    }

    bool success;
    if (widget.note == null) {
      // Create new note
      final newNote = Note(
        title: _titleController.text,
        content: _contentController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: _category,
        colorValue: Note.colorToString(_color),
      );
      success = await notesService.createNote(authService.token!, newNote);
    } else {
      // Update existing note
      widget.note!.title = _titleController.text;
      widget.note!.content = _contentController.text;
      widget.note!.category = _category;
      widget.note!.colorValue = Note.colorToString(_color);
      widget.note!.updatedAt = DateTime.now();
      success = await notesService.updateNote(authService.token!, widget.note!);
    }

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save note')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Note title',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Category: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _category,
                  underline: Container(),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _category = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Color: ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _color = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              maxLines: null,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Start writing...',
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}