import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false; // Tránh khởi tạo lại nhiều lần

  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!_isInitialized) {
      try {
        await Supabase.initialize(
          url: 'https://wlbxtgykexnmlgrmoxig.supabase.co',
          anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndsYnh0Z3lrZXhubWxncm1veGlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI0Njc2MzAsImV4cCI6MjA1ODA0MzYzMH0.vvMuTIcoxxGZ9-audV25WIaSf2wK7J3yQt_cvfqcupI',
        );
        _isInitialized = true;
        print('Supabase đã khởi tạo thành công');
      } catch (error) {
        print('Lỗi khởi tạo Supabase: $error');
      }
    } else {
      print('Supabase đã được khởi tạo trước đó');
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  /// Lấy danh sách name từ bảng ai_models
  Future<List<String>> getAIModelNames() async {
    try {
      final response = await client.from('ai_models').select('name');
      final List<String> modelNames =
      (response as List).map((item) => item['name'] as String).toList();
      return modelNames;
    } catch (error) {
      print('Lỗi khi lấy danh sách tên AI models: $error');
      return [];
    }
  }

  /// Tạo một đoạn chat mới
  Future<Conversation> createConversation(String userId, {String? title}) async {
    try {
      final newConversation = Conversation(
        sessionId: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        userId: userId,
        title: title ?? 'Đoạn chat mới',
      );

      final response = await client
          .from('conversations')
          .insert(newConversation.toJson())
          .select()
          .single();

      return Conversation.fromJson(response);
    } catch (error) {
      print('Lỗi khi tạo đoạn chat: $error');
      throw Exception('Không thể tạo đoạn chat: $error');
    }
  }

  /// Thêm một đoạn chat
  Future<Conversation> addConversation(Conversation conversation) async {
    try {
      final response = await client
          .from('conversations')
          .insert(conversation.toJson())
          .select()
          .single();

      return Conversation.fromJson(response);
    } catch (error) {
      print('Lỗi khi thêm đoạn chat: $error');
      throw Exception('Không thể thêm đoạn chat: $error');
    }
  }

  /// Đổi tên đoạn chat
  Future<bool> renameConversation(String userId, String sessionId, String newTitle) async {
    try {
      await client
          .from('conversations')
          .update({'title': newTitle})
          .eq('user_id', userId)
          .eq('session_id', sessionId);
      print('Đổi tên đoạn chat thành công: $newTitle');
      return true;
    } catch (error) {
      print('Lỗi khi đổi tên đoạn chat: $error');
      return false;
    }
  }

  /// Xóa đoạn chat
  Future<bool> deleteConversation(String userId, String sessionId) async {
    try {
      await client
          .from('conversations')
          .delete()
          .eq('user_id', userId)
          .eq('session_id', sessionId);
      print('Xóa đoạn chat thành công: $sessionId');
      return true;
    } catch (error) {
      print('Lỗi khi xóa đoạn chat: $error');
      return false;
    }
  }

  /// Lấy danh sách đoạn chat
  Future<List<Conversation>> getConversations(String userId) async {
    try {
      final response = await client
          .from('conversations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((item) => Conversation.fromJson(item)).toList();
    } catch (error) {
      print('Lỗi khi lấy danh sách đoạn chat: $error');
      return [];
    }
  }

  /// Tạo người dùng trong bảng users
  Future<bool> createUser(String userId, {String? username, String? email}) async {
    try {
      final response = await client.from('users').insert({
        'id': userId,
        'username': username,
        'email': email,
      }).select().single();

      print('Tạo người dùng thành công: ${response['id']}');
      return true;
    } catch (error) {
      print('Lỗi khi tạo người dùng: $error');
      return false;
    }
  }

  /// Cập nhật username trong bảng users
  Future<bool> updateUsername(String userId, String newUsername) async {
    try {
      final response = await client
          .from('users')
          .update({'username': newUsername})
          .eq('id', userId)
          .select()
          .single();

      print('Cập nhật username thành công: ${response['username']}');
      return true;
    } catch (error) {
      print('Lỗi khi cập nhật username: $error');
      return false;
    }
  }

  /// Lưu lịch sử
  Future<bool> saveMessageToHistory(
      String sessionId, String userId, String question, String answer, String model) async {
    try {
      final messageJson = {
        'answer': answer,
        'question': question,
        'model': model,
      };

      await client.from('histories').insert({
        'session_id': sessionId,
        'user_id': userId,
        'message': messageJson,
      });

      return true;
    } catch (error) {
      print('Lỗi khi lưu tin nhắn vào histories: $error');
      return false;
    }
  }

  /// Lấy lịch sử tin nhắn
  Future<List<Map<String, dynamic>>> getMessages(String sessionId, String userId) async {
    try {
      final response = await client
          .from('histories')
          .select('created_at, message')
          .eq('session_id', sessionId)
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('Lỗi khi lấy tin nhắn: $error');
      return [];
    }
  }
}