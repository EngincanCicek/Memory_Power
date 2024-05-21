import 'package:flutter/material.dart';

import 'note.dart';
import 'note_database.dart';

class NoteEditPage extends StatefulWidget {
  final Note? note;

  NoteEditPage({this.note});

  @override
  _NoteEditPageState createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _title = widget.note!.title;
      _description = widget.note!.description;
    } else {
      _title = '';
      _description = '';
    }
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Yeni Not' : 'Notu Düzenle'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Başlık'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen başlık girin';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              SizedBox(height: 8.0),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Açıklama'),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                focusNode: _descriptionFocusNode,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen açıklama girin';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              SizedBox(height: 16.0), // Boşluk eklendi
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    onPressed: () async {
                      _descriptionFocusNode.unfocus(); // Klavyeyi kapat
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        final newNote = Note(
                          id: widget.note?.id,
                          title: _title,
                          description: _description,
                        );
                        if (widget.note == null) {
                          await NoteDatabase.instance.create(newNote);
                        } else {
                          await NoteDatabase.instance.update(newNote);
                        }
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Kaydet'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
