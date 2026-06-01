import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/alert_usecases.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../domain/usecases/user_usecases.dart';

// Auth Providers
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final checkEmailVerificationUseCaseProvider = Provider<CheckEmailVerificationUseCase>((ref) {
  return CheckEmailVerificationUseCase(ref.watch(authRepositoryProvider));
});

final reloadUserUseCaseProvider = Provider<ReloadUserUseCase>((ref) {
  return ReloadUserUseCase(ref.watch(authRepositoryProvider));
});

// Alert Providers
final emitAlertUseCaseProvider = Provider<EmitAlertUseCase>((ref) {
  return EmitAlertUseCase(ref.watch(alertRepositoryProvider));
});

final updateAlertStatusUseCaseProvider = Provider<UpdateAlertStatusUseCase>((ref) {
  return UpdateAlertStatusUseCase(ref.watch(alertRepositoryProvider));
});

final getActiveAlertsUseCaseProvider = Provider<GetActiveAlertsUseCase>((ref) {
  return GetActiveAlertsUseCase(ref.watch(alertRepositoryProvider));
});

final getAlertsHistoryUseCaseProvider = Provider<GetAlertsHistoryUseCase>((ref) {
  return GetAlertsHistoryUseCase(ref.watch(alertRepositoryProvider));
});

final updateEmergencyLocationUseCaseProvider = Provider<UpdateEmergencyLocationUseCase>((ref) {
  return UpdateEmergencyLocationUseCase(ref.watch(alertRepositoryProvider));
});

final listenToAlertUseCaseProvider = Provider<ListenToAlertUseCase>((ref) {
  return ListenToAlertUseCase(ref.watch(alertRepositoryProvider));
});

// Chat Providers
final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>((ref) {
  return GetMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final uploadMediaUseCaseProvider = Provider<UploadMediaUseCase>((ref) {
  return UploadMediaUseCase(ref.watch(chatRepositoryProvider));
});

// User Providers
final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>((ref) {
  return GetUserByIdUseCase(ref.watch(userRepositoryProvider));
});

final saveUserProfileUseCaseProvider = Provider<SaveUserProfileUseCase>((ref) {
  return SaveUserProfileUseCase(ref.watch(userRepositoryProvider));
});

final getAllUsersUseCaseProvider = Provider<GetAllUsersUseCase>((ref) {
  return GetAllUsersUseCase(ref.watch(userRepositoryProvider));
});

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((ref) {
  return DeleteUserUseCase(ref.watch(userRepositoryProvider));
});

final updateUserRoleUseCaseProvider = Provider<UpdateUserRoleUseCase>((ref) {
  return UpdateUserRoleUseCase(ref.watch(userRepositoryProvider));
});

final getOnlineNeighborsCountUseCaseProvider = Provider<GetOnlineNeighborsCountUseCase>((ref) {
  return GetOnlineNeighborsCountUseCase(ref.watch(userRepositoryProvider));
});

final updateConnectionStatusUseCaseProvider = Provider<UpdateConnectionStatusUseCase>((ref) {
  return UpdateConnectionStatusUseCase(ref.watch(userRepositoryProvider));
});
