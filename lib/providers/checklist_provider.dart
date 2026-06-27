import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checklist_item.dart';
import '../services/database_helper.dart';
import 'auth_provider.dart';

class ChecklistNotifier extends StateNotifier<List<TimelineChecklistItem>> {
  final Ref _ref;
  StreamSubscription? _checklistSubscription;

  final List<Map<String, String>> _defaultTimelineTasks = const [
    {'phase': 'D-6m', 'title': '양가 상견례 일정 조율 및 예약', 'linked': '상견례'},
    {'phase': 'D-6m', 'title': '결혼 전체 예산 수립 및 분담 논의', 'linked': '웨딩 플래너'},
    {'phase': 'D-6m', 'title': '웨딩홀(베뉴) 투어 및 최종 계약', 'linked': '결혼식장'},
    {'phase': 'D-6m', 'title': '본식 스냅 및 서브/아이폰 스냅 예약', 'linked': '본식 스냅 & 아이폰 스냅'},
    {'phase': 'D-6m', 'title': '본식 DVD(영상) 촬영 업체 계약', 'linked': '본식 DVD (영상)'},
    {'phase': 'D-6m', 'title': '스드메 패키지 구성 및 플래너 계약', 'linked': '스드메'},
    {'phase': 'D-6m', 'title': '신혼여행(허니문) 항공권 및 숙소 예약', 'linked': '신혼여행'},
    {'phase': 'D-5m', 'title': '결혼반지(웨딩 밴드) 맞춤 제작', 'linked': '반지'},
    {'phase': 'D-5m', 'title': '신랑 맞춤 예복 및 촬영용 턱시도 결정', 'linked': '신랑 예복 / 한복'},
    {'phase': 'D-5m', 'title': '웨딩 갤러리 촬영용 드레스 셀렉', 'linked': '스드메'},
    {'phase': 'D-5m', 'title': '스튜디오 웨딩 촬영 진행', 'linked': '스드메'},
    {'phase': 'D-5m', 'title': '신혼집 매물 탐색 및 지역 조사', 'linked': '집'},
    {'phase': 'D-3m', 'title': '웨딩 촬영 원본 사진 셀렉 및 보정 요청', 'linked': '스드메'},
    {'phase': 'D-3m', 'title': '청첩장 디자인 선정 및 종이 청첩장 인쇄', 'linked': '청첩장'},
    {'phase': 'D-3m', 'title': '식전영상 및 모바일 청첩장용 영상 제작', 'linked': '식전영상 & 모바일 청첩장 영상'},
    {'phase': 'D-3m', 'title': '모바일 청첩장 제작 및 링크 생성', 'linked': '청첩장'},
    {'phase': 'D-3m', 'title': '주례자, 사회자, 축가자 최종 섭외 및 감사비 준비', 'linked': '주례 / 사회 / 축가'},
    {'phase': 'D-3m', 'title': '양가 어머님 한복 대여/맞춤 피팅', 'linked': '어머님 한복'},
    {'phase': 'D-3m', 'title': '양가 아버님 정장 예복 준비', 'linked': '아버님 예복 / 한복'},
    {'phase': 'D-3m', 'title': '신혼집 계약 완료 및 대출 심사 확인', 'linked': '집'},
    {'phase': 'D-3m', 'title': '신혼 가전, 가구, 식기류 구입 리스트 작성 및 구매', 'linked': '혼수 리스트'},
    {'phase': 'D-1m', 'title': '본식 드레스 최종 셀렉 및 가공 피팅', 'linked': '스드메'},
    {'phase': 'D-1m', 'title': '혼주 메이크업 업체 예약 확인 및 시간 배정', 'linked': '스드메'},
    {'phase': 'D-1m', 'title': '웨딩홀 최종 식순 및 BGM, 식전영상 파일 전달', 'linked': '결혼식장'},
    {'phase': 'D-1m', 'title': '웨딩카 대여 예약 및 당일 운전 기사 배정', 'linked': '웨딩카'},
    {'phase': 'D-1m', 'title': '신부 부케 및 부토니에, 코사지 꽃 장식 예약', 'linked': '부케 & 꽃 장식'},
    {'phase': 'D-1m', 'title': '본식 참석 하객에게 종이/모바일 청첩장 발송 완료', 'linked': '청첩장'},
    {'phase': 'D-1m', 'title': '하객 답례품 종류 및 수량 확정 후 예약', 'linked': '답례품 & 답례 떡'},
    {'phase': 'D-2w', 'title': '웨딩홀 보증 하객 인원 최종 전달 및 식대 정산 확인', 'linked': '결혼식장'},
    {'phase': 'D-2w', 'title': '사회자/축가자 대본 전달 및 식순 최종 점검', 'linked': '주례 / 사회 / 축가'},
    {'phase': 'D-2w', 'title': '개인 위생 및 뷰티 케어 (피부 관리, 네일, 헤어 염색, 제모)', 'linked': '개인 케어'},
    {'phase': 'D-2w', 'title': '본식 당일 준비물 (반지, 헬퍼비, 웨딩슈즈, 한복 등) 체크리스트 작성', 'linked': '결혼식장'},
    {'phase': 'D-2w', 'title': '신혼여행 짐 싸기 (환전, 로밍, 여권 확인)', 'linked': '신혼여행'},
    {'phase': 'D-2w', 'title': '프로포즈 완료 여부 및 기념 선물 준비', 'linked': '프로포즈'},
    {'phase': 'D-2w', 'title': '예물/예단 양가 전달 완료 상태 확인', 'linked': '예물'},
  ];

  ChecklistNotifier(this._ref) : super([]) {
    _initChecklist();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.currentUser?.coupleId != previous?.currentUser?.coupleId) {
        _initChecklist();
      }
    });
  }

  @override
  void dispose() {
    _checklistSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initChecklist() async {
    _checklistSubscription?.cancel();
    final auth = _ref.read(authProvider);

    var checklist = await DatabaseHelper.instance.getChecklist();

    if (checklist.isEmpty) {
      // Temporary mapping helper to resolve default linked category ids
      final defaultCategories = [
        {'name': '상견례', 'id': 'meeting'},
        {'name': '웨딩 플래너', 'id': 'planner'},
        {'name': '결혼식장', 'id': 'hall'},
        {'name': '본식 스냅 & 아이폰 스냅', 'id': 'snap'},
        {'name': '본식 DVD (영상)', 'id': 'dvd'},
        {'name': '스드메', 'id': 'sdm'},
        {'name': '신혼여행', 'id': 'honeymoon'},
        {'name': '반지', 'id': 'ring'},
        {'name': '신랑 예복 / 한복', 'id': 'suit'},
        {'name': '집', 'id': 'home'},
        {'name': '청첩장', 'id': 'invitation'},
        {'name': '식전영상 & 모바일 청첩장 영상', 'id': 'video'},
        {'name': '주례 / 사회 / 축가', 'id': 'officiant'},
        {'name': '어머님 한복', 'id': 'hanbok_mother'},
        {'name': '아버님 예복 / 한복', 'id': 'suit_father'},
        {'name': '혼수 리스트', 'id': 'furniture'},
        {'name': '웨딩카', 'id': 'car'},
        {'name': '부케 & 꽃 장식', 'id': 'flower'},
        {'name': '답례품 & 답례 떡', 'id': 'gifts'},
        {'name': '개인 케어', 'id': 'care'},
        {'name': '프로포즈', 'id': 'propose'},
        {'name': '예물', 'id': 'yemul'},
      ];

      checklist = [];
      for (int i = 0; i < _defaultTimelineTasks.length; i++) {
        final task = _defaultTimelineTasks[i];
        final match = defaultCategories.firstWhere(
          (c) => c['name'] == task['linked'],
          orElse: () => {'name': '', 'id': 'planner'},
        );

        checklist.add(
          TimelineChecklistItem(
            id: 'timeline_$i',
            phase: task['phase']!,
            title: task['title']!,
            isDone: false,
            linkedCategoryId: match['id'],
            createdBy: '시스템',
          ),
        );
      }
      await DatabaseHelper.instance.saveChecklist(checklist);
    }

    state = checklist;

    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      _initFirestoreSync(auth.currentUser!.coupleId!);
    }
  }

  void _initFirestoreSync(String coupleId) {
    final checklistCol = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('checklist');

    _checklistSubscription = checklistCol.snapshots().listen((snap) async {
      if (snap.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var item in state) {
          final docRef = checklistCol.doc(item.id);
          batch.set(docRef, item.toMap());
        }
        await batch.commit();
      } else {
        final list = snap.docs.map((doc) => TimelineChecklistItem.fromMap(doc.data(), doc.id)).toList();
        await DatabaseHelper.instance.saveChecklist(list);
        state = list;
      }
    }, onError: (e) => debugPrint('Firestore checklist listen error: $e'));
  }

  Future<void> toggleTimelineTask(String id) async {
    final taskIndex = state.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final newDone = !task.isDone;

      await DatabaseHelper.instance.updateChecklistItem(id, newDone);
      
      final updated = List<TimelineChecklistItem>.from(state);
      updated[taskIndex] = task.copyWith(isDone: newDone);
      state = updated;

      final auth = _ref.read(authProvider);
      if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
        await FirebaseFirestore.instance
            .collection('couples')
            .doc(auth.currentUser!.coupleId)
            .collection('checklist')
            .doc(id)
            .update({'isDone': newDone})
            .catchError((e) => debugPrint('Firestore checklist update error: $e'));
      }
    }
  }

  Future<void> updateTimelineByLinkedCategory(String categoryId, bool isDone) async {
    final updated = state.map((task) {
      if (task.linkedCategoryId == categoryId) {
        DatabaseHelper.instance.updateChecklistItem(task.id, isDone);
        
        final auth = _ref.read(authProvider);
        if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
          FirebaseFirestore.instance
              .collection('couples')
              .doc(auth.currentUser!.coupleId)
              .collection('checklist')
              .doc(task.id)
              .update({'isDone': isDone})
              .catchError((e) => debugPrint('Firestore checklist linked update error: $e'));
        }
        return task.copyWith(isDone: isDone);
      }
      return task;
    }).toList();

    state = updated;
  }
}

final checklistProvider = StateNotifierProvider<ChecklistNotifier, List<TimelineChecklistItem>>((ref) {
  return ChecklistNotifier(ref);
});
