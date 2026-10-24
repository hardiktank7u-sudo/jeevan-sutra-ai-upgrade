// Google AI Studio - Jeevan Sutra AI Assistant Screen
// Botanical conversational AI guide powered by Gemini
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/gemini_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _userName = 'Hardik';
  String _dominantPrakriti = 'Pitta-Kapha';
  bool _isGenerating = false;
  bool _historyLoaded = false;

  final List<_ChatMessage> _messages = [];

  final List<String> _suggestedPrompts = [
    'Help me build a morning routine',
    'Explain a traditional wellness practice',
    'Suggest balanced Indian meals',
    'Tell me about medicinal plants',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final name = await LocalStorageService.instance.getProfileName();
    final dosha = await LocalStorageService.instance.getDosha();
    if (name.isNotEmpty && name != 'Wellness Explorer') {
      _userName = name.split(' ').first;
    }
    if (dosha != null && dosha.isNotEmpty) {
      _dominantPrakriti = dosha;
    }

    final saved = await LocalStorageService.instance.getChatHistory();
    if (!mounted) return;

    if (saved.isNotEmpty) {
      setState(() {
        _messages.addAll(
          saved.map(
            (item) => _ChatMessage(
              text: (item['text'] ?? '').toString(),
              isUser: item['isUser'] == true,
            ),
          ),
        );
        _historyLoaded = true;
      });
    } else {
      setState(() => _historyLoaded = true);
    }
  }

  Future<void> _persistChat() async {
    if (!_historyLoaded) return;
    final toSave = _messages
        .map((m) => {'text': m.text, 'isUser': m.isUser})
        .toList();
    await LocalStorageService.instance.saveChatHistory(toSave);
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

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isGenerating) return;

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: clean, isUser: true));
      _messages.add(_ChatMessage(text: '', isUser: false));
      _isGenerating = true;
    });
    _scrollToBottom();
    await _persistChat();

    // Prepare conversational history for Gemini
    final conversationHistory = _messages
        .take(_messages.length - 2)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    try {
      final stream = GeminiService.instance.streamChatResponse(
        prompt: clean,
        conversationHistory: conversationHistory,
      );

      stream.listen(
        (chunk) {
          if (!mounted) return;
          setState(() {
            _messages.last.text += chunk;
          });
          _scrollToBottom();
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isGenerating = false);
          _persistChat();
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            if (_messages.last.text.isEmpty) {
              _messages.last.text =
                  "I apologize, I could not complete the response. Please check your connectivity or try again.";
            }
            _isGenerating = false;
          });
          _persistChat();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.last.text = "Connection issue: $e";
        _isGenerating = false;
      });
      _persistChat();
    }
  }

  void _resetChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JeevanSutraColors.warmIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Start New Conversation?", style: TextStyle(fontWeight: FontWeight.bold, color: JeevanSutraColors.forestGreen)),
        content: const Text("This will clear the current conversation history with your AI Wellness Guide."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
              });
              await LocalStorageService.instance.clearChatHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: JeevanSutraColors.forestGreen),
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BotanicalBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(isDark),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg, isDark);
                        },
                      ),
              ),
              _buildInputArea(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        border: Border(
          bottom: BorderSide(
            color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [JeevanSutraColors.freshLeaf, JeevanSutraColors.forestGreen]
                        : [JeevanSutraColors.forestGreen, JeevanSutraColors.deepBotanical],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Wellness Guide",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Namaste, $_userName • Prakriti: $_dominantPrakriti",
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: "Reset Conversation",
            onPressed: _resetChat,
            color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
          ),
        ],
      ),
    );
  }

  // ─── Empty State with Suggested Chips ──────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? JeevanSutraColors.darkSurfaceElevated : JeevanSutraColors.softSage,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 32,
              color: JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Living Intelligence at Your Service",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ask about traditional Ayurveda, herbology, personalized diet, or Dinacharya routines.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "SUGGESTED EXPLORATIONS",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._suggestedPrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _sendMessage(prompt),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: JeevanSutraColors.freshLeaf),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prompt,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Chat Message Bubble ───────────────────────────────────────────────────

  Widget _buildMessageBubble(_ChatMessage msg, bool isDark) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: JeevanSutraColors.forestGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: JeevanSutraColors.forestGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
            ),
          ],
        ),
      );
    }

    // AI Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? JeevanSutraColors.darkSurfaceElevated : JeevanSutraColors.softSage,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 16, color: JeevanSutraColors.forestGreen),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.text.isEmpty && _isGenerating)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: JeevanSutraColors.forestGreen),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Consulting Vedic knowledge...",
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: JeevanSutraColors.secondaryText),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    MarkdownBody(
                      data: msg.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                        ),
                        h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: JeevanSutraColors.forestGreen),
                        h2: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: JeevanSutraColors.forestGreen),
                        listBullet: TextStyle(color: isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Copied to clipboard"), duration: Duration(seconds: 1)),
                          );
                        },
                        child: const Icon(Icons.copy_rounded, size: 14, color: JeevanSutraColors.secondaryText),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Input Bar ──────────────────────────────────────────────────────

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        border: Border(
          top: BorderSide(
            color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.warmIvory,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
                ),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: _sendMessage,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.mainText,
                ),
                decoration: InputDecoration(
                  hintText: "Ask Jeevan Sutra AI guide...",
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: JeevanSutraColors.forestGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: JeevanSutraColors.forestGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
