import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/notes_service.dart';
import 'editor_screen.dart';

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({Key? key}) : super(key: key);

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  String selectedCategory = 'All';
  bool isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notesService = Provider.of<NotesService>(context, listen: false);
    
    if (authService.token != null) {
      await notesService.fetchNotes(authService.token!);
    }
  }

  List<String> get categories {
    final notesService = Provider.of<NotesService>(context);
    final cats = notesService.notes.map((n) => n.category).toSet().toList();
    return ['All', ...cats];
  }

  List<Note> get filteredNotes {
    final notesService = Provider.of<NotesService>(context);
    if (selectedCategory == 'All') return notesService.notes;
    return notesService.notes.where((n) => n.category == selectedCategory).toList();
  }

  void _addNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteEditorPage(),
      ),
    );
  }

  void _editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
    );
  }

  Future<void> _deleteNote(Note note) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notesService = Provider.of<NotesService>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && authService.token != null && note.id != null) {
      await notesService.deleteNote(authService.token!, note.id!);
    }
  }

  Future<void> _toggleFavorite(Note note) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notesService = Provider.of<NotesService>(context, listen: false);
    
    if (authService.token != null && note.id != null) {
      await notesService.toggleFavorite(authService.token!, note);
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notesService = Provider.of<NotesService>(context, listen: false);
    
    notesService.clearNotes();
    await authService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final notesService = Provider.of<NotesService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Notes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Hello, ${authService.currentUser?.name ?? "User"}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notesService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoryFilter(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadNotes,
                    child: filteredNotes.isEmpty
                        ? _buildEmptyState()
                        : isGridView
                            ? _buildGridView()
                            : _buildListView(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
        elevation: 4,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_add_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No notes yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to create your first note',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _editNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                note.color.withOpacity(0.05),
                note.color.withOpacity(0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: note.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isFavorite ? Icons.star : Icons.star_border,
                      color: note.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () => _toggleFavorite(note),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: isGridView ? 6 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: note.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      note.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: note.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteNote(note);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}