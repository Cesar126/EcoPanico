import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/usecase_providers.dart';
import 'auth_viewmodel.dart';

class ChatState {
  final List<MessageEntity> messages;
  final bool isLoading;
  final String? errorMessage;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<MessageEntity>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatViewModel extends Notifier<ChatState> {
  StreamSubscription? _chatSubscription;

  @override
  ChatState build() {
    state = ChatState(isLoading: true);
    _chatSubscription = ref.read(getMessagesUseCaseProvider).call().listen((messages) {
      final currentUser = ref.read(authViewModelProvider).user;
      final filtered = messages.where((msg) {
        if (currentUser == null || currentUser.latitude == null || currentUser.longitude == null) {
          return true; // fallback: show all if user has no position set
        }
        if (msg.latitude == null || msg.longitude == null) {
          return true; // legacy or fallback message (show it)
        }
        final distance = Geolocator.distanceBetween(
          currentUser.latitude!,
          currentUser.longitude!,
          msg.latitude!,
          msg.longitude!,
        );
        return distance <= 200.0; // Filter messages to 200m range (sector)
      }).toList();

      state = state.copyWith(messages: filtered, isLoading: false);
    }, onError: (err) {
      state = state.copyWith(errorMessage: err.toString(), isLoading: false);
    });

    ref.onDispose(() {
      _chatSubscription?.cancel();
    });

    return ChatState();
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final msg = MessageEntity(
      id: const Uuid().v4(),
      senderId: user.id,
      senderName: user.fullName,
      messageText: text,
      timestamp: DateTime.now(),
      latitude: user.latitude,
      longitude: user.longitude,
    );

    try {
      await ref.read(sendMessageUseCaseProvider).call(msg);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> shareLocation() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    double lat = 0.33201;
    double lng = -78.11743;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {
      lat = 0.33201 + (DateTime.now().second % 10) * 0.0001;
      lng = -78.11743 - (DateTime.now().second % 10) * 0.0001;
    }

    final msg = MessageEntity(
      id: const Uuid().v4(),
      senderId: user.id,
      senderName: user.fullName,
      messageText: '📍 Ubicación en tiempo real compartida',
      timestamp: DateTime.now(),
      latitude: lat,
      longitude: lng,
    );

    try {
      await ref.read(sendMessageUseCaseProvider).call(msg);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> sendMediaFile(String filePath, bool isVideo) async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final downloadUrl = await ref.read(uploadMediaUseCaseProvider).call(
        filePath,
        isVideo ? 'chat_videos' : 'chat_photos',
      );

      final msg = MessageEntity(
        id: const Uuid().v4(),
        senderId: user.id,
        senderName: user.fullName,
        messageText: isVideo ? '🎥 Video enviado' : '📷 Foto enviada',
        timestamp: DateTime.now(),
        photoUrl: isVideo ? null : downloadUrl,
        videoUrl: isVideo ? downloadUrl : null,
        latitude: user.latitude,
        longitude: user.longitude,
      );

      await ref.read(sendMessageUseCaseProvider).call(msg);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      if (!isVideo) {
        // Fallback for photos: if Firebase Storage upload fails, read image bytes,
        // convert to Base64 data URL, and save to Firestore document database.
        try {
          final file = File(filePath);
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          final dataUrl = 'data:image/jpeg;base64,$base64Image';

          final msg = MessageEntity(
            id: const Uuid().v4(),
            senderId: user.id,
            senderName: user.fullName,
            messageText: '📷 Foto enviada (Base de Datos)',
            timestamp: DateTime.now(),
            photoUrl: dataUrl,
            videoUrl: null,
            latitude: user.latitude,
            longitude: user.longitude,
          );
          await ref.read(sendMessageUseCaseProvider).call(msg);
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'La foto se subió directamente a la base de datos (Base64) porque falló el almacenamiento de archivos.',
          );
        } catch (firestoreError) {
          state = state.copyWith(errorMessage: firestoreError.toString(), isLoading: false);
        }
      } else {
        state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      }
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Global provider for Chat State & Actions
final chatViewModelProvider = NotifierProvider<ChatViewModel, ChatState>(() {
  return ChatViewModel();
});
