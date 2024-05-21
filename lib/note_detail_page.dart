import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'note.dart';
import 'note_database.dart';
import 'dart:io';

class NoteDetailPage extends StatefulWidget {
  final Note note;

  NoteDetailPage({required this.note});

  @override
  _NoteDetailPageState createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  bool _isEditMode = false; // Düzenleme modunu kontrol eden değişken
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Note _currentNote;
  bool _isImagePickerActive = false; // ImagePicker'ın aktif olup olmadığını kontrol eden değişken

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _descriptionController = TextEditingController(text: widget.note.description);
    _currentNote = widget.note;
  }

  Future<void> _pickImage() async {
    if (_isImagePickerActive) return; // Eğer ImagePicker zaten aktifse yeni bir işlem başlatma
    _isImagePickerActive = true; // ImagePicker'ın aktif olduğunu işaretle

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
      _isImagePickerActive = false; // İşlem tamamlandığında ImagePicker'ın aktif olmadığını işaretle
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
      // Resim kaldırma işlemi
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

  @override
  Widget build(BuildContext context) {
    List<String> imagePaths = _currentNote.imagePath?.split(',').toList() ?? [];
    // Geçersiz dosya yollarını kaldırma
    imagePaths.removeWhere((path) => !File(path).existsSync());

    return Scaffold(
      appBar: AppBar(
        title: _isEditMode
            ? TextField(
          controller: _titleController,
          style: TextStyle(
            fontSize: 26, // Başlık yazısının boyutunu büyüttük
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Başlık',
            border: InputBorder.none,
          ),
        )
            : Text(_currentNote.title, style: TextStyle(fontSize: 26)), // Başlık yazısının boyutunu büyüttük
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
                  crossAxisAlignment: CrossAxisAlignment.start, // Başlık ve açıklama sola yaslı
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
                            style: TextStyle(fontSize: 18, color: Colors.teal[800]),
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
                            style: TextStyle(fontSize: 18, color: Colors.teal[800]),
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Açıklama',
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 16),
                    if (imagePaths.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Görselleri kare olarak düzenle
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
                                      fit: BoxFit.cover, // Görsellerin boşluk kalmadan sığması için cover kullanıldı
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
          if (_isEditMode || imagePaths.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Resim Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50), // Butonun genişliğini ayarla
                ),
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
