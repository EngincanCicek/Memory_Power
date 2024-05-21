import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'note.dart';
import 'note_database.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NoteDetailPage extends StatefulWidget {
  final Note note;

  NoteDetailPage({required this.note});

  @override
  _NoteDetailPageState createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  bool _isEditMode = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Note _currentNote;
  bool _isImagePickerActive = false;
  bool _useTurkishFont = false; // Türkçe font seçimi için eklenen değişken

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _descriptionController = TextEditingController(text: widget.note.description);
    _currentNote = widget.note;
  }

  Future<void> _pickImage() async {
    if (_isImagePickerActive) return;
    _isImagePickerActive = true;

    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          List<String> imagePaths = _currentNote.imagePath != null
              ? _currentNote.imagePath!.split(',').toList()
              : [];
          imagePaths.add(pickedFile.path);
          _currentNote = _currentNote.copyWith(imagePath: imagePaths.join(','));
          NoteDatabase.instance.update(_currentNote);
        });
      }
    } finally {
      _isImagePickerActive = false;
    }
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

  void _removeImage(int index) {
    setState(() {
      List<String> imagePaths = _currentNote.imagePath!.split(',').toList();
      imagePaths.removeAt(index);
      _currentNote = _currentNote.copyWith(imagePath: imagePaths.join(','));
      NoteDatabase.instance.update(_currentNote);
    });
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditMode) {
        _saveChanges();
      }
      _isEditMode = !_isEditMode;
    });
  }

  void _saveChanges() async {
    _currentNote = _currentNote.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
    );
    await NoteDatabase.instance.update(_currentNote);
  }

  Future<String> askQuestion(String text) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_API_KEY_HERE', // Geçerli API anahtarınızı burada kullanın
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': 'Lütfen aşağıdaki metne dayalı olarak bilgi sorusu oluştur: $text'},
        ],
        'max_tokens': 100,
        'temperature': 0.5,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      String question = data['choices'][0]['message']['content'].trim();
      // Gereksiz ifadeleri kaldır
      if (question.contains('bilgi sorusu oluşturabilirsiniz')) {
        question = question.replaceAll(RegExp(r'bilgi sorusu oluşturabilirsiniz\.*'), '').trim();
      }
      return question;
    } else {
      print('Failed response: ${response.body}');
      throw Exception('Failed to generate question');
    }
  }

  void _showQuestionDialog(String question) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sorunuz'),
          content: Text(question),
          actions: [
            TextButton(
              child: Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Soru oluşturuluyor..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void _askQuestion() async {
    try {
      _showLoadingDialog();
      final text = _currentNote.description;
      final question = await askQuestion(text);
      Navigator.of(context).pop(); // Loading dialogunu kapat
      _showQuestionDialog(question);
    } catch (e) {
      Navigator.of(context).pop(); // Loading dialogunu kapat
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Soru oluşturma işlemi başarısız oldu. Lütfen tekrar deneyin.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> imagePaths = _currentNote.imagePath?.split(',').toList() ?? [];
    imagePaths.removeWhere((path) => !File(path).existsSync());

    TextStyle defaultTextStyle = TextStyle(fontSize: 16, color: Colors.teal[800]);
    TextStyle turkishFontStyle = TextStyle(fontSize: 16, color: Colors.teal[800], fontFamily: 'NotoSerif'); // Türkçe font stili

    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
            ? TextField(
          controller: _titleController,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Başlık',
            border: InputBorder.none,
          ),
        )
            : Text(_currentNote.title, style: TextStyle(fontSize: 26)),
        backgroundColor: Colors.teal,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _toggleEditMode,
            ),
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'edit') {
                _toggleEditMode();
              } else if (result == 'delete') {
                _showDeleteConfirmationDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Text(_isEditMode ? 'Düzenlemeyi Bitir' : 'Düzenle'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Sil'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEditMode)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentNote.title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[900],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _currentNote.description,
                            style: _useTurkishFont ? turkishFontStyle : defaultTextStyle, // Türkçe font kullanımı
                          ),
                        ],
                      ),
                    if (_isEditMode)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[900],
                            ),
                            decoration: InputDecoration(
                              hintText: 'Başlık',
                              border: InputBorder.none,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _descriptionController,
                            style: TextStyle(fontSize: 16, color: Colors.teal[800]), // Font boyutunu küçülttüm
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Açıklama',
                              border: InputBorder.none,
                            ),
                          ),
                          SwitchListTile(
                            title: Text('Türkçe Font Kullan'),
                            value: _useTurkishFont,
                            onChanged: (bool value) {
                              setState(() {
                                _useTurkishFont = value;
                              });
                            },
                          ),
                        ],
                      ),
                    SizedBox(height: 16),
                    if (imagePaths.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: imagePaths.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _showImageDialog(imagePaths[index]);
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
                                    child: Image.file(
                                      File(imagePaths[index]),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                                if (_isEditMode)
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
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // "Soru Sor" butonunu ortaladım
              children: [
                ElevatedButton(
                  onPressed: _askQuestion,
                  child: Text('Soru Sor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_isEditMode)
                  SizedBox(width: 16), // Boşluk ekledim
                if (_isEditMode)
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.image),
                    label: Text('Resim Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: Size(150, 50),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                await NoteDatabase.instance.delete(widget.note.id!);
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
