class NoteFolder {
  int? id;
  String name;
  int colorValue;
  DateTime createdAt;

  NoteFolder({
    this.id,
    required this.name,
    this.colorValue = 0xFF6366F1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory NoteFolder.fromMap(Map<String, dynamic> m) => NoteFolder(
        id: m['id'],
        name: m['name'],
        colorValue: m['colorValue'] ?? 0xFF6366F1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
      );
}

class Note {
  int? id;
  int? folderId; // null = General
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? reminderTime;
  bool isPinned;

  Note({
    this.id,
    this.folderId,
    required this.title,
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.reminderTime,
    this.isPinned = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'folderId': folderId,
        'title': title,
        'content': content,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'reminderTime': reminderTime?.millisecondsSinceEpoch,
        'isPinned': isPinned ? 1 : 0,
      };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'],
        folderId: m['folderId'],
        title: m['title'],
        content: m['content'] ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt']),
        reminderTime: m['reminderTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['reminderTime'])
            : null,
        isPinned: m['isPinned'] == 1,
      );
}
