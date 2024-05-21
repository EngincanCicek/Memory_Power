class NoteFields {
  static final List<String> values = [
    id, title, description, imagePath, isImportant
  ];

  static const String id = 'id';
  static const String title = 'title';
  static const String description = 'description';
  static const String imagePath = 'imagePath';
  static const String isImportant = 'isImportant';
}

class Note {
  final int? id;
  final String title;
  final String description;
  final String? imagePath;
  final bool isImportant;

  Note({
    this.id,
    required this.title,
    required this.description,
    this.imagePath,
    this.isImportant = false,
  });

  Note copyWith({
    int? id,
    String? title,
    String? description,
    String? imagePath,
    bool? isImportant,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      NoteFields.id: id,
      NoteFields.title: title,
      NoteFields.description: description,
      NoteFields.imagePath: imagePath,
      NoteFields.isImportant: isImportant ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map[NoteFields.id] as int?,
      title: map[NoteFields.title] as String,
      description: map[NoteFields.description] as String,
      imagePath: map[NoteFields.imagePath] as String?,
      isImportant: map[NoteFields.isImportant] == 1,
    );
  }
}