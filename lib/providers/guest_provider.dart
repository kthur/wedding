import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/guest_item.dart';
import '../services/database_helper.dart';
import 'auth_provider.dart';

class GuestNotifier extends StateNotifier<List<GuestItem>> {
  final Ref _ref;
  StreamSubscription? _guestsSubscription;

  final List<GuestItem> _defaultGuests = [
    GuestItem(id: 'guest_0', name: '김철수', phone: '010-1234-5678', side: 'groom', mealConfirmed: true, attended: false),
    GuestItem(id: 'guest_1', name: '이영희', phone: '010-8765-4321', side: 'bride', mealConfirmed: true, attended: false),
    GuestItem(id: 'guest_2', name: '박민준', phone: '010-4455-6677', side: 'groom', mealConfirmed: false, attended: false),
  ];

  GuestNotifier(this._ref) : super([]) {
    _initGuests();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.currentUser?.coupleId != previous?.currentUser?.coupleId) {
        _initGuests();
      }
    });
  }

  @override
  void dispose() {
    _guestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initGuests() async {
    _guestsSubscription?.cancel();
    final auth = _ref.read(authProvider);

    var guests = await DatabaseHelper.instance.getGuests();

    if (guests.isEmpty) {
      guests = _defaultGuests;
      await DatabaseHelper.instance.saveGuests(guests);
    }

    state = guests;

    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      _initFirestoreSync(auth.currentUser!.coupleId!);
    }
  }

  void _initFirestoreSync(String coupleId) {
    final guestsCol = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('guests');

    _guestsSubscription = guestsCol.snapshots().listen((snap) async {
      if (snap.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var guest in state) {
          final docRef = guestsCol.doc(guest.id);
          batch.set(docRef, guest.toMap());
        }
        await batch.commit();
      } else {
        final list = snap.docs.map((doc) => GuestItem.fromMap(doc.data(), doc.id)).toList();
        await DatabaseHelper.instance.saveGuests(list);
        state = list;
      }
    }, onError: (e) => debugPrint('Firestore guests listen error: $e'));
  }

  Future<void> addGuest(String name, String phone, String side) async {
    // Solve ID collision (M-16) by using UUID
    final newGuest = GuestItem(
      id: 'guest_${const Uuid().v4()}',
      name: name,
      phone: phone,
      side: side,
      mealConfirmed: false,
      attended: false,
    );

    await DatabaseHelper.instance.addGuest(newGuest);
    state = [...state, newGuest];

    final auth = _ref.read(authProvider);
    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(auth.currentUser!.coupleId)
          .collection('guests')
          .doc(newGuest.id)
          .set(newGuest.toMap())
          .catchError((e) => debugPrint('Firestore guest add error: $e'));
    }
  }

  Future<void> toggleGuestMeal(String id) async {
    final guestIndex = state.indexWhere((g) => g.id == id);
    if (guestIndex != -1) {
      final guest = state[guestIndex];
      final newMealConfirmed = !guest.mealConfirmed;

      await DatabaseHelper.instance.updateGuestMeal(id, newMealConfirmed);

      final updated = List<GuestItem>.from(state);
      updated[guestIndex] = guest.copyWith(mealConfirmed: newMealConfirmed);
      state = updated;

      final auth = _ref.read(authProvider);
      if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
        await FirebaseFirestore.instance
            .collection('couples')
            .doc(auth.currentUser!.coupleId)
            .collection('guests')
            .doc(id)
            .update({'mealConfirmed': newMealConfirmed})
            .catchError((e) => debugPrint('Firestore guest update error: $e'));
      }
    }
  }
}

final guestProvider = StateNotifierProvider<GuestNotifier, List<GuestItem>>((ref) {
  return GuestNotifier(ref);
});
