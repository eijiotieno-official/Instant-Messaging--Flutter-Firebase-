class MessageModel {
  String id;
  String sender;
  String receiver;
  String text;
  DateTime time;

  MessageModel(
      {required this.id,
      required this.sender,
      required this.receiver,
      required this.text,
      required this.time});
}
