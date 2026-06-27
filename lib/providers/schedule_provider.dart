import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/wedding_category.dart';
import '../services/database_helper.dart';
import 'auth_provider.dart';

class ScheduleNotifier extends StateNotifier<List<CategorySchedule>> {
  final Ref _ref;
  StreamSubscription? _schedulesSubscription;

  ScheduleNotifier(this._ref) : super([]) {
    _initSchedules();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.currentUser?.coupleId != previous?.currentUser?.coupleId) {
        _initSchedules();
      }
    });
  }

  @override
  void dispose() {
    _schedulesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initSchedules() async {
    _schedulesSubscription?.cancel();
    final auth = _ref.read(authProvider);

    final list = await DatabaseHelper.instance.getAllSchedules();
    state = list;

    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      _initFirestoreSync(auth.currentUser!.coupleId!);
    }
  }

  void _initFirestoreSync(String coupleId) {
    final schedulesCol = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('schedules');

    _schedulesSubscription = schedulesCol.snapshots().listen((snap) async {
      final list = snap.docs.map((doc) {
        final data = doc.data();
        return CategorySchedule.fromMap({...data, 'id': doc.id});
      }).toList();
      
      // Clean and save in batch locally
      final db = await DatabaseHelper.instance.database;
      final batch = db.batch();
      batch.delete('schedules');
      for (var item in list) {
        batch.insert('schedules', {
          'id': item.id,
          'categoryId': 'planner', // Default category
          'date': item.date.toIso8601String(),
          'title': item.title,
          'reminderDays': item.reminderDays,
        });
      }
      await batch.commit(noResult: true);
      state = list;
    }, onError: (e) => debugPrint('Firestore schedules listen error: $e'));
  }

  Future<void> addSchedule(String title, DateTime date, {String categoryId = 'planner'}) async {
    final schedule = CategorySchedule(
      id: const Uuid().v4(),
      title: title,
      date: DateTime(date.year, date.month, date.day),
      reminderDays: 1,
    );

    await DatabaseHelper.instance.addSchedule(categoryId, schedule);
    state = [...state, schedule];

    final auth = _ref.read(authProvider);
    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(auth.currentUser!.coupleId)
          .collection('schedules')
          .doc(schedule.id)
          .set(schedule.toMap())
          .catchError((e) => debugPrint('Firestore schedule save error: $e'));
    }
  }

  Future<void> deleteSchedule(String id) async {
    await DatabaseHelper.instance.deleteSchedule(id);
    state = state.where((s) => s.id != id).toList();

    final auth = _ref.read(authProvider);
    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(auth.currentUser!.coupleId)
          .collection('schedules')
          .doc(id)
          .delete()
          .catchError((e) => debugPrint('Firestore schedule delete error: $e'));
    }
  }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, List<CategorySchedule>>((ref) {
  return ScheduleNotifier(ref);
});
