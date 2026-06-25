enum PreparationStatus {
  none,
  inProgress,
  done;

  String get displayName {
    switch (this) {
      case PreparationStatus.none:
        return '미시작';
      case PreparationStatus.inProgress:
        return '진행중';
      case PreparationStatus.done:
        return '완료';
    }
  }
}

class CategorySchedule {
  final String id;
  final DateTime date;
  final String title;
  final int reminderDays; // 1, 3, 7 등

  CategorySchedule({
    required this.id,
    required this.date,
    required this.title,
    required this.reminderDays,
  });

  factory CategorySchedule.fromMap(Map<String, dynamic> map) {
    return CategorySchedule(
      id: map['id'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      title: map['title'] as String? ?? '',
      reminderDays: map['reminderDays'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'reminderDays': reminderDays,
    };
  }
}

class CategoryPhoto {
  final String url;
  final String caption;
  final String uploadedBy;
  final DateTime uploadedAt;

  CategoryPhoto({
    required this.url,
    required this.caption,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory CategoryPhoto.fromMap(Map<String, dynamic> map) {
    return CategoryPhoto(
      url: map['url'] as String? ?? '',
      caption: map['caption'] as String? ?? '',
      uploadedBy: map['uploadedBy'] as String? ?? '',
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'caption': caption,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class WeddingCategory {
  final String id;
  final String name;
  final String groupName; // '식장 & 의식' | '스타일 & 뷰티' | '초대 & 감사' | '양가 행사' | '신혼 준비'
  final PreparationStatus status;
  final int estimatedCost;
  final int actualCost;
  final String notes;
  final String vendorName;
  final String vendorPhone;
  final List<CategorySchedule> schedules;
  final List<CategoryPhoto> photos;
  final String updatedBy;
  final DateTime updatedAt;

  WeddingCategory({
    required this.id,
    required this.name,
    required this.groupName,
    required this.status,
    required this.estimatedCost,
    required this.actualCost,
    required this.notes,
    required this.vendorName,
    required this.vendorPhone,
    required this.schedules,
    required this.photos,
    required this.updatedBy,
    required this.updatedAt,
  });

  factory WeddingCategory.fromMap(Map<String, dynamic> map, String id) {
    return WeddingCategory(
      id: id,
      name: map['name'] as String? ?? '',
      groupName: map['groupName'] as String? ?? '',
      status: PreparationStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'none'),
        orElse: () => PreparationStatus.none,
      ),
      estimatedCost: map['estimatedCost'] as int? ?? 0,
      actualCost: map['actualCost'] as int? ?? 0,
      notes: map['notes'] as String? ?? '',
      vendorName: map['vendorName'] as String? ?? '',
      vendorPhone: map['vendorPhone'] as String? ?? '',
      schedules: (map['schedules'] as List<dynamic>?)
              ?.map((s) => CategorySchedule.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      photos: (map['photos'] as List<dynamic>?)
              ?.map((p) => CategoryPhoto.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      updatedBy: map['updatedBy'] as String? ?? '',
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'groupName': groupName,
      'status': status.name,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'notes': notes,
      'vendorName': vendorName,
      'vendorPhone': vendorPhone,
      'schedules': schedules.map((s) => s.toMap()).toList(),
      'photos': photos.map((p) => p.toMap()).toList(),
      'updatedBy': updatedBy,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WeddingCategory copyWith({
    PreparationStatus? status,
    int? estimatedCost,
    int? actualCost,
    String? notes,
    String? vendorName,
    String? vendorPhone,
    List<CategorySchedule>? schedules,
    List<CategoryPhoto>? photos,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return WeddingCategory(
      id: id,
      name: name,
      groupName: groupName,
      status: status ?? this.status,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      notes: notes ?? this.notes,
      vendorName: vendorName ?? this.vendorName,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      schedules: schedules ?? this.schedules,
      photos: photos ?? this.photos,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
