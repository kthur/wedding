import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wedding_category.dart';
import '../services/database_helper.dart';
import 'auth_provider.dart';
import 'checklist_provider.dart';

class CategoryNotifier extends StateNotifier<List<WeddingCategory>> {
  final Ref _ref;
  StreamSubscription? _categoriesSubscription;

  final List<Map<String, String>> _defaultCategories = const [
    {'id': 'planner', 'name': '웨딩 플래너', 'group': '식장 & 의식'},
    {'id': 'hall', 'name': '결혼식장', 'group': '식장 & 의식'},
    {'id': 'officiant', 'name': '주례 / 사회 / 축가', 'group': '식장 & 의식'},
    {'id': 'snap', 'name': '본식 스냅 & 아이폰 스냅', 'group': '식장 & 의식'},
    {'id': 'dvd', 'name': '본식 DVD (영상)', 'group': '식장 & 의식'},
    {'id': 'video', 'name': '식전영상 & 모바일 청첩장 영상', 'group': '식장 & 의식'},
    {'id': 'flower', 'name': '부케 & 꽃 장식', 'group': '식장 & 의식'},
    {'id': 'car', 'name': '웨딩카', 'group': '식장 & 의식'},
    {'id': 'pyebaek', 'name': '폐백 / 이바지', 'group': '식장 & 의식'},
    {'id': 'sdm', 'name': '스드메', 'group': '스타일 & 뷰티'},
    {'id': 'suit', 'name': '신랑 예복 / 한복', 'group': '스타일 & 뷰티'},
    {'id': 'ring', 'name': '반지', 'group': '스타일 & 뷰티'},
    {'id': 'hanbok_mother', 'name': '어머님 한복', 'group': '스타일 & 뷰티'},
    {'id': 'suit_father', 'name': '아버님 예복 / 한복', 'group': '스타일 & 뷰티'},
    {'id': 'care', 'name': '개인 케어', 'group': '스타일 & 뷰티'},
    {'id': 'invitation', 'name': '청첩장', 'group': '초대 & 감사'},
    {'id': 'gifts', 'name': '답례품 & 답례 떡', 'group': '초대 & 감사'},
    {'id': 'propose', 'name': '프로포즈', 'group': '양가 행사'},
    {'id': 'meeting', 'name': '상견례', 'group': '양가 행사'},
    {'id': 'yemul', 'name': '예물', 'group': '양가 행사'},
    {'id': 'yedan', 'name': '예단', 'group': '양가 행사'},
    {'id': 'home', 'name': '집', 'group': '신혼 준비'},
    {'id': 'furniture', 'name': '혼수 리스트', 'group': '신혼 준비'},
    {'id': 'honeymoon', 'name': '신혼여행', 'group': '신혼 준비'},
  ];

  CategoryNotifier(this._ref) : super([]) {
    _initCategories();
    
    // React to changes in user authentication or couple linking status
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.currentUser?.coupleId != previous?.currentUser?.coupleId) {
        _initCategories();
      }
    });
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initCategories() async {
    _categoriesSubscription?.cancel();
    final auth = _ref.read(authProvider);

    // Read from local database
    var categories = await DatabaseHelper.instance.getCategories();

    // Populate default categories if SQLite table is empty
    if (categories.isEmpty) {
      categories = _defaultCategories.map((cat) {
        return WeddingCategory(
          id: cat['id']!,
          name: cat['name']!,
          groupName: cat['group']!,
          status: PreparationStatus.none,
          estimatedCost: 0,
          actualCost: 0,
          notes: '',
          vendorName: '',
          vendorPhone: '',
          schedules: [],
          photos: [],
          updatedBy: '시스템',
          updatedAt: DateTime.now(),
        );
      }).toList();
      await DatabaseHelper.instance.saveCategories(categories);
    }

    state = categories;

    // Start Firestore sync if online and coupled
    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      _initFirestoreSync(auth.currentUser!.coupleId!);
    }
  }

  void _initFirestoreSync(String coupleId) {
    final categoriesCol = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('categories');

    _categoriesSubscription = categoriesCol.snapshots().listen((snap) async {
      if (snap.docs.isEmpty) {
        // Write default categories into Firestore in a batch write
        final batch = FirebaseFirestore.instance.batch();
        for (var cat in state) {
          final docRef = categoriesCol.doc(cat.id);
          batch.set(docRef, {
            'name': cat.name,
            'groupName': cat.groupName,
            'status': cat.status.name,
            'estimatedCost': cat.estimatedCost,
            'actualCost': cat.actualCost,
            'notes': cat.notes,
            'vendorName': cat.vendorName,
            'vendorPhone': cat.vendorPhone,
            'schedules': [],
            'photos': [],
            'updatedBy': '시스템',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      } else {
        final list = snap.docs.map((doc) => WeddingCategory.fromMap(doc.data(), doc.id)).toList();
        await DatabaseHelper.instance.saveCategories(list);
        state = list;
      }
    }, onError: (e) => debugPrint('Firestore categories listen error: $e'));
  }

  Future<void> updateCategory(WeddingCategory updated) async {
    await DatabaseHelper.instance.updateCategory(updated);
    state = state.map((c) => c.id == updated.id ? updated : c).toList();

    // Trigger checklist sync
    if (updated.status == PreparationStatus.done) {
      _ref.read(checklistProvider.notifier).updateTimelineByLinkedCategory(updated.id, true);
    } else if (updated.status == PreparationStatus.none) {
      _ref.read(checklistProvider.notifier).updateTimelineByLinkedCategory(updated.id, false);
    }

    final auth = _ref.read(authProvider);
    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(auth.currentUser!.coupleId)
          .collection('categories')
          .doc(updated.id)
          .set(updated.toMap())
          .catchError((e) => debugPrint('Firestore category save error: $e'));
    }
  }

  Future<void> addCategoryPhoto(String categoryId, CategoryPhoto photo) async {
    final category = state.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw StateError('Category not found: $categoryId'),
    );

    final updatedPhotos = [...category.photos, photo];
    final updated = category.copyWith(
      photos: updatedPhotos,
      updatedBy: _ref.read(authProvider).currentUser?.name ?? '사용자',
      updatedAt: DateTime.now(),
    );

    await updateCategory(updated);
  }

  Future<void> deleteCategoryPhoto(String categoryId, String photoUrl) async {
    final category = state.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw StateError('Category not found: $categoryId'),
    );

    final updatedPhotos = category.photos.where((p) => p.url != photoUrl).toList();
    final updated = category.copyWith(
      photos: updatedPhotos,
      updatedBy: _ref.read(authProvider).currentUser?.name ?? '사용자',
      updatedAt: DateTime.now(),
    );

    await updateCategory(updated);
  }

  Future<void> updateCategoryBudgetFromScan(
    String categoryId, {
    required int actualCost,
    required String vendorName,
    required CategoryPhoto photo,
  }) async {
    final category = state.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw StateError('Category not found: $categoryId'),
    );

    final updatedPhotos = [...category.photos, photo];
    final updated = category.copyWith(
      actualCost: actualCost,
      vendorName: vendorName,
      photos: updatedPhotos,
      updatedBy: _ref.read(authProvider).currentUser?.name ?? '사용자',
      updatedAt: DateTime.now(),
    );

    await updateCategory(updated);
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<WeddingCategory>>((ref) {
  return CategoryNotifier(ref);
});
