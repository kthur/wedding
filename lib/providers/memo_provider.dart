import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_helper.dart';
import 'auth_provider.dart';

class MemoNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref _ref;
  StreamSubscription? _memosSubscription;

  MemoNotifier(this._ref) : super([]) {
    _initMemos();

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.currentUser?.coupleId != previous?.currentUser?.coupleId) {
        _initMemos();
      }
    });
  }

  @override
  void dispose() {
    _memosSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initMemos() async {
    _memosSubscription?.cancel();
    final auth = _ref.read(authProvider);

    final memos = await DatabaseHelper.instance.getMemos();
    state = memos;

    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      _initFirestoreSync(auth.currentUser!.coupleId!);
    }
  }

  void _initFirestoreSync(String coupleId) {
    final memosCol = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('memos');

    _memosSubscription = memosCol.snapshots().listen((snap) async {
      // For chat memos, we append new ones that don't exist locally
      final list = snap.docs.map((doc) => doc.data()).toList();
      
      // Bulk update local database with Firestore memos
      for (var memo in list) {
        final exists = state.any((m) => m['text'] == memo['text'] && m['time'] == memo['time']);
        if (!exists) {
          await DatabaseHelper.instance.addMemo(memo);
        }
      }
      
      state = list;
    }, onError: (e) => debugPrint('Firestore memos listen error: $e'));
  }

  Future<void> sendMemo(String text) async {
    final auth = _ref.read(authProvider);
    final userName = auth.currentUser?.name ?? '나';
    
    // Better time formatting using DateTime components rather than substring slicing (L-5)
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    final newMemo = {
      'text': text,
      'sender': userName,
      'time': timeStr,
    };

    await DatabaseHelper.instance.addMemo(newMemo);
    state = [...state, newMemo];

    if (Firebase.apps.isNotEmpty && auth.currentUser?.coupleId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('couples')
            .doc(auth.currentUser!.coupleId)
            .collection('memos')
            .add(newMemo);
      } catch (e) {
        debugPrint('Firestore memo send error: $e');
      }
    }
  }
}

final memoProvider = StateNotifierProvider<MemoNotifier, List<Map<String, dynamic>>>((ref) {
  return MemoNotifier(ref);
});
