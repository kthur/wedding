import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._prefs) : super(AuthState()) {
    _initAuth();
  }

  @override
  void dispose() {
    _coupleSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAuth() async {
    state = state.copyWith(isLoading: true);

    // Mock mode for UX review (ignoring real Firebase initialization)
    final savedUid = _prefs.getString('user_uid');
    if (savedUid == null) {
      state = AuthState(currentUser: null, coupleInfo: null, isLoading: false);
      return;
    }

    final currentUser = UserProfile(
      uid: savedUid,
      name: _prefs.getString('user_name') ?? '',
      gender: _prefs.getString('user_gender') ?? '',
      coupleId: _prefs.getString('user_couple_id'),
      inviteCode: _prefs.getString('user_invite_code') ?? 'MOCK',
    );

    CoupleInfo? coupleInfo = await DatabaseHelper.instance.getCoupleInfo();
    if (coupleInfo == null && currentUser.name.isNotEmpty) {
      // Create initial local couple info if user onboarded but info doesn't exist yet
      coupleInfo = CoupleInfo(
        maleUid: currentUser.gender == 'male' ? currentUser.uid : 'partner_uid',
        femaleUid: currentUser.gender == 'female' ? currentUser.uid : 'partner_uid',
        weddingDate: null, // Allow user to set custom date later
        budgetGoal: 40000000,
      );
      await DatabaseHelper.instance.saveCoupleInfo(coupleInfo);
    }

    state = AuthState(currentUser: currentUser, coupleInfo: coupleInfo, isLoading: false);
  }

// void _initFirestoreSync(UserProfile currentUser) {
  //   // No-op in mock mode
  // }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulating network lag
    try {
      const uid = 'mock_google_user';
      await _prefs.setString('user_uid', uid);
      final currentUser = UserProfile(
        uid: uid,
        name: '',
        gender: '',
        coupleId: null,
        inviteCode: 'MOCK_GGL',
      );
      state = AuthState(currentUser: currentUser, coupleInfo: null, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulating network lag
    try {
      const uid = 'mock_apple_user';
      await _prefs.setString('user_uid', uid);
      final currentUser = UserProfile(
        uid: uid,
        name: '',
        gender: '',
        coupleId: null,
        inviteCode: 'MOCK_APL',
      );
      state = AuthState(currentUser: currentUser, coupleInfo: null, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> signUpProfile({required String name, required String gender}) async {
    final currentUser = state.currentUser;
    if (currentUser == null) return false;

    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulating network lag
    try {
      final String inviteCode = _generateRandomCode(3);
      final newUser = UserProfile(
        uid: currentUser.uid,
        name: name,
        gender: gender,
        coupleId: null,
        inviteCode: inviteCode,
      );

      await _prefs.setString('user_name', name);
      await _prefs.setString('user_gender', gender);
      await _prefs.setString('user_invite_code', inviteCode);

      state = state.copyWith(currentUser: newUser, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Sign Up Profile Error: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<bool> linkPartner(String code) async {
    final currentUser = state.currentUser;
    if (currentUser == null) return false;

    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulating network lag
    try {
      final coupleId = 'couple_mock_${currentUser.uid.substring(0, min(5, currentUser.uid.length))}';
      const partnerUid = 'partner_mock_123';
      
      await _prefs.setString('user_couple_id', coupleId);
      
      final isMale = currentUser.gender == 'male';
      final coupleInfo = CoupleInfo(
        maleUid: isMale ? currentUser.uid : partnerUid,
        femaleUid: isMale ? partnerUid : currentUser.uid,
        weddingDate: DateTime.now().add(const Duration(days: 180)),
        budgetGoal: 40000000,
      );

      await DatabaseHelper.instance.saveCoupleInfo(coupleInfo);
      
      final updatedUser = UserProfile(
        uid: currentUser.uid,
        name: currentUser.name,
        gender: currentUser.gender,
        coupleId: coupleId,
        inviteCode: currentUser.inviteCode,
      );
      state = state.copyWith(currentUser: updatedUser, coupleInfo: coupleInfo, isLoading: false);
      return true;
    } catch (e) {
      debugPrint('Link Partner Error: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      _coupleSubscription?.cancel();
      _authSubscription?.cancel();
      
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      
      await _prefs.remove('user_uid');
      await _prefs.remove('user_name');
      await _prefs.remove('user_gender');
      await _prefs.remove('user_couple_id');
      await _prefs.remove('user_invite_code');
      await DatabaseHelper.instance.clearAllData();

      state = AuthState(currentUser: null, coupleInfo: null, isLoading: false);
      _initAuth();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateBudgetGoal(int goal) async {
    final currentCoupleInfo = state.coupleInfo ?? CoupleInfo(
      maleUid: state.currentUser?.gender == 'male' ? state.currentUser?.uid : 'partner_uid',
      femaleUid: state.currentUser?.gender == 'female' ? state.currentUser?.uid : 'partner_uid',
      weddingDate: null,
      budgetGoal: goal,
    );
    final updated = CoupleInfo(
      maleUid: currentCoupleInfo.maleUid,
      femaleUid: currentCoupleInfo.femaleUid,
      weddingDate: currentCoupleInfo.weddingDate,
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

  Future<void> updateWeddingDate(DateTime date) async {
    final currentCoupleInfo = state.coupleInfo ?? CoupleInfo(
      maleUid: state.currentUser?.gender == 'male' ? state.currentUser?.uid : 'partner_uid',
      femaleUid: state.currentUser?.gender == 'female' ? state.currentUser?.uid : 'partner_uid',
      weddingDate: date,
      budgetGoal: 40000000,
    );
    final updated = CoupleInfo(
      maleUid: currentCoupleInfo.maleUid,
      femaleUid: currentCoupleInfo.femaleUid,
      weddingDate: date,
      budgetGoal: currentCoupleInfo.budgetGoal,
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

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs);
});
