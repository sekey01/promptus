class Expense {
  int? id;
  String title;
  String description;
  double amount;
  String category;
  DateTime createdAt;
  int priority; // 1 = Low, 2 = Medium, 3 = High

  Expense({
    this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.createdAt,
    this.priority = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'priority': priority,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      priority: map['priority'],
    );
  }

  @override
  String toString() {
    return 'Expense{id: $id, title: $title, amount: $amount, category: $category}';
  }
}