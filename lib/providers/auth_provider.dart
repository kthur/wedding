import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/couple_info.dart';
import '../services/database_helper.dart';
import 'wedding_provider.dart' show sharedPreferencesProvider;

class AuthState {
  final UserProfile? currentUser;
  final CoupleInfo? coupleInfo;
  final bool isLoading;

  AuthState({
    this.currentUser,
    this.coupleInfo,
    this.isLoading = false,
  });

  AuthState copyWith({
    UserProfile? currentUser,
    CoupleInfo? coupleInfo,
    bool? isLoading,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      coupleInfo: coupleInfo ?? this.coupleInfo,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;
  StreamSubscription? _coupleSubscription;

  AuthNotifier(this._prefs) : super(AuthState()) {
    _initAuth();
  }

  @override
  void dispose() {
    _coupleSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAuth() async {
    state = state.copyWith(isLoading: true);

    String? uid;
    if (Firebase.apps.isNotEmpty) {
      try {
        final auth = FirebaseAuth.instance;
        var user = auth.currentUser;
        if (user == null) {
          final cred = await auth.signInAnonymously();
          user = cred.user;
        }
        uid = user?.uid;
      } catch (e) {
        debugPrint('Firebase Auth error: $e');
      }
    }

    // Initial default user if not exists
    if (!_prefs.containsKey('user_uid')) {
      await _prefs.setString('user_uid', uid ?? 'user_123');
      await _prefs.setString('user_name', '민우');
      await _prefs.setString('user_gender', 'male');
      await _prefs.setString('user_invite_code', 'W7A');
    } else if (uid != null && _prefs.getString('user_uid') != uid) {
      await _prefs.setString('user_uid', uid);
    }

    final currentUser = UserProfile(
      uid: _prefs.getString('user_uid')!,
      name: _prefs.getString('user_name')!,
      gender: _prefs.getString('user_gender')!,
      coupleId: _prefs.getString('user_couple_id'),
      inviteCode: _prefs.getString('user_invite_code')!,
    );

    state = state.copyWith(currentUser: currentUser);

    // Load couple info from SQLite
    CoupleInfo? coupleInfo = await DatabaseHelper.instance.getCoupleInfo();
    
    // If not found in SQLite but coupleId is set, create a default one
    if (coupleInfo == null && currentUser.coupleId != null) {
      final weddingDateStr = _prefs.getString('couple_wedding_date');
      coupleInfo = CoupleInfo(
        maleUid: _prefs.getString('couple_male_uid') ?? currentUser.uid,
        femaleUid: _prefs.getString('couple_female_uid') ?? 'female_partner',
        weddingDate: weddingDateStr != null ? DateTime.parse(weddingDateStr) : DateTime.now().add(const Duration(days: 180)),
        budgetGoal: _prefs.getInt('couple_budget_goal') ?? 40000000,
      );
      await DatabaseHelper.instance.saveCoupleInfo(coupleInfo);
    }

    state = state.copyWith(coupleInfo: coupleInfo);

    if (Firebase.apps.isNotEmpty && currentUser.coupleId != null) {
      _initFirestoreSync(currentUser);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void _initFirestoreSync(UserProfile currentUser) {
    _coupleSubscription?.cancel();
    final coupleDoc = FirebaseFirestore.instance.collection('couples').doc(currentUser.coupleId);

    _coupleSubscription = coupleDoc.snapshots().listen((snap) async {
      if (!snap.exists) {
        final defaultInfo = CoupleInfo(
          maleUid: currentUser.gender == 'male' ? currentUser.uid : 'partner_uid',
          femaleUid: currentUser.gender == 'female' ? currentUser.uid : 'partner_uid',
          weddingDate: DateTime.now().add(const Duration(days: 180)),
          budgetGoal: 40000000,
        );
        await coupleDoc.set(defaultInfo.toMap());
        await DatabaseHelper.instance.saveCoupleInfo(defaultInfo);
        state = state.copyWith(coupleInfo: defaultInfo);
      } else {
        final data = snap.data();
        if (data != null) {
          final info = CoupleInfo.fromMap(data);
          await DatabaseHelper.instance.saveCoupleInfo(info);
          state = state.copyWith(coupleInfo: info);
        }
      }
    }, onError: (e) => debugPrint('Firestore couple listen error: $e'));

    state = state.copyWith(isLoading: false);
  }

  Future<bool> linkPartner(String code) async {
    if (code.length == 3) {
      await _prefs.setString('user_couple_id', 'couple_789');
      await _prefs.setString('couple_male_uid', 'user_123');
      await _prefs.setString('couple_female_uid', 'female_partner');
      await _prefs.setString('couple_wedding_date', DateTime.now().add(const Duration(days: 180)).toIso8601String());
      await _prefs.setInt('couple_budget_goal', 35000000);

      // Re-initialize authentication data
      await _initAuth();
      return true;
    }
    return false;
  }

  Future<void> updateBudgetGoal(int goal) async {
    if (state.coupleInfo != null) {
      final updated = CoupleInfo(
        maleUid: state.coupleInfo!.maleUid,
        femaleUid: state.coupleInfo!.femaleUid,
        weddingDate: state.coupleInfo!.weddingDate,
        budgetGoal: goal,
      );
      await DatabaseHelper.instance.saveCoupleInfo(updated);
      state = state.copyWith(coupleInfo: updated);

      if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
        await FirebaseFirestore.instance
            .collection('couples')
            .doc(state.currentUser!.coupleId)
            .update({'budgetGoal': goal}).catchError((e) => debugPrint('Firestore budget update error: $e'));
      }
    }
  }

  Future<void> updateWeddingDate(DateTime date) async {
    if (state.coupleInfo != null) {
      final updated = CoupleInfo(
        maleUid: state.coupleInfo!.maleUid,
        femaleUid: state.coupleInfo!.femaleUid,
        weddingDate: date,
        budgetGoal: state.coupleInfo!.budgetGoal,
      );
      await DatabaseHelper.instance.saveCoupleInfo(updated);
      state = state.copyWith(coupleInfo: updated);

      if (Firebase.apps.isNotEmpty && state.currentUser?.coupleId != null) {
        await FirebaseFirestore.instance
            .collection('couples')
            .doc(state.currentUser!.coupleId)
            .update({'weddingDate': date.toIso8601String()}).catchError((e) => debugPrint('Firestore wedding date update error: $e'));
      }
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs);
});
