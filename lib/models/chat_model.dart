import 'package:my_chat/models/message_model.dart';

class ChatModel {
  String user;
  List<MessageModel> messages;

  ChatModel({required this.user, required this.messages});
}