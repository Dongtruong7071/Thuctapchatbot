import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:ungdungchatbot/models/conversation.dart';
import 'package:ungdungchatbot/services/authen_service.dart';
import 'package:ungdungchatbot/services/n8n_service.dart';
import 'package:ungdungchatbot/services/supabase_service.dart';

import '../widgets/chat_app_bar.dart';

class ChatController extends ChangeNotifier {
  final AuthenService _authService;
  final SupabaseService _supabaseService;
  final ApiService _apiService;

  String? _selectedChatbot;
  String _selectedChat = 'Đoạn chat mới';
  bool _isNewChat = true;
  String? _currentSessionId;
  List<Conversation> chatGroups = [];
  List<Conversation> filteredChatGroups = [];
  List<Map<String, String>> messages = [];
  List<Map<String, String>> filteredMessages = [];
  String userId = '';
  String username = '';
  Future<List<String>>? modelNamesFuture;
  String searchKeyword = '';

  ChatController(this._authService, this._supabaseService, this._apiService) {
    filteredChatGroups = List.from(chatGroups);
    filteredMessages = List.from(messages);
    _initialize();
  }

  void _initialize() {
    modelNamesFuture = _supabaseService.getAIModelNames();
    modelNamesFuture?.then((modelNames) {
      if (modelNames.isNotEmpty && _selectedChatbot == null) {
        _selectedChatbot = modelNames[0];
        notifyListeners();
      }
    });
    _getUserId().then((_) {
      _loadConversations();
    });
  }

  Future<void> _getUserId() async {
    try {
      var userId = await _authService.getUserId();
      final displayName = await _authService.getDisplayName();
      if (userId != null) {
        userId = userId;
        username = displayName ?? '';
        notifyListeners();
      } else {
        userId = dotenv.env['USER_ID'] ?? '';
        print('Không tìm thấy người dùng, sử dụng userId từ .env: $userId');
      }
    } catch (error) {
      print('Lỗi khi lấy userId hoặc displayName: $error');
    }
  }

  Future<void> _loadConversations() async {
    final conversations = await _supabaseService.getConversations(userId);
    chatGroups = conversations;
    filteredChatGroups = List.from(chatGroups);
    if (chatGroups.isNotEmpty && _selectedChat == 'Đoạn chat mới') {
      _selectedChat = chatGroups[0].title ?? 'Đoạn chat mới';
      _currentSessionId = chatGroups[0].sessionId.toIso8601String();
      _isNewChat = false;
      await _loadMessages(chatGroups[0].sessionId.toIso8601String());
    }
    notifyListeners();
  }

  Future<void> _loadMessages(String sessionId) async {
    final messagesData = await _supabaseService.getMessages(sessionId, userId);
    messages = messagesData.map((msg) {
      final messageData = msg['message'] as Map<String, dynamic>;
      return [
        {
          'sender': 'bot',
          'text': messageData['answer'] as String,
          'model': (messageData['model'] as String?) ?? 'Unknown',
          'isLoading': 'false',
        },
        {
          'sender': 'user',
          'text': messageData['question'] as String,
          'model': '',
          'isLoading': 'false',
        },
      ];
    }).expand((pair) => pair).toList();
    filteredMessages = List.from(messages);
    notifyListeners();
  }

  Future<void> sendMessage({
    required TextEditingController messageController,
    required VoidCallback scrollToBottom,
    String? existingMessage,
    int? indexToReplace,
    required String systemPrompt,
    required String tone,
    required String responseLength,
  }) async {
    String message = existingMessage ?? messageController.text.trim();
    if (message.isNotEmpty && _selectedChatbot != null) {
      String currentSessionId = _currentSessionId ?? '';

      if (_isNewChat && existingMessage == null) {
        try {
          final conversation = await _supabaseService.createConversation(
            userId,
            title: _selectedChat,
          );
          chatGroups.insert(0, conversation);
          filteredChatGroups.insert(0, conversation);
          _isNewChat = false;
          _currentSessionId = conversation.sessionId.toIso8601String();
          currentSessionId = conversation.sessionId.toIso8601String();
          _selectedChat = conversation.title ?? 'Đoạn chat mới';
          notifyListeners();
        } catch (error) {
          throw 'Lỗi khi tạo đoạn chat: $error';
        }
      }

      if (existingMessage == null) {
        messages.insert(0, {
          'sender': 'user',
          'text': message,
          'model': '',
          'isLoading': 'false',
        });
        messages.insert(0, {
          'sender': 'bot',
          'text': 'Đang tải...',
          'model': _selectedChatbot!,
          'isLoading': 'true',
        });
        filteredMessages = List.from(messages);
        messageController.clear();
        scrollToBottom();
        notifyListeners();
      }

      // In giá trị cài đặt để kiểm tra
      print('Nhận được trong sendMessage: systemPrompt=$systemPrompt, tone=$tone, responseLength=$responseLength');

      double temperature;
      switch (tone) {
        case 'Nghiêm túc':
          temperature = 0.3;
          break;
        case 'Trung tính':
          temperature = 0.7;
          break;
        case 'Cảm xúc':
          temperature = 0.9;
          break;
        case 'Cường điệu':
          temperature = 1.0;
          break;
        default:
          temperature = 0.7;
          print('Tone không hợp lệ, sử dụng mặc định: $tone');
      }

      int maxTokens;
      switch (responseLength) {
        case 'Ngắn':
          maxTokens = 70;
          break;
        case 'Trung bình':
          maxTokens = 150;
          break;
        case 'Dài':
          maxTokens = 300;
          break;
        default:
          maxTokens = 150;
          print('ResponseLength không hợp lệ, sử dụng mặc định: $responseLength');
      }

      // In giá trị sau khi xử lý
      print('Sau khi xử lý: temperature=$temperature, maxTokens=$maxTokens');

      String botResponse = await _apiService.sendDataToN8n({
        'SessionId': currentSessionId,
        'chatbot': _selectedChatbot,
        'chatInput': message,
        'systemPrompt': tone == 'Cường điệu'
            ? '$systemPrompt Phóng đại tối đa để gây ấn tượng mạnh, ví dụ "Đây là thứ tuyệt vời nhất trên đời!!!"'
            : systemPrompt,
        'temperature': temperature,
        'maxTokens': maxTokens,
      });

      await _supabaseService.saveMessageToHistory(
        currentSessionId,
        userId,
        message,
        botResponse,
        _selectedChatbot!,
      );

      if (indexToReplace != null && indexToReplace >= 0) {
        messages[indexToReplace] = {
          'sender': 'bot',
          'text': botResponse,
          'model': _selectedChatbot!,
          'isLoading': 'false',
        };
      } else {
        final loadingIndex = messages.indexWhere(
                (msg) => msg['isLoading'] == 'true' && msg['sender'] == 'bot');
        if (loadingIndex != -1) {
          messages[loadingIndex] = {
            'sender': 'bot',
            'text': botResponse,
            'model': _selectedChatbot!,
            'isLoading': 'false',
          };
        } else {
          messages.insert(0, {
            'sender': 'bot',
            'text': botResponse,
            'model': _selectedChatbot!,
            'isLoading': 'false',
          });
        }
      }
      filteredMessages = List.from(messages);
      scrollToBottom();
      notifyListeners();

      if (existingMessage == null) {
        await _apiService.sendDataToN8n({
          'SessionId': currentSessionId,
          'chatbot': _selectedChatbot,
          'message': message,
          'systemPrompt': tone == 'Cường điệu'
              ? '$systemPrompt Phóng đại tối đa để gây ấn tượng mạnh, ví dụ "Đây là thứ tuyệt vời nhất trên đời!!!"'
              : systemPrompt,
          'temperature': temperature,
          'maxTokens': maxTokens,
        });
      }
    }
  }

  void reloadMessage(int index, VoidCallback scrollToBottom, BuildContext context) {
    final message = messages[index];
    if (message['sender'] == 'bot') {
      messages[index] = {
        'sender': 'bot',
        'text': 'Đang tải...',
        'model': _selectedChatbot!,
        'isLoading': 'true',
      };
      filteredMessages = List.from(messages);
      scrollToBottom();
      notifyListeners();

      final userMessageIndex = index + 1;
      if (userMessageIndex < messages.length &&
          messages[userMessageIndex]['sender'] == 'user') {
        final chatAppBarState = Provider.of<ChatAppBarState>(context, listen: false);
        final settings = chatAppBarState.getSettings();
        sendMessage(
          existingMessage: messages[userMessageIndex]['text'],
          indexToReplace: index,
          messageController: TextEditingController(),
          scrollToBottom: scrollToBottom,
          systemPrompt: settings['systemPrompt']!,
          tone: settings['tone']!,
          responseLength: settings['responseLength']!,
        );
      } else {
        for (int i = index + 1; i < messages.length; i++) {
          if (messages[i]['sender'] == 'user') {
            final chatAppBarState = Provider.of<ChatAppBarState>(context, listen: false);
            final settings = chatAppBarState.getSettings();
            sendMessage(
              existingMessage: messages[i]['text'],
              indexToReplace: index,
              messageController: TextEditingController(),
              scrollToBottom: scrollToBottom,
              systemPrompt: settings['systemPrompt']!,
              tone: settings['tone']!,
              responseLength: settings['responseLength']!,
            );
            break;
          }
        }
      }
    }
  }

  void searchChats(String keyword) {
    if (keyword.isEmpty) {
      filteredChatGroups = List.from(chatGroups);
    } else {
      filteredChatGroups = chatGroups
          .where((chat) =>
          (chat.title ?? '').toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void searchMessages(String keyword) {
    searchKeyword = keyword;
    if (keyword.isEmpty) {
      filteredMessages = List.from(messages);
    } else {
      filteredMessages = messages
          .where((msg) =>
          msg['text']!.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut(context);
    }
  }

  Future<void> renameChat(BuildContext context) async {
    if (_isNewChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng gửi tin nhắn trước khi đổi tên')),
      );
      return;
    }

    final controller = TextEditingController(text: _selectedChat);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên đoạn chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập tên mới'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      final success = await _supabaseService.renameConversation(
        userId,
        _currentSessionId!,
        newTitle,
      );
      if (success) {
        final index = chatGroups.indexWhere(
                (chat) => chat.sessionId.toIso8601String() == _currentSessionId);
        if (index != -1) {
          final updatedConversation = Conversation(
            sessionId: chatGroups[index].sessionId,
            createdAt: chatGroups[index].createdAt,
            userId: chatGroups[index].userId,
            title: newTitle,
          );
          chatGroups[index] = updatedConversation;
          filteredChatGroups[index] = updatedConversation;
        }
        _selectedChat = newTitle;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi tên đoạn chat thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi đổi tên đoạn chat')),
        );
      }
    }
  }

  Future<void> deleteChat(BuildContext context) async {
    if (_isNewChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có đoạn chat để xóa')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xóa đoạn chat "$_selectedChat"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success =
      await _supabaseService.deleteConversation(userId, _currentSessionId!);
      if (success) {
        chatGroups.removeWhere(
                (chat) => chat.sessionId.toIso8601String() == _currentSessionId);
        filteredChatGroups.removeWhere(
                (chat) => chat.sessionId.toIso8601String() == _currentSessionId);
        _selectedChat = 'Đoạn chat mới';
        _isNewChat = true;
        _currentSessionId = null;
        messages.clear();
        filteredMessages.clear();
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa đoạn chat thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi xóa đoạn chat')),
        );
      }
    }
  }

  Future<void> renameAccount(BuildContext context) async {
    final controller = TextEditingController(text: username);
    final newUsername = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên tài khoản'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập tên mới'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (newUsername != null && newUsername.isNotEmpty) {
      final authSuccess = await _authService.updateDisplayName(newUsername);
      final dbSuccess = await _supabaseService.updateUsername(userId, newUsername);
      if (authSuccess && dbSuccess) {
        username = newUsername;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi tên tài khoản thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi đổi tên tài khoản')),
        );
      }
    }
  }

  void startNewChat() {
    messages.clear();
    filteredMessages.clear();
    _selectedChat = 'Đoạn chat mới';
    _isNewChat = true;
    _currentSessionId = null;
    notifyListeners();
  }

  void selectChat(Conversation chat) {
    _selectedChat = chat.title ?? 'Đoạn chat mới';
    _currentSessionId = chat.sessionId.toIso8601String();
    _isNewChat = false;
    _loadMessages(chat.sessionId.toIso8601String());
    notifyListeners();
  }

  String? get selectedChatbot => _selectedChatbot;
  String get selectedChat => _selectedChat;
  bool get isNewChat => _isNewChat;
  String? get currentSessionId => _currentSessionId;
  set selectedChatbot(String? value) {
    _selectedChatbot = value;
    notifyListeners();
  }
}