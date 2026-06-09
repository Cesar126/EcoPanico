import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/usecase_providers.dart';
import '../providers/repository_providers.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isEmailVerified;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isEmailVerified = false,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool? isEmailVerified,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  StreamSubscription? _authSubscription;

  @override
  AuthState build() {
    // Listen to repository authentication changes
    state = AuthState(isLoading: true);
    _authSubscription = ref.read(authRepositoryProvider).onAuthStateChanged.listen((user) async {
      if (user != null) {
        final verified = await ref.read(checkEmailVerificationUseCaseProvider).call();
        state = AuthState(user: user, isEmailVerified: verified, isLoading: false);
      } else {
        state = AuthState(user: null, isEmailVerified: false, isLoading: false);
      }
    }, onError: (err) {
      state = AuthState(errorMessage: err.toString(), isLoading: false);
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await ref.read(loginUseCaseProvider).call(email, password);
      if (user != null) {
        final verified = await ref.read(checkEmailVerificationUseCaseProvider).call();
        state = state.copyWith(user: user, isEmailVerified: verified, isLoading: false);
      } else {
        state = state.copyWith(errorMessage: 'Credenciales inválidas', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String address,
    required String houseNumber,
    required String email,
    required String password,
    String? photoUrl,
    required String community,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    double? lat;
    double? lng;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (_) {
      // Fallback: let user register anyway if location services fail or are denied
    }

    try {
      final userEntity = UserEntity(
        id: '',
        fullName: fullName,
        phone: phone,
        address: address,
        houseNumber: houseNumber,
        photoUrl: photoUrl,
        role: 'vecino',
        latitude: lat,
        longitude: lng,
        community: community,
      );
      final user = await ref.read(registerUseCaseProvider).call(userEntity, email, password);
      state = state.copyWith(user: user, isEmailVerified: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> checkVerification() async {
    if (state.user == null) return;
    try {
      await ref.read(reloadUserUseCaseProvider).call();
      final verified = await ref.read(checkEmailVerificationUseCaseProvider).call();
      if (verified != state.isEmailVerified) {
        state = state.copyWith(isEmailVerified: verified);
      }
    } catch (_) {}
  }

  Future<void> recoverPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(resetPasswordUseCaseProvider).call(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(logoutUseCaseProvider).call();
      state = AuthState(user: null, isEmailVerified: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Global provider for Auth State & Actions
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(() {
  return AuthViewModel();
});
