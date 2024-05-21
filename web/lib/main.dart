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

  @override
  void initState() {
    super.initState();
    notes = NoteDatabase.instance.readAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Image.asset(
            'assets/note_app_logo_transparent.png', // Logo dosyanızın yolunu buraya ekleyin
            height: 40,
          ),
        ),
        backgroundColor: Colors.teal,
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
            // Önemli notları en üste almak için sıralama
            List<Note> sortedNotes = snapshot.data!;
            sortedNotes.sort((a, b) => b.isImportant.compareTo(a.isImportant));

            return GridView.count(
              crossAxisCount: 2,
              children: List.generate(sortedNotes.length, (index) {
                final note = sortedNotes[index];
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
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => NoteDetailPage(note: note),
                    ));
                    setState(() {
                      notes = NoteDatabase.instance.readAll();
                    });
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    color: backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 8.0), // Yıldız simgesi ile metin arasında boşluk
                              Text(
                                note.title,
                                style: TextStyle(
                                  fontSize: 18,
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
                                  fontSize: 16,
                                  color: Colors.teal[800],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (note.isImportant) // Önemli notlar için yıldız simgesi ekleme
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
