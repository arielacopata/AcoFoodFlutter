class UserPreferences {
  final bool b12Checked;
  final bool linoChecked;
  final bool legumbresChecked;
  final bool yodoChecked;
  final String sortOrder;
  final List<int> enabledHabitIds;

  UserPreferences({
    required this.b12Checked,
    required this.linoChecked,
    required this.legumbresChecked,
    required this.yodoChecked,
    required this.sortOrder,
    required this.enabledHabitIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'b12Checked': b12Checked,
      'linoChecked': linoChecked,
      'legumbresChecked': legumbresChecked,
      'yodoChecked': yodoChecked,
      'sortOrder': sortOrder,
      'enabledHabitIds': enabledHabitIds,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      b12Checked: map['b12Checked'] ?? false,
      linoChecked: map['linoChecked'] ?? false,
      legumbresChecked: map['legumbresChecked'] ?? false,
      yodoChecked: map['yodoChecked'] ?? true,
      sortOrder: map['sortOrder'] ?? 'alfabetico',
      enabledHabitIds: List<int>.from(
        map['enabledHabitIds'] ?? [1, 2, 3, 4, 5],
      ),
    );
  }
}
