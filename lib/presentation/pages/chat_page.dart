import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../../domain/entities/message_entity.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendMedia(bool isVideo) async {
    try {
      final XFile? media = isVideo 
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      
      if (media != null) {
        await ref.read(chatViewModelProvider.notifier).sendMediaFile(media.path, isVideo);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      ref.read(chatViewModelProvider.notifier).sendTextMessage(_textController.text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Compartir con la Comunidad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Location attachment button
                    _buildAttachmentBtn(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(chatViewModelProvider.notifier).shareLocation();
                        _scrollToBottom();
                      },
                    ),
                    // Photo attachment button
                    _buildAttachmentBtn(
                      icon: Icons.photo_library_outlined,
                      label: 'Fotografía',
                      color: AppColors.success,
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndSendMedia(false);
                      },
                    ),
                    // Video attachment button
                    _buildAttachmentBtn(
                      icon: Icons.video_camera_back_outlined,
                      label: 'Video Corto',
                      color: AppColors.alert,
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndSendMedia(true);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final currentUser = authState.user;

    // Scroll to bottom when messages list updates
    ref.listen<ChatState>(chatViewModelProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat Vecinal Los Ceibos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Coordinación en tiempo real', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Messages List View
          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                : chatState.messages.isEmpty
                    ? const Center(child: Text('No hay mensajes en el chat. Escribe algo para comenzar.'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chatState.messages[index];
                          final isOwn = msg.senderId == currentUser?.id;
                          return _buildMessageBubble(msg, isOwn);
                        },
                      ),
          ),

          // Sending indicator loading bar
          if (chatState.isLoading && chatState.messages.isNotEmpty)
            const LinearProgressIndicator(color: AppColors.primary, minHeight: 2),

          // Message input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageEntity msg, bool isOwn) {
    final timeString = DateFormat('HH:mm').format(msg.timestamp);

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name (only if not own message)
            if (!isOwn)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Text(
                  msg.senderName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              ),

            // Message Body Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOwn ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isOwn ? const Radius.circular(16) : const Radius.circular(0),
                  bottomRight: isOwn ? const Radius.circular(0) : const Radius.circular(16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rendering location share coordinates card
                  if (msg.isLocationShare) ...[
                    _buildLocationShareCard(msg.latitude!, msg.longitude!, isOwn),
                    const SizedBox(height: 8),
                  ],

                  // Rendering photo/video media assets
                  if (msg.photoUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: msg.photoUrl!.startsWith('http')
                          ? Image.network(
                              msg.photoUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) => progress == null
                                  ? child
                                  : const SizedBox(
                                      height: 150,
                                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                                    ),
                            )
                          : Image.file(
                              File(msg.photoUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(
                                height: 150,
                                child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (msg.videoUrl != null) ...[
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_fill_outlined, color: Colors.white, size: 48),
                            SizedBox(height: 6),
                            Text('Video corto', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Plain Text Message
                  Text(
                    msg.messageText,
                    style: TextStyle(
                      color: isOwn ? Colors.white : AppColors.textDark,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Timestamp representation
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 6, left: 6),
              child: Text(
                timeString,
                style: const TextStyle(fontSize: 9, color: AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationShareCard(double lat, double lng, bool isOwn) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOwn ? Colors.white.withOpacity(0.12) : AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwn ? Colors.white24 : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: isOwn ? Colors.white : AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubicación Compartida',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isOwn ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOwn ? Colors.white70 : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isOwn ? Colors.white70 : AppColors.primary,
          )
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachments trigger
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
              onPressed: _showAttachmentOptions,
            ),
            const SizedBox(width: 8),
            // Message input field
            Expanded(
              child: TextFormField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onFieldSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary, size: 28),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
