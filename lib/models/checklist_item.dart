class TimelineChecklistItem {
  final String id;
  final String phase; // 'D-6m' | 'D-5m' | 'D-3m' | 'D-1m' | 'D-2w'
  final String title;
  final bool isDone;
  final String? linkedCategoryId; // 카테고리 연동 아이디 (예: 'wedding_hall', 'photographer' 등)
  final String createdBy;

  TimelineChecklistItem({
    required this.id,
    required this.phase,
    required this.title,
    required this.isDone,
    this.linkedCategoryId,
    required this.createdBy,
  });

  factory TimelineChecklistItem.fromMap(Map<String, dynamic> map, String id) {
    return TimelineChecklistItem(
      id: id,
      phase: map['phase'] as String? ?? 'D-6m',
      title: map['title'] as String? ?? '',
      isDone: map['isDone'] as bool? ?? false,
      linkedCategoryId: map['linkedCategoryId'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase,
      'title': title,
      'isDone': isDone,
      'linkedCategoryId': linkedCategoryId,
      'createdBy': createdBy,
    };
  }

  TimelineChecklistItem copyWith({
    bool? isDone,
    String? title,
  }) {
    return TimelineChecklistItem(
      id: id,
      phase: phase,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      linkedCategoryId: linkedCategoryId,
      createdBy: createdBy,
    );
  }
}

class GuestItem {
  final String id;
  final String name;
  final String phone;
  final String side; // 'groom' (신랑측) | 'bride' (신부측)
  final bool mealConfirmed;
  final bool attended;

  GuestItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.side,
    required this.mealConfirmed,
    required this.attended,
  });

  factory GuestItem.fromMap(Map<String, dynamic> map, String id) {
    return GuestItem(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      side: map['side'] as String? ?? 'groom',
      mealConfirmed: map['mealConfirmed'] as bool? ?? false,
      attended: map['attended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'side': side,
      'mealConfirmed': mealConfirmed,
      'attended': attended,
    };
  }
}
