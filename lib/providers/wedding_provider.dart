import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/couple_info.dart';
import '../models/wedding_category.dart';
import '../models/checklist_item.dart';

// 로컬 테스트(Firebase Mock용) 상태 관리 프로바이더
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class WeddingState {
  final UserProfile? currentUser;
  final CoupleInfo? coupleInfo;
  final List<WeddingCategory> categories;
  final List<TimelineChecklistItem> timelineChecklist;
  final List<GuestItem> guests;
  final List<String> customChecklist;
  final List<Map<String, dynamic>> memos;
  final bool isLoading;

  WeddingState({
    this.currentUser,
    this.coupleInfo,
    this.categories = const [],
    this.timelineChecklist = const [],
    this.guests = const [],
    this.customChecklist = const [],
    this.memos = const [],
    this.isLoading = false,
  });

  WeddingState copyWith({
    UserProfile? currentUser,
    CoupleInfo? coupleInfo,
    List<WeddingCategory>? categories,
    List<TimelineChecklistItem>? timelineChecklist,
    List<GuestItem>? guests,
    List<String>? customChecklist,
    List<Map<String, dynamic>>? memos,
    bool? isLoading,
  }) {
    return WeddingState(
      currentUser: currentUser ?? this.currentUser,
      coupleInfo: coupleInfo ?? this.coupleInfo,
      categories: categories ?? this.categories,
      timelineChecklist: timelineChecklist ?? this.timelineChecklist,
      guests: guests ?? this.guests,
      customChecklist: customChecklist ?? this.customChecklist,
      memos: memos ?? this.memos,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WeddingNotifier extends StateNotifier<WeddingState> {
  final SharedPreferences _prefs;
  final List<StreamSubscription> _subscriptions = [];

  WeddingNotifier(this._prefs) : super(WeddingState()) {
    _initLocalData();
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  // 기본 시기별 체크리스트 목록 정의
  final List<Map<String, String>> _defaultTimelineTasks = [
    // D-6m
    {'phase': 'D-6m', 'title': '양가 상견례 일정 조율 및 예약', 'linked': '상견례'},
    {'phase': 'D-6m', 'title': '결혼 전체 예산 수립 및 분담 논의', 'linked': '웨딩 플래너'},
    {'phase': 'D-6m', 'title': '웨딩홀(베뉴) 투어 및 최종 계약', 'linked': '결혼식장'},
    {'phase': 'D-6m', 'title': '본식 스냅 및 서브/아이폰 스냅 예약', 'linked': '본식 스냅 & 아이폰 스냅'},
    {'phase': 'D-6m', 'title': '본식 DVD(영상) 촬영 업체 계약', 'linked': '본식 DVD (영상)'},
    {'phase': 'D-6m', 'title': '스드메 패키지 구성 및 플래너 계약', 'linked': '스드메'},
    {'phase': 'D-6m', 'title': '신혼여행(허니문) 항공권 및 숙소 예약', 'linked': '신혼여행'},
    // D-5~4m
    {'phase': 'D-5m', 'title': '결혼반지(웨딩 밴드) 맞춤 제작', 'linked': '반지'},
    {'phase': 'D-5m', 'title': '신랑 맞춤 예복 및 촬영용 턱시도 결정', 'linked': '신랑 예복 / 한복'},
    {'phase': 'D-5m', 'title': '웨딩 갤러리 촬영용 드레스 셀렉', 'linked': '스드메'},
    {'phase': 'D-5m', 'title': '스튜디오 웨딩 촬영 진행', 'linked': '스드메'},
    {'phase': 'D-5m', 'title': '신혼집 매물 탐색 및 지역 조사', 'linked': '집'},
    // D-3~2m
    {'phase': 'D-3m', 'title': '웨딩 촬영 원본 사진 셀렉 및 보정 요청', 'linked': '스드메'},
    {'phase': 'D-3m', 'title': '청첩장 디자인 선정 및 종이 청첩장 인쇄', 'linked': '청첩장'},
    {'phase': 'D-3m', 'title': '식전영상 및 모바일 청첩장용 영상 제작', 'linked': '식전영상 & 모바일 청첩장 영상'},
    {'phase': 'D-3m', 'title': '모바일 청첩장 제작 및 링크 생성', 'linked': '청첩장'},
    {'phase': 'D-3m', 'title': '주례자, 사회자, 축가자 최종 섭외 및 감사비 준비', 'linked': '주례 / 사회 / 축가'},
    {'phase': 'D-3m', 'title': '양가 어머님 한복 대여/맞춤 피팅', 'linked': '어머님 한복'},
    {'phase': 'D-3m', 'title': '양가 아버님 정장 예복 준비', 'linked': '아버님 예복 / 한복'},
    {'phase': 'D-3m', 'title': '신혼집 계약 완료 및 대출 심사 확인', 'linked': '집'},
    {'phase': 'D-3m', 'title': '신혼 가전, 가구, 식기류 구입 리스트 작성 및 구매', 'linked': '혼수 리스트'},
    // D-1m
    {'phase': 'D-1m', 'title': '본식 드레스 최종 셀렉 및 가공 피팅', 'linked': '스드메'},
    {'phase': 'D-1m', 'title': '혼주 메이크업 업체 예약 확인 및 시간 배정', 'linked': '스드메'},
    {'phase': 'D-1m', 'title': '웨딩홀 최종 식순 및 BGM, 식전영상 파일 전달', 'linked': '결혼식장'},
    {'phase': 'D-1m', 'title': '웨딩카 대여 예약 및 당일 운전 기사 배정', 'linked': '웨딩카'},
    {'phase': 'D-1m', 'title': '신부 부케 및 부토니에, 코사지 꽃 장식 예약', 'linked': '부케 & 꽃 장식'},
    {'phase': 'D-1m', 'title': '본식 참석 하객에게 종이/모바일 청첩장 발송 완료', 'linked': '청첩장'},
    {'phase': 'D-1m', 'title': '하객 답례품 종류 및 수량 확정 후 예약', 'linked': '답례품 & 답례 떡'},
    // D-2w~Day-1
    {'phase': 'D-2w', 'title': '웨딩홀 보증 하객 인원 최종 전달 및 식대 정산 확인', 'linked': '결혼식장'},
    {'phase': 'D-2w', 'title': '사회자/축가자 대본 전달 및 식순 최종 점검', 'linked': '주례 / 사회 / 축가'},
    {'phase': 'D-2w', 'title': '개인 위생 및 뷰티 케어 (피부 관리, 네일, 헤어 염색, 제모)', 'linked': '개인 케어'},
    {'phase': 'D-2w', 'title': '본식 당일 준비물 (반지, 헬퍼비, 웨딩슈즈, 한복 등) 체크리스트 작성', 'linked': '결혼식장'},
    {'phase': 'D-2w', 'title': '신혼여행 짐 싸기 (환전, 로밍, 여권 확인)', 'linked': '신혼여행'},
    {'phase': 'D-2w', 'title': '프로포즈 완료 여부 및 기념 선물 준비', 'linked': '프로포즈'},
    {'phase': 'D-2w', 'title': '예물/예단 양가 전달 완료 상태 확인', 'linked': '예물'},
  ];

  void _initLocalData() {
    state = state.copyWith(isLoading: true);

    // 로그인된 유저가 없을 경우, 더미 유저 생성
    final hasUserProfile = _prefs.containsKey('user_uid');
    if (!hasUserProfile) {
      _prefs.setString('user_uid', 'user_123');
      _prefs.setString('user_name', '민우');
      _prefs.setString('user_gender', 'male');
      _prefs.setString('user_invite_code', 'W7A');
    }

    final currentUser = UserProfile(
      uid: _prefs.getString('user_uid')!,
      name: _prefs.getString('user_name')!,
      gender: _prefs.getString('user_gender')!,
      coupleId: _prefs.getString('user_couple_id'),
      inviteCode: _prefs.getString('user_invite_code')!,
    );

    // 카테고리 초기 데이터 정의
    final List<Map<String, String>> defaultCategories = [
      // 식장 & 의식
      {'id': 'planner', 'name': '웨딩 플래너', 'group': '식장 & 의식'},
      {'id': 'hall', 'name': '결혼식장', 'group': '식장 & 의식'},
      {'id': 'officiant', 'name': '주례 / 사회 / 축가', 'group': '식장 & 의식'},
      {'id': 'snap', 'name': '본식 스냅 & 아이폰 스냅', 'group': '식장 & 의식'},
      {'id': 'dvd', 'name': '본식 DVD (영상)', 'group': '식장 & 의식'},
      {'id': 'video', 'name': '식전영상 & 모바일 청첩장 영상', 'group': '식장 & 의식'},
      {'id': 'flower', 'name': '부케 & 꽃 장식', 'group': '식장 & 의식'},
      {'id': 'car', 'name': '웨딩카', 'group': '식장 & 의식'},
      {'id': 'pyebaek', 'name': '폐백 / 이바지', 'group': '식장 & 의식'},
      // 스타일 & 뷰티
      {'id': 'sdm', 'name': '스드메', 'group': '스타일 & 뷰티'},
      {'id': 'suit', 'name': '신랑 예복 / 한복', 'group': '스타일 & 뷰티'},
      {'id': 'ring', 'name': '반지', 'group': '스타일 & 뷰티'},
      {'id': 'hanbok_mother', 'name': '어머님 한복', 'group': '스타일 & 뷰티'},
      {'id': 'suit_father', 'name': '아버님 예복 / 한복', 'group': '스타일 & 뷰티'},
      {'id': 'care', 'name': '개인 케어', 'group': '스타일 & 뷰티'},
      // 초대 & 감사
      {'id': 'invitation', 'name': '청첩장', 'group': '초대 & 감사'},
      {'id': 'gifts', 'name': '답례품 & 답례 떡', 'group': '초대 & 감사'},
      // 양가 행사
      {'id': 'propose', 'name': '프로포즈', 'group': '양가 행사'},
      {'id': 'meeting', 'name': '상견례', 'group': '양가 행사'},
      {'id': 'yemul', 'name': '예물', 'group': '양가 행사'},
      {'id': 'yedan', 'name': '예단', 'group': '양가 행사'},
      // 신혼 준비
      {'id': 'home', 'name': '집', 'group': '신혼 준비'},
      {'id': 'furniture', 'name': '혼수 리스트', 'group': '신혼 준비'},
      {'id': 'honeymoon', 'name': '신혼여행', 'group': '신혼 준비'},
    ];

    if (Firebase.apps.isNotEmpty && currentUser.coupleId != null) {
      _initFirestoreSync(currentUser, defaultCategories);
      return;
    }

    List<WeddingCategory> categories = [];
    for (var cat in defaultCategories) {
      final keyPrefix = 'cat_${cat['id']}_';
      final statusName = _prefs.getString('${keyPrefix}status') ?? 'none';
      final estCost = _prefs.getInt('${keyPrefix}estimatedCost') ?? 0;
      final actCost = _prefs.getInt('${keyPrefix}actualCost') ?? 0;
      final notes = _prefs.getString('${keyPrefix}notes') ?? '';
      final vendorName = _prefs.getString('${keyPrefix}vendorName') ?? '';
      final vendorPhone = _prefs.getString('${keyPrefix}vendorPhone') ?? '';
      final photoCount = _prefs.getInt('${keyPrefix}photoCount') ?? 0;
      List<CategoryPhoto> photos = [];
      for (int i = 0; i < photoCount; i++) {
        final photoKey = '${keyPrefix}photo_${i}_';
        photos.add(
          CategoryPhoto(
            url: _prefs.getString('${photoKey}url') ?? '',
            caption: _prefs.getString('${photoKey}caption') ?? '',
            uploadedBy: _prefs.getString('${photoKey}uploadedBy') ?? '',
            uploadedAt: DateTime.parse(_prefs.getString('${photoKey}uploadedAt') ?? DateTime.now().toIso8601String()),
          ),
        );
      }

      categories.add(
        WeddingCategory(
          id: cat['id']!,
          name: cat['name']!,
          groupName: cat['group']!,
          status: PreparationStatus.values.firstWhere((e) => e.name == statusName),
          estimatedCost: estCost,
          actualCost: actCost,
          notes: notes,
          vendorName: vendorName,
          vendorPhone: vendorPhone,
          schedules: [],
          photos: photos,
          updatedBy: '시스템',
          updatedAt: DateTime.now(),
        ),
      );
    }

    // 시기별 체크리스트 생성 및 로드
    List<TimelineChecklistItem> timelineList = [];
    for (int i = 0; i < _defaultTimelineTasks.length; i++) {
      final task = _defaultTimelineTasks[i];
      final taskKey = 'timeline_task_${i}_isDone';
      final isDone = _prefs.getBool(taskKey) ?? false;
      final linkedCat = categories.firstWhere(
        (c) => c.name == task['linked'],
        orElse: () => categories.first,
      );

      timelineList.add(
        TimelineChecklistItem(
          id: 'timeline_$i',
          phase: task['phase']!,
          title: task['title']!,
          isDone: isDone,
          linkedCategoryId: linkedCat.id,
          createdBy: '시스템',
        ),
      );
    }

    // 커플 정보 로드
    CoupleInfo? coupleInfo;
    if (currentUser.coupleId != null) {
      final weddingDateStr = _prefs.getString('couple_wedding_date');
      coupleInfo = CoupleInfo(
        maleUid: _prefs.getString('couple_male_uid') ?? currentUser.uid,
        femaleUid: _prefs.getString('couple_female_uid') ?? 'female_partner',
        weddingDate: weddingDateStr != null ? DateTime.parse(weddingDateStr) : DateTime.now().add(const Duration(days: 180)),
        budgetGoal: _prefs.getInt('couple_budget_goal') ?? 40000000,
      );
    }

    // 하객 목록 로드
    final guestCount = _prefs.getInt('guest_count') ?? 0;
    List<GuestItem> guests = [];
    for (int i = 0; i < guestCount; i++) {
      final guestKey = 'guest_${i}_';
      guests.add(
        GuestItem(
          id: 'guest_$i',
          name: _prefs.getString('${guestKey}name') ?? '',
          phone: _prefs.getString('${guestKey}phone') ?? '',
          side: _prefs.getString('${guestKey}side') ?? 'groom',
          mealConfirmed: _prefs.getBool('${guestKey}mealConfirmed') ?? false,
          attended: _prefs.getBool('${guestKey}attended') ?? false,
        ),
      );
    }

    // 하객 기본 예시 추가 (처음 실행 시)
    if (guestCount == 0) {
      guests = [
        GuestItem(id: 'guest_0', name: '김철수', phone: '010-1234-5678', side: 'groom', mealConfirmed: true, attended: false),
        GuestItem(id: 'guest_1', name: '이영희', phone: '010-8765-4321', side: 'bride', mealConfirmed: true, attended: false),
        GuestItem(id: 'guest_2', name: '박민준', phone: '010-4455-6677', side: 'groom', mealConfirmed: false, attended: false),
      ];
      _prefs.setInt('guest_count', 3);
      for (int i = 0; i < guests.length; i++) {
        final guestKey = 'guest_${i}_';
        _prefs.setString('${guestKey}name', guests[i].name);
        _prefs.setString('${guestKey}phone', guests[i].phone);
        _prefs.setString('${guestKey}side', guests[i].side);
        _prefs.setBool('${guestKey}mealConfirmed', guests[i].mealConfirmed);
        _prefs.setBool('${guestKey}attended', guests[i].attended);
      }
    }

    // 메모 목록 로드
    final memoCount = _prefs.getInt('memo_count') ?? 0;
    List<Map<String, dynamic>> memos = [];
    for (int i = 0; i < memoCount; i++) {
      memos.add({
        'text': _prefs.getString('memo_${i}_text'),
        'sender': _prefs.getString('memo_${i}_sender'),
        'time': _prefs.getString('memo_${i}_time'),
      });
    }

    state = WeddingState(
      currentUser: currentUser,
      coupleInfo: coupleInfo,
      categories: categories,
      timelineChecklist: timelineList,
      guests: guests,
      memos: memos,
      isLoading: false,
    );
  }

  void _initFirestoreSync(UserProfile currentUser, List<Map<String, String>> defaultCategories) {
    final coupleId = currentUser.coupleId!;
    final coupleDoc = FirebaseFirestore.instance.collection('couples').doc(coupleId);

    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    state = state.copyWith(isLoading: true, currentUser: currentUser);

    // 1. 커플 정보 리스너
    _subscriptions.add(coupleDoc.snapshots().listen((snap) async {
      if (!snap.exists) {
        await coupleDoc.set({
          'maleUid': currentUser.gender == 'male' ? currentUser.uid : 'partner_uid',
          'femaleUid': currentUser.gender == 'female' ? currentUser.uid : 'partner_uid',
          'weddingDate': DateTime.now().add(const Duration(days: 180)).toIso8601String(),
          'budgetGoal': 40000000,
        });
      } else {
        final data = snap.data();
        if (data != null) {
          state = state.copyWith(coupleInfo: CoupleInfo.fromMap(data));
        }
      }
    }, onError: (e) => debugPrint('Firestore couple listen error: $e')));

    // 2. 카테고리 정보 리스너
    final categoriesCol = coupleDoc.collection('categories');
    _subscriptions.add(categoriesCol.snapshots().listen((snap) async {
      if (snap.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var cat in defaultCategories) {
          final docRef = categoriesCol.doc(cat['id']);
          batch.set(docRef, {
            'name': cat['name'],
            'groupName': cat['group'],
            'status': 'none',
            'estimatedCost': 0,
            'actualCost': 0,
            'notes': '',
            'vendorName': '',
            'vendorPhone': '',
            'schedules': [],
            'photos': [],
            'updatedBy': '시스템',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      } else {
        final list = snap.docs.map((doc) => WeddingCategory.fromMap(doc.data(), doc.id)).toList();
        state = state.copyWith(categories: list);
      }
    }, onError: (e) => debugPrint('Firestore categories listen error: $e')));

    // 3. 체크리스트 리스너
    final checklistCol = coupleDoc.collection('checklist');
    _subscriptions.add(checklistCol.snapshots().listen((snap) async {
      if (snap.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (int i = 0; i < _defaultTimelineTasks.length; i++) {
          final task = _defaultTimelineTasks[i];
          final docRef = checklistCol.doc('timeline_$i');
          batch.set(docRef, {
            'phase': task['phase'],
            'title': task['title'],
            'isDone': false,
            'linkedCategoryId': _getLinkedIdByName(task['linked'] ?? '', defaultCategories),
            'createdBy': '시스템',
          });
        }
        await batch.commit();
      } else {
        final list = snap.docs.map((doc) => TimelineChecklistItem.fromMap(doc.data(), doc.id)).toList();
        state = state.copyWith(timelineChecklist: list);
      }
    }, onError: (e) => debugPrint('Firestore checklist listen error: $e')));

    // 4. 하객 정보 리스너
    final guestsCol = coupleDoc.collection('guests');
    _subscriptions.add(guestsCol.snapshots().listen((snap) async {
      if (snap.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        final defaultGuests = [
          GuestItem(id: 'guest_0', name: '김철수', phone: '010-1234-5678', side: 'groom', mealConfirmed: true, attended: false),
          GuestItem(id: 'guest_1', name: '이영희', phone: '010-8765-4321', side: 'bride', mealConfirmed: true, attended: false),
          GuestItem(id: 'guest_2', name: '박민준', phone: '010-4455-6677', side: 'groom', mealConfirmed: false, attended: false),
        ];
        for (var guest in defaultGuests) {
          final docRef = guestsCol.doc(guest.id);
          batch.set(docRef, guest.toMap());
        }
        await batch.commit();
      } else {
        final list = snap.docs.map((doc) => GuestItem.fromMap(doc.data(), doc.id)).toList();
        state = state.copyWith(guests: list);
      }
    }, onError: (e) => debugPrint('Firestore guests listen error: $e')));

    // 5. 메모 정보 리스너
    final memosCol = coupleDoc.collection('memos');
    _subscriptions.add(memosCol.snapshots().listen((snap) {
      final list = snap.docs.map((doc) => doc.data()).toList();
      state = state.copyWith(memos: list);
    }, onError: (e) => debugPrint('Firestore memos listen error: $e')));

    state = state.copyWith(isLoading: false);
  }

  String? _getLinkedIdByName(String name, List<Map<String, String>> defaultCategories) {
    try {
      final match = defaultCategories.firstWhere((c) => c['name'] == name);
      return match['id'];
    } catch (_) {
      return null;
    }
  }

  // 3자리 초대코드로 커플 연동 진행
  bool linkPartner(String code) {
    if (code.length == 3) {
      _prefs.setString('user_couple_id', 'couple_789');
      _prefs.setString('couple_male_uid', 'user_123');
      _prefs.setString('couple_female_uid', 'female_partner');
      _prefs.setString('couple_wedding_date', DateTime.now().add(const Duration(days: 180)).toIso8601String());
      _prefs.setInt('couple_budget_goal', 35000000);
      
      _initLocalData();
      return true;
    }
    return false;
  }

  // 카테고리 업데이트
  void updateCategory(WeddingCategory updated) {
    final keyPrefix = 'cat_${updated.id}_';
    _prefs.setString('${keyPrefix}status', updated.status.name);
    _prefs.setInt('${keyPrefix}estimatedCost', updated.estimatedCost);
    _prefs.setInt('${keyPrefix}actualCost', updated.actualCost);
    _prefs.setString('${keyPrefix}notes', updated.notes);
    _prefs.setString('${keyPrefix}vendorName', updated.vendorName);
    _prefs.setString('${keyPrefix}vendorPhone', updated.vendorPhone);

    state = state.copyWith(
      categories: state.categories.map((c) => c.id == updated.id ? updated : c).toList(),
    );

    if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
      FirebaseFirestore.instance
          .collection('couples')
          .doc(state.currentUser!.coupleId)
          .collection('categories')
          .doc(updated.id)
          .set(updated.toMap());
    }

    // 카테고리가 완료되면 연동된 시기별 체크리스트 상태도 업데이트
    if (updated.status == PreparationStatus.done) {
      _updateTimelineByLinkedCategory(updated.id, true);
    } else if (updated.status == PreparationStatus.none) {
      _updateTimelineByLinkedCategory(updated.id, false);
    }
  }

  // 시기별 체크리스트 아이템 직접 완료 상태 토글
  void toggleTimelineTask(String id) {
    final index = state.timelineChecklist.indexWhere((t) => t.id == id);
    if (index != -1) {
      final currentTask = state.timelineChecklist[index];
      final newDone = !currentTask.isDone;
      _prefs.setBool('timeline_task_${index}_isDone', newDone);

      final updatedTasks = List<TimelineChecklistItem>.from(state.timelineChecklist);
      updatedTasks[index] = currentTask.copyWith(isDone: newDone);

      // 연동된 카테고리가 있으면 카테고리 진행 상태도 연동 처리
      List<WeddingCategory> updatedCategories = List.from(state.categories);
      if (currentTask.linkedCategoryId != null) {
        final catIndex = updatedCategories.indexWhere((c) => c.id == currentTask.linkedCategoryId);
        if (catIndex != -1) {
          final cat = updatedCategories[catIndex];
          if (newDone && cat.status != PreparationStatus.done) {
            final updatedCat = cat.copyWith(status: PreparationStatus.done);
            _prefs.setString('cat_${cat.id}_status', PreparationStatus.done.name);
            updatedCategories[catIndex] = updatedCat;
            
            if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
              FirebaseFirestore.instance
                  .collection('couples')
                  .doc(state.currentUser!.coupleId)
                  .collection('categories')
                  .doc(cat.id)
                  .update({'status': PreparationStatus.done.name});
            }
          }
        }
      }

      if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
        FirebaseFirestore.instance
            .collection('couples')
            .doc(state.currentUser!.coupleId)
            .collection('checklist')
            .doc(id)
            .update({'isDone': newDone});
      }

      state = state.copyWith(
        timelineChecklist: updatedTasks,
        categories: updatedCategories,
      );
    }
  }

  void _updateTimelineByLinkedCategory(String categoryId, bool isDone) {
    final updatedTasks = state.timelineChecklist.map((task) {
      if (task.linkedCategoryId == categoryId) {
        final index = state.timelineChecklist.indexOf(task);
        _prefs.setBool('timeline_task_${index}_isDone', isDone);
        
        if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
          FirebaseFirestore.instance
              .collection('couples')
              .doc(state.currentUser!.coupleId)
              .collection('checklist')
              .doc(task.id)
              .update({'isDone': isDone});
        }
        return task.copyWith(isDone: isDone);
      }
      return task;
    }).toList();

    state = state.copyWith(timelineChecklist: updatedTasks);
  }

  // 하객 추가
  void addGuest(String name, String phone, String side) {
    final newGuest = GuestItem(
      id: 'guest_${state.guests.length}',
      name: name,
      phone: phone,
      side: side,
      mealConfirmed: false,
      attended: false,
    );

    final updated = [...state.guests, newGuest];
    _prefs.setInt('guest_count', updated.length);

    final guestKey = 'guest_${updated.length - 1}_';
    _prefs.setString('${guestKey}name', name);
    _prefs.setString('${guestKey}phone', phone);
    _prefs.setString('${guestKey}side', side);
    _prefs.setBool('${guestKey}mealConfirmed', false);
    _prefs.setBool('${guestKey}attended', false);

    if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
      FirebaseFirestore.instance
          .collection('couples')
          .doc(state.currentUser!.coupleId)
          .collection('guests')
          .doc(newGuest.id)
          .set(newGuest.toMap());
    }

    state = state.copyWith(guests: updated);
  }

  // 하객 토글 (식사 확정 / 참석 여부)
  void toggleGuestMeal(String id) {
    final updated = state.guests.map((g) {
      if (g.id == id) {
        final idx = state.guests.indexOf(g);
        _prefs.setBool('guest_${idx}_mealConfirmed', !g.mealConfirmed);
        
        if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
          FirebaseFirestore.instance
              .collection('couples')
              .doc(state.currentUser!.coupleId)
              .collection('guests')
              .doc(id)
              .update({'mealConfirmed': !g.mealConfirmed});
        }

        return GuestItem(
          id: g.id,
          name: g.name,
          phone: g.phone,
          side: g.side,
          mealConfirmed: !g.mealConfirmed,
          attended: g.attended,
        );
      }
      return g;
    }).toList();
    state = state.copyWith(guests: updated);
  }

  // 메모 전송
  void sendMemo(String text) {
    final userName = state.currentUser?.name ?? '나';
    final timeStr = DateTime.now().toLocal().toString().substring(11, 16); // HH:mm
    final newMemo = {
      'text': text,
      'sender': userName,
      'time': timeStr,
    };

    final updated = [...state.memos, newMemo];
    _prefs.setInt('memo_count', updated.length);
    _prefs.setString('memo_${updated.length - 1}_text', text);
    _prefs.setString('memo_${updated.length - 1}_sender', userName);
    _prefs.setString('memo_${updated.length - 1}_time', timeStr);

    if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
      FirebaseFirestore.instance
          .collection('couples')
          .doc(state.currentUser!.coupleId)
          .collection('memos')
          .add(newMemo);
    }

    state = state.copyWith(memos: updated);
  }

  // 카테고리 사진 추가
  void addCategoryPhoto(String categoryId, CategoryPhoto photo) {
    final catIndex = state.categories.indexWhere((c) => c.id == categoryId);
    if (catIndex != -1) {
      final cat = state.categories[catIndex];
      final updatedPhotos = [...cat.photos, photo];
      final updatedCat = cat.copyWith(
        photos: updatedPhotos,
        updatedBy: state.currentUser?.name ?? '사용자',
        updatedAt: DateTime.now(),
      );

      final keyPrefix = 'cat_${categoryId}_';
      _prefs.setInt('${keyPrefix}photoCount', updatedPhotos.length);
      final photoKey = '${keyPrefix}photo_${updatedPhotos.length - 1}_';
      _prefs.setString('${photoKey}url', photo.url);
      _prefs.setString('${photoKey}caption', photo.caption);
      _prefs.setString('${photoKey}uploadedBy', photo.uploadedBy);
      _prefs.setString('${photoKey}uploadedAt', photo.uploadedAt.toIso8601String());

      if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
        FirebaseFirestore.instance
            .collection('couples')
            .doc(state.currentUser!.coupleId)
            .collection('categories')
            .doc(categoryId)
            .update({
              'photos': updatedPhotos.map((p) => p.toMap()).toList(),
              'updatedBy': updatedCat.updatedBy,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      state = state.copyWith(
        categories: state.categories.map((c) => c.id == categoryId ? updatedCat : c).toList(),
      );
    }
  }

  // 카테고리 사진 삭제
  void deleteCategoryPhoto(String categoryId, String photoUrl) {
    final catIndex = state.categories.indexWhere((c) => c.id == categoryId);
    if (catIndex != -1) {
      final cat = state.categories[catIndex];
      final updatedPhotos = cat.photos.where((p) => p.url != photoUrl).toList();
      final updatedCat = cat.copyWith(
        photos: updatedPhotos,
        updatedBy: state.currentUser?.name ?? '사용자',
        updatedAt: DateTime.now(),
      );

      final keyPrefix = 'cat_${categoryId}_';
      _prefs.setInt('${keyPrefix}photoCount', updatedPhotos.length);
      for (int i = 0; i < updatedPhotos.length; i++) {
        final photoKey = '${keyPrefix}photo_${i}_';
        _prefs.setString('${photoKey}url', updatedPhotos[i].url);
        _prefs.setString('${photoKey}caption', updatedPhotos[i].caption);
        _prefs.setString('${photoKey}uploadedBy', updatedPhotos[i].uploadedBy);
        _prefs.setString('${photoKey}uploadedAt', updatedPhotos[i].uploadedAt.toIso8601String());
      }

      if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
        FirebaseFirestore.instance
            .collection('couples')
            .doc(state.currentUser!.coupleId)
            .collection('categories')
            .doc(categoryId)
            .update({
              'photos': updatedPhotos.map((p) => p.toMap()).toList(),
              'updatedBy': updatedCat.updatedBy,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      state = state.copyWith(
        categories: state.categories.map((c) => c.id == categoryId ? updatedCat : c).toList(),
      );
    }
  }

  // 영수증 스캔을 통한 카테고리 예산/금액 업데이트
  void updateCategoryBudgetFromScan(String categoryId, {required int actualCost, required String vendorName, required CategoryPhoto photo}) {
    final catIndex = state.categories.indexWhere((c) => c.id == categoryId);
    if (catIndex != -1) {
      final cat = state.categories[catIndex];
      final updatedPhotos = [...cat.photos, photo];
      final updatedCat = cat.copyWith(
        actualCost: actualCost,
        vendorName: vendorName,
        photos: updatedPhotos,
        updatedBy: state.currentUser?.name ?? '사용자',
        updatedAt: DateTime.now(),
      );

      final keyPrefix = 'cat_${categoryId}_';
      _prefs.setInt('${keyPrefix}actualCost', actualCost);
      _prefs.setString('${keyPrefix}vendorName', vendorName);
      _prefs.setInt('${keyPrefix}photoCount', updatedPhotos.length);
      final photoKey = '${keyPrefix}photo_${updatedPhotos.length - 1}_';
      _prefs.setString('${photoKey}url', photo.url);
      _prefs.setString('${photoKey}caption', photo.caption);
      _prefs.setString('${photoKey}uploadedBy', photo.uploadedBy);
      _prefs.setString('${photoKey}uploadedAt', photo.uploadedAt.toIso8601String());

      if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
        FirebaseFirestore.instance
            .collection('couples')
            .doc(state.currentUser!.coupleId)
            .collection('categories')
            .doc(categoryId)
            .update({
              'actualCost': actualCost,
              'vendorName': vendorName,
              'photos': updatedPhotos.map((p) => p.toMap()).toList(),
              'updatedBy': updatedCat.updatedBy,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      state = state.copyWith(
        categories: state.categories.map((c) => c.id == categoryId ? updatedCat : c).toList(),
      );
    }
  }
}

final weddingProvider = StateNotifierProvider<WeddingNotifier, WeddingState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WeddingNotifier(prefs);
});
