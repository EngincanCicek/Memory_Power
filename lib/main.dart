import 'package:flutter/material.dart';
import 'note.dart';
import 'note_database.dart';
import 'note_detail_page.dart';
import 'note_edit_page.dart';
import 'splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Not Defteri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.teal[50],
      ),
      home: SplashScreen(), // SplashScreen'i giriş ekranı olarak belirledik
    );
  }
}

class NoteListPage extends StatefulWidget {
  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  late Future<List<Note>> notes;
  bool _selectionMode = false;
  List<int> _selectedNotes = [];

  @override
  void initState() {
    super.initState();
    notes = NoteDatabase.instance.readAll();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedNotes.clear();
    });
  }

  void _toggleNoteSelection(int id) {
    setState(() {
      if (_selectedNotes.contains(id)) {
        _selectedNotes.remove(id);
      } else {
        _selectedNotes.add(id);
      }
    });
  }

  void _deleteSelectedNotes() async {
    for (var id in _selectedNotes) {
      await NoteDatabase.instance.delete(id);
    }
    setState(() {
      notes = NoteDatabase.instance.readAll();
      _selectionMode = false;
      _selectedNotes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notlar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _selectedNotes.isEmpty ? null : _deleteSelectedNotes,
            ),
          IconButton(
            icon: Icon(_selectionMode ? Icons.close : Icons.select_all),
            onPressed: _toggleSelectionMode,
          ),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: notes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Henüz not yok'));
          } else {
            List<Note> sortedNotes = snapshot.data!;
            sortedNotes.sort((a, b) => b.isImportant ? 1 : -1);

            return GridView.count(
              crossAxisCount: 2,
              children: List.generate(sortedNotes.length, (index) {
                final note = sortedNotes[index];
                bool isSelected = _selectedNotes.contains(note.id!);
                Color backgroundColor;
                switch (index % 5) {
                  case 0:
                    backgroundColor = Color(0xFFFFF59D); // Açık sarı
                    break;
                  case 1:
                    backgroundColor = Color(0xFFA5D6A7); // Açık yeşil
                    break;
                  case 2:
                    backgroundColor = Color(0xFF90CAF9); // Açık mavi
                    break;
                  case 3:
                    backgroundColor = Color(0xFFFFAB91); // Açık turuncu
                    break;
                  case 4:
                    backgroundColor = Color(0xFFCE93D8); // Açık mor
                    break;
                  default:
                    backgroundColor = Colors.white;
                }
                return GestureDetector(
                  onTap: _selectionMode
                      ? () => _toggleNoteSelection(note.id!)
                      : () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => NoteDetailPage(note: note),
                    ));
                    setState(() {
                      notes = NoteDatabase.instance.readAll();
                    });
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    color: backgroundColor, // Renk değiştirme kaldırıldı
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  note.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[900],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  note.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.teal[800],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (note.imagePath != null && note.imagePath!.isNotEmpty)
                          Positioned(
                            bottom: 8.0,
                            left: 8.0,
                            child: Icon(
                              Icons.photo,
                              color: Colors.black45,
                            ),
                          ),
                        if (_selectionMode)
                          Positioned(
                            top: 4.0, // Yıldız simgesiyle aynı hizaya getirmek için ayarlandı
                            left: 4.0,
                            child: Transform.scale(
                              scale: 1.2, // Checkbox boyutunu biraz daha büyüt
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  _toggleNoteSelection(note.id!);
                                },
                              ),
                            ),
                          ),
                        if (note.isImportant)
                          Positioned(
                            top: 8.0,
                            right: 8.0,
                            child: Icon(
                              Icons.star,
                              color: Colors.yellow[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => NoteEditPage(),
          ));
          setState(() {
            notes = NoteDatabase.instance.readAll();
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}