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

  GuestItem copyWith({
    String? id,
    String? name,
    String? phone,
    String? side,
    bool? mealConfirmed,
    bool? attended,
  }) {
    return GuestItem(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      side: side ?? this.side,
      mealConfirmed: mealConfirmed ?? this.mealConfirmed,
      attended: attended ?? this.attended,
    );
  }
}
