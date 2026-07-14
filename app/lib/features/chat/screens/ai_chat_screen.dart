import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/chat_bubble.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AiChatProvider>();
      if (provider.sessionId == null && !provider.isStarting) {
        provider.startSession();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          Consumer<AiChatProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: provider.isConnected
                          ? Colors.green
                          : provider.isConnecting || provider.isStarting
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AiChatProvider>(
        builder: (context, provider, child) {
          if (provider.messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: provider.sessionId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (provider.isStarting)
                              const CircularProgressIndicator(),
                            if (provider.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  provider.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (!provider.isStarting)
                              ElevatedButton.icon(
                                onPressed: () {
                                  provider.startSession();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Start Conversation'),
                              )
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          if (provider.errorMessage != null)
                            _ConnectionBanner(message: provider.errorMessage!),
                          Expanded(
                            child: provider.messages.isEmpty
                                ? Center(
                                    child: Text(
                                      provider.isConnected
                                          ? 'Say something to start!'
                                          : 'Connecting to AI Coach...',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(
                                      bottom: 20,
                                      top: 20,
                                    ),
                                    itemCount: provider.messages.length,
                                    itemBuilder: (context, index) {
                                      return ChatBubble(
                                        message: provider.messages[index],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
              if (provider.sessionId != null) _buildInputArea(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, AiChatProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = provider.isConnected && !provider.isStarting;

    void submitMessage() {
      if (provider.sendMessage(_messageController.text)) {
        _messageController.clear();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: canSend,
                decoration: InputDecoration(
                  hintText: canSend
                      ? 'Type your message...'
                      : 'Waiting for connection...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: canSend ? (_) => submitMessage() : null,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: canSend ? submitMessage : null,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canSend
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: canSend ? provider.toggleRecording : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: !canSend
                      ? Colors.grey.shade400
                      : provider.isRecording
                          ? Colors.red.shade600
                          : Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    if (provider.isRecording)
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                  ],
                ),
                child: Icon(
                  provider.isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                provider.endSession();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade100,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colorScheme.onErrorContainer,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
