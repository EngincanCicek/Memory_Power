import 'package:flutter/material.dart';
import 'note.dart';
import 'note_database.dart';
import 'note_edit_page.dart';

class NoteDetailPage extends StatelessWidget {
  final Note note;

  NoteDetailPage({required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              note.description,
              style: TextStyle(fontSize: 18),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => NoteEditPage(note: note),
                    ));
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Düzenle'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(context),
                  icon: Icon(Icons.delete),
                  label: Text('Sil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notu Sil'),
          content: Text('Bu notu silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Sil'),
              onPressed: () async {
                await NoteDatabase.instance.delete(note.id!);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
