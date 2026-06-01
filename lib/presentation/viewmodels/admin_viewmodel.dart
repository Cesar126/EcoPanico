import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/usecase_providers.dart';

class AdminState {
  final List<UserEntity> users;
  final bool isLoading;
  final String? errorMessage;

  AdminState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get totalUsers => users.length;
  int get totalNeighbors => users.where((u) => u.role == 'vecino').length;
  int get totalAdmins => users.where((u) => u.role == 'admin').length;
  int get onlineCount => users.where((u) => u.isConnected).length;

  AdminState copyWith({
    List<UserEntity>? users,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminViewModel extends Notifier<AdminState> {
  StreamSubscription? _usersSub;

  @override
  AdminState build() {
    state = AdminState(isLoading: true);
    _usersSub = ref.read(getAllUsersUseCaseProvider).call().listen((users) {
      state = state.copyWith(users: users, isLoading: false);
    }, onError: (err) {
      state = state.copyWith(errorMessage: err.toString(), isLoading: false);
    });

    ref.onDispose(() {
      _usersSub?.cancel();
    });

    return AdminState();
  }

  Future<void> changeUserRole(String id, String role) async {
    try {
      await ref.read(updateUserRoleUseCaseProvider).call(id, role);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> removeUser(String id) async {
    try {
      await ref.read(deleteUserUseCaseProvider).call(id);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Global provider for Admin State & Actions
final adminViewModelProvider = NotifierProvider<AdminViewModel, AdminState>(() {
  return AdminViewModel();
});
