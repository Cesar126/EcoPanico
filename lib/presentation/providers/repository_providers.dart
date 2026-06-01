import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../domain/repositories/chat_repository.dart';

import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';

import '../../data/repositories/mock_user_repository.dart';
import '../../data/repositories/firebase_user_repository.dart';

import '../../data/repositories/mock_alert_repository.dart';
import '../../data/repositories/firebase_alert_repository.dart';

import '../../data/repositories/mock_chat_repository.dart';
import '../../data/repositories/firebase_chat_repository.dart';

// Modern Notifier replacing StateProvider for Riverpod 3 compatibility
class MockModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return AppConfig.useMockData;
  }

  void toggle(bool val) {
    state = val;
  }
}

final mockModeStateProvider = NotifierProvider<MockModeNotifier, bool>(() {
  return MockModeNotifier();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final isMock = ref.watch(mockModeStateProvider);
  return isMock ? MockAuthRepository() : FirebaseAuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final isMock = ref.watch(mockModeStateProvider);
  return isMock ? MockUserRepository() : FirebaseUserRepository();
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final isMock = ref.watch(mockModeStateProvider);
  return isMock ? MockAlertRepository() : FirebaseAlertRepository();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final isMock = ref.watch(mockModeStateProvider);
  return isMock ? MockChatRepository() : FirebaseChatRepository();
});
