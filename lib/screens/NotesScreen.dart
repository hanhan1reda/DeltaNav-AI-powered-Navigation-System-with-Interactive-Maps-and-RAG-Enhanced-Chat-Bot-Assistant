import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  static const Color primaryColor = Color(0xFF1E88E5); // Blue
  static const Color accentColor = Color(0xFFFF6D00); // Orange

  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isAddingNote = false;
  bool _isHighPriority = false;
  late AnimationController _animationController;
  late Animation<double> _fabScaleAnimation;

  final List<String> _categories = ['General', 'Work', 'Personal', 'Study'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutBack),
    );
    _animationController.repeat(reverse: true);
    _loadNotes();
    _searchController.addListener(_filterNotes);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesString = prefs.getString('notes');
    if (notesString != null) {
      setState(() {
        _notes = List<Map<String, dynamic>>.from(jsonDecode(notesString));
        _filteredNotes = _notes;
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(_notes));
    _filterNotes();
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        return note['content'].toLowerCase().contains(query) ||
            note['category'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addNote() {
    if (_noteController.text.trim().isNotEmpty) {
      setState(() {
        _notes.add({
          'content': _noteController.text.trim(),
          'category': _selectedCategory,
          'timestamp': DateTime.now().toIso8601String(),
          'isHighPriority': _isHighPriority,
        });
        _noteController.clear();
        _isAddingNote = false;
        _isHighPriority = false;
        _selectedCategory = 'General';
      });
      _saveNotes();
    }
  }

  void _editNote(int index) {
    _noteController.text = _notes[index]['content'];
    _selectedCategory = _notes[index]['category'];
    _isHighPriority = _notes[index]['isHighPriority'];
    setState(() {
      _isAddingNote = true;
    });
    showDialog(
      context: context,
      builder: (context) => _buildNoteDialog(
        title: "Edit Note",
        onSave: () {
          setState(() {
            _notes[index] = {
              'content': _noteController.text.trim(),
              'category': _selectedCategory,
              'timestamp': DateTime.now().toIso8601String(),
              'isHighPriority': _isHighPriority,
            };
            _noteController.clear();
            _isAddingNote = false;
            _isHighPriority = false;
            _selectedCategory = 'General';
          });
          _saveNotes();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Note deleted",
          style: TextStyle(fontFamily: 'Zain', color: Colors.white),
        ),
        backgroundColor: NotesScreen.primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportNotes() {
    final notesJson = jsonEncode(_notes);
    Clipboard.setData(ClipboardData(text: notesJson));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Notes copied to clipboard!",
          style: TextStyle(fontFamily: 'Zain', color: Colors.white),
        ),
        backgroundColor: NotesScreen.primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildNoteDialog({required String title, required VoidCallback onSave}) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.grey[100]!.withOpacity(0.95),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: NotesScreen.accentColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [NotesScreen.primaryColor, NotesScreen.accentColor],
              ).createShader(bounds),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Zain',
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter your note...",
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Zain',
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(
                fontSize: 16,
                color: NotesScreen.primaryColor,
                fontFamily: 'Zain',
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Category",
                labelStyle: TextStyle(
                  color: NotesScreen.primaryColor,
                  fontFamily: 'Zain',
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(fontFamily: 'Zain', color: NotesScreen.primaryColor),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isHighPriority,
                  onChanged: (value) {
                    setState(() {
                      _isHighPriority = value!;
                    });
                  },
                  activeColor: NotesScreen.accentColor,
                ),
                Text(
                  "High Priority",
                  style: TextStyle(
                    fontSize: 16,
                    color: NotesScreen.primaryColor,
                    fontFamily: 'Zain',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _noteController.clear();
                    setState(() {
                      _isAddingNote = false;
                      _isHighPriority = false;
                      _selectedCategory = 'General';
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                      color: NotesScreen.primaryColor,
                      fontFamily: 'Zain',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onSave,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NotesScreen.primaryColor,
                            NotesScreen.accentColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: NotesScreen.accentColor.withOpacity(0.4),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'Zain',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        primaryColor: NotesScreen.primaryColor,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Background Image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/delta2.jpg"),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.15),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NotesScreen.primaryColor.withOpacity(0.6),
                      NotesScreen.accentColor.withOpacity(0.5),
                      Colors.black.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [NotesScreen.primaryColor, NotesScreen.accentColor],
                          ).createShader(bounds),
                          child: Text(
                            "Your Notes",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Zain',
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: NotesScreen.accentColor.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _exportNotes,
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.7),
                                    boxShadow: [
                                      BoxShadow(
                                        color: NotesScreen.accentColor.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.share,
                                    color: NotesScreen.primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.7),
                                    boxShadow: [
                                      BoxShadow(
                                        color: NotesScreen.accentColor.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: NotesScreen.primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search notes...",
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Zain',
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: NotesScreen.primaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ),
                      style: TextStyle(
                        fontFamily: 'Zain',
                        color: NotesScreen.primaryColor,
                      ),
                    ),
                  ),
                  // Notes List
                  Expanded(
                    child: _filteredNotes.isEmpty
                        ? Center(
                            child: Text(
                              "No notes found. Add your first note!",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[800],
                                fontFamily: 'Zain',
                                height: 1.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            itemCount: _filteredNotes.length,
                            itemBuilder: (context, index) {
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  final animation = CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      index * 0.1,
                                      1.0,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset(0.5, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: Dismissible(
                                        key: Key(_filteredNotes[index]['content'] + index.toString()),
                                        direction: DismissDirection.endToStart,
                                        onDismissed: (direction) {
                                          _deleteNote(_notes.indexOf(_filteredNotes[index]));
                                        },
                                        background: Container(
                                          margin: EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.only(right: 20),
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                        ),
                                        child: GestureDetector(
                                          onTap: () => _editNote(_notes.indexOf(_filteredNotes[index])),
                                          child: Container(
                                            margin: EdgeInsets.symmetric(vertical: 8),
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.9),
                                                  _filteredNotes[index]['isHighPriority']
                                                      ? NotesScreen.accentColor.withOpacity(0.3)
                                                      : Colors.grey[100]!.withOpacity(0.9),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.15),
                                                  blurRadius: 15,
                                                  offset: Offset(4, 4),
                                                  spreadRadius: 1,
                                                ),
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(0.5),
                                                  blurRadius: 15,
                                                  offset: Offset(-4, -4),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: _filteredNotes[index]['isHighPriority']
                                                    ? NotesScreen.accentColor.withOpacity(0.5)
                                                    : Colors.white.withOpacity(0.2),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        _filteredNotes[index]['content'],
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: NotesScreen.primaryColor,
                                                          fontFamily: 'Zain',
                                                          height: 1.5,
                                                          letterSpacing: 0.5,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (_filteredNotes[index]['isHighPriority'])
                                                      Icon(
                                                        Icons.star,
                                                        color: NotesScreen.accentColor,
                                                        size: 20,
                                                      ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      _filteredNotes[index]['category'],
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: NotesScreen.primaryColor.withOpacity(0.7),
                                                        fontFamily: 'Zain',
                                                      ),
                                                    ),
                                                    Text(
                                                      DateFormat('MMM d, yyyy HH:mm').format(
                                                        DateTime.parse(_filteredNotes[index]['timestamp']),
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontFamily: 'Zain',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  // Copyright Notice
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "© 2025 Delta University for Science and Technology",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Zain',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: ScaleTransition(
          scale: _fabScaleAnimation,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _isAddingNote = true;
                _noteController.clear();
                _isHighPriority = false;
                _selectedCategory = 'General';
              });
              showDialog(
                context: context,
                builder: (context) => _buildNoteDialog(
                  title: "Add Note",
                  onSave: () {
                    _addNote();
                    Navigator.pop(context);
                  },
                ),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [NotesScreen.primaryColor, NotesScreen.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NotesScreen.accentColor.withOpacity(0.5),
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}