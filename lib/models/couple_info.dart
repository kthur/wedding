class CoupleInfo {
  final String? maleUid;
  final String? femaleUid;
  final DateTime? weddingDate;
  final int budgetGoal;

  CoupleInfo({
    this.maleUid,
    this.femaleUid,
    this.weddingDate,
    required this.budgetGoal,
  });

  factory CoupleInfo.fromMap(Map<String, dynamic> map) {
    return CoupleInfo(
      maleUid: map['maleUid'] as String?,
      femaleUid: map['femaleUid'] as String?,
      weddingDate: map['weddingDate'] != null 
          ? DateTime.parse(map['weddingDate'] as String) 
          : null,
      budgetGoal: map['budgetGoal'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maleUid': maleUid,
      'femaleUid': femaleUid,
      'weddingDate': weddingDate?.toIso8601String(),
      'budgetGoal': budgetGoal,
    };
  }
}

class UserProfile {
  final String uid;
  final String name;
  final String gender; // 'male' | 'female'
  final String? coupleId;
  final String inviteCode;

  UserProfile({
    required this.uid,
    required this.name,
    required this.gender,
    this.coupleId,
    required this.inviteCode,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      gender: map['gender'] as String? ?? 'male',
      coupleId: map['coupleId'] as String?,
      inviteCode: map['inviteCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'coupleId': coupleId,
      'inviteCode': inviteCode,
    };
  }
}
