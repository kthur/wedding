import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

    if (Firebase.apps.isEmpty) {
      // Fallback local mode
      final currentUser = UserProfile(
        uid: 'local_user',
        name: _prefs.getString('user_name') ?? '민우',
        gender: _prefs.getString('user_gender') ?? 'male',
        coupleId: _prefs.getString('user_couple_id') ?? 'couple_789',
        inviteCode: 'LCL',
      );
      CoupleInfo? coupleInfo = await DatabaseHelper.instance.getCoupleInfo();
      if (coupleInfo == null) {
        coupleInfo = CoupleInfo(
          maleUid: 'local_user',
          femaleUid: 'partner_uid',
          weddingDate: DateTime.now().add(const Duration(days: 180)),
          budgetGoal: 40000000,
        );
        await DatabaseHelper.instance.saveCoupleInfo(coupleInfo);
      }
      state = AuthState(currentUser: currentUser, coupleInfo: coupleInfo, isLoading: false);
      return;
    }

    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        state = AuthState(currentUser: null, coupleInfo: null, isLoading: false);
        _coupleSubscription?.cancel();
        return;
      }

      state = state.copyWith(isLoading: true);
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final currentUser = UserProfile.fromMap(data, user.uid);
          state = state.copyWith(currentUser: currentUser);

          if (currentUser.coupleId != null) {
            CoupleInfo? coupleInfo = await DatabaseHelper.instance.getCoupleInfo();
            state = state.copyWith(coupleInfo: coupleInfo);
            _initFirestoreSync(currentUser);
          } else {
            state = state.copyWith(coupleInfo: null, isLoading: false);
          }
        } else {
          // User authenticated but profile onboarding is incomplete
          final currentUser = UserProfile(
            uid: user.uid,
            name: '',
            gender: '',
            coupleId: null,
            inviteCode: '',
          );
          state = state.copyWith(currentUser: currentUser, coupleInfo: null, isLoading: false);
        }
      } catch (e) {
        debugPrint('Auth initialization error: $e');
        state = state.copyWith(isLoading: false);
      }
    });
  }

  void _initFirestoreSync(UserProfile currentUser) {
    if (currentUser.coupleId == null) return;
    _coupleSubscription?.cancel();
    final coupleDoc = FirebaseFirestore.instance.collection('couples').doc(currentUser.coupleId);

    _coupleSubscription = coupleDoc.snapshots().listen((snap) async {
      if (snap.exists) {
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

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
        return true;
      } else if (defaultTargetPlatform == TargetPlatform.android ||
                 defaultTargetPlatform == TargetPlatform.iOS ||
                 defaultTargetPlatform == TargetPlatform.macOS) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          state = state.copyWith(isLoading: false);
          return false;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        return true;
      } else {
        // Fallback for Windows desktop
        await FirebaseAuth.instance.signInAnonymously();
        return true;
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true);
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final OAuthCredential oAuthCredential = OAuthProvider('apple.com').credential(
          idToken: credential.identityToken,
          rawNonce: credential.state,
        );

        await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
        return true;
      } else {
        // Fallback for Windows / Android
        await FirebaseAuth.instance.signInAnonymously();
        return true;
      }
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> signUpProfile({required String name, required String gender}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final String inviteCode = _generateRandomCode(3);
      final newUser = UserProfile(
        uid: user.uid,
        name: name,
        gender: gender,
        coupleId: null,
        inviteCode: inviteCode,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(newUser.toMap());
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
    if (currentUser == null || Firebase.apps.isEmpty) return false;

    state = state.copyWith(isLoading: true);
    try {
      final codeUpper = code.toUpperCase();
      
      final partnerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('inviteCode', isEqualTo: codeUpper)
          .limit(1)
          .get();

      if (partnerQuery.docs.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final partnerDoc = partnerQuery.docs.first;
      final partnerUid = partnerDoc.id;
      final partnerProfile = UserProfile.fromMap(partnerDoc.data(), partnerUid);

      if (partnerProfile.coupleId != null || partnerProfile.uid == currentUser.uid) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final coupleId = 'couple_${currentUser.uid.substring(0, 5)}_${partnerUid.substring(0, 5)}';

      final batch = FirebaseFirestore.instance.batch();
      batch.update(FirebaseFirestore.instance.collection('users').doc(currentUser.uid), {'coupleId': coupleId});
      batch.update(FirebaseFirestore.instance.collection('users').doc(partnerUid), {'coupleId': coupleId});

      final isMale = currentUser.gender == 'male';
      final coupleInfo = CoupleInfo(
        maleUid: isMale ? currentUser.uid : partnerUid,
        femaleUid: isMale ? partnerUid : currentUser.uid,
        weddingDate: DateTime.now().add(const Duration(days: 180)),
        budgetGoal: 40000000,
      );

      batch.set(FirebaseFirestore.instance.collection('couples').doc(coupleId), coupleInfo.toMap());
      await batch.commit();

      await DatabaseHelper.instance.saveCoupleInfo(coupleInfo);
      
      final updatedUser = UserProfile(
        uid: currentUser.uid,
        name: currentUser.name,
        gender: currentUser.gender,
        coupleId: coupleId,
        inviteCode: currentUser.inviteCode,
      );
      state = state.copyWith(currentUser: updatedUser, coupleInfo: coupleInfo);
      _initFirestoreSync(updatedUser);
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
