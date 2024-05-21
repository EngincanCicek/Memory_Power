import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  List<String> _imagePaths = [];
  bool _isImportant = false;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  bool _isTitleFocused = false;
  bool _isDescriptionFocused = false;
  int _selectedImageIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _title = widget.note!.title;
      _description = widget.note!.description;
      _imagePaths = widget.note!.imagePath != null
          ? widget.note!.imagePath!.split(',').toList()
          : [];
      _isImportant = widget.note!.isImportant;
    } else {
      _title = '';
      _description = '';
    }

    _titleFocusNode.addListener(() {
      setState(() {
        _isTitleFocused = _titleFocusNode.hasFocus;
      });
    });

    _descriptionFocusNode.addListener(() {
      setState(() {
        _isDescriptionFocused = _descriptionFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(8.0),
            child: InteractiveViewer(
              panEnabled: false,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.file(File(imagePath)),
            ),
          ),
        );
      },
    );
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newNote = Note(
        id: widget.note?.id,
        title: _title,
        description: _description,
        imagePath: _imagePaths.join(','),
        isImportant: _isImportant,
      );
      if (widget.note == null) {
        await NoteDatabase.instance.create(newNote);
      } else {
        await NoteDatabase.instance.update(newNote);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Yeni Not' : 'Notu Düzenle'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.teal[50],
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(_isTitleFocused ? 12.0 : 8.0),
                  decoration: BoxDecoration(
                    color: _isTitleFocused ? Colors.teal[100] : Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: _isTitleFocused
                        ? [BoxShadow(color: Colors.teal, blurRadius: 10.0)]
                        : [],
                  ),
                  child: TextFormField(
                    focusNode: _titleFocusNode,
                    initialValue: _title,
                    style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Başlık',
                      labelStyle: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                    ),
                    cursorColor: Colors.teal,
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
                ),
                SizedBox(height: 16.0),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(_isDescriptionFocused ? 12.0 : 8.0),
                  decoration: BoxDecoration(
                    color: _isDescriptionFocused ? Colors.teal[100] : Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: _isDescriptionFocused
                        ? [BoxShadow(color: Colors.teal, blurRadius: 10.0)]
                        : [],
                  ),
                  child: TextFormField(
                    focusNode: _descriptionFocusNode,
                    initialValue: _description,
                    style: TextStyle(color: Colors.teal[900]),
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      labelStyle: TextStyle(color: Colors.teal),
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    cursorColor: Colors.teal,
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
                ),
                SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: _isImportant,
                      onChanged: (value) {
                        setState(() {
                          _isImportant = value!;
                        });
                      },
                    ),
                    Text(
                      'Önemli',
                      style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.teal, width: 2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: _imagePaths[index] != null && _imagePaths[index]!.isNotEmpty
                                  ? Image.file(
                                File(_imagePaths[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                                  : Container(), // Placeholder if image path is invalid
                            ),
                          ),
                          if (_selectedImageIndex == index)
                            Positioned(
                              top: 8.0,
                              right: 8.0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text('Resim Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  ),
                  child: Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
