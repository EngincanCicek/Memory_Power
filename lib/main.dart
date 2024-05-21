import 'package:flutter/material.dart';

import 'note.dart';
import 'note_database.dart';
import 'note_detail_page.dart';
import 'note_edit_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Not Defteri',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NoteListPage(),
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
        title: Text('Notlar'),
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
            return GridView.count(
              crossAxisCount: 2,
              children: List.generate(snapshot.data!.length, (index) {
                final note = snapshot.data![index];
                Color backgroundColor;
                switch (index % 5) {
                  case 0:
                    backgroundColor = Color(0xFF8A5CC5); // Mor
                    break;
                  case 1:
                    backgroundColor = Color(0xFFFFFFFF); // Beyaz
                    break;
                  case 2:
                    backgroundColor = Color(0xFF60D889); // Yeşil
                    break;
                  case 3:
                    backgroundColor = Color(0xFFDEDC52); // Sarı
                    break;
                  case 4:
                    backgroundColor = Color(0xFFCE3A54); // Kırmızı
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
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
        backgroundColor: Color(0xFF8A5CC5), // 8A5CC5 rengi

      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
