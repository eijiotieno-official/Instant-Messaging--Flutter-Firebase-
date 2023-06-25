import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_chat/models/message_model.dart';
import 'package:my_chat/models/user_model.dart';
import 'package:my_chat/services/chat_services.dart';
import 'package:my_chat/utils.dart';
import 'package:my_chat/widgets/user_photo.dart';

class ChatPage extends StatefulWidget {
  final bool fromHome;
  final UserModel user;
  const ChatPage({super.key, required this.fromHome, required this.user});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController textEditingController = TextEditingController();
  ChatServices chatServices = ChatServices();
  List<MessageModel> messages = [];
  Stream<QuerySnapshot>? messagesStream;
  StreamSubscription<QuerySnapshot>? messagesSubscription;

  Stream<QuerySnapshot> getMessagesStream() {
    Stream<QuerySnapshot> stream =
        messagesCollection(user: currentUser, chat: widget.user.id)
            .orderBy('time', descending: true)
            .snapshots();
    return stream;
  }

  @override
  void initState() {
    super.initState();
    messagesStream = getMessagesStream();
    messagesSubscription = messagesStream!.listen(
      (snapshot) {
        setState(() {
          messages = [];
        });
        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            MessageModel message = MessageModel(
              id: doc['id'],
              sender: doc['sender'],
              receiver: doc['receiver'],
              text: doc['text'],
              time: doc['time'].toDate(),
            );
            if (messages.contains(message) == false) {
              setState(() {
                messages.add(message);
              });
            }
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.fromHome) {
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
          Navigator.pop(context);
        }
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                if (widget.fromHome) {
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
            ),
            title: ListTile(
              leading: userPhoto(radius: 18, url: widget.user.photo),
              title: Text(
                widget.user.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
              subtitle: Text(
                widget.user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.8),
                  fontSize: 15,
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          "No messages",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.8),
                            fontSize: 25,
                          ),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return messageWidget(message: messages[index]);
                        },
                      ),
              ),
              chatMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget messageWidget({required MessageModel message}) {
    return Align(
      alignment: message.sender == currentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 4,
          left: 8,
          right: 8,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: deviceWidth(context: context) * 0.8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: message.sender == currentUser ? Colors.white : Colors.blue,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 8,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color:
                    message.sender == currentUser ? Colors.black : Colors.white,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget chatMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: TextField(
                              maxLines: null,
                              style: TextStyle(
                                color: Colors.transparent,
                                fontSize: 18,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        Scrollbar(
                          radius: const Radius.circular(5),
                          child: TextField(
                            controller: textEditingController,
                            maxLines: 10,
                            minLines: 1,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              border: InputBorder.none,
                              hintText: "Message",
                              hintStyle: TextStyle(
                                color: Colors.black.withOpacity(0.4),
                                fontSize: deviceWidth(context: context) * 0.05,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: const IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.transparent,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (textEditingController.text.trim().isNotEmpty) {
                        chatServices.sendTextMessage(
                            receiver: widget.user.id,
                            text: textEditingController.text.trim());
                        setState(() {
                          textEditingController.clear();
                        });
                      }
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: const IconButton(
                        onPressed: null,
                        icon: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
