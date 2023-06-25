import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_chat/models/chat_model.dart';
import 'package:my_chat/models/message_model.dart';
import 'package:my_chat/models/user_model.dart';
import 'package:my_chat/pages/chat_page.dart';
import 'package:my_chat/pages/users_page.dart';
import 'package:my_chat/utils.dart';
import 'package:my_chat/widgets/chat_widget.dart';
import 'package:my_chat/widgets/user_photo.dart';

class Home extends StatefulWidget {
  final ReceivedAction? receivedAction;
  const Home({super.key, required this.receivedAction});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<ChatModel> chats = [];
  Stream<QuerySnapshot>? chatsStream;
  StreamSubscription<QuerySnapshot>? chatsSubscription;
  Stream<QuerySnapshot> getChatsStream() {
    Stream<QuerySnapshot> stream =
        chatsCollection(user: currentUser).snapshots();
    return stream;
  }

  Future streamChats() async {
    chatsStream = getChatsStream();
    chatsSubscription = chatsStream!.listen(
      (chatSnapshot) {
        setState(() {
          chats = [];
        });
        if (chatSnapshot.docs.isNotEmpty) {
          for (var chat in chatSnapshot.docs) {
            if (chat['id'] != currentUser) {
              messagesCollection(user: currentUser, chat: chat['id'])
                  .orderBy('time', descending: false)
                  .get()
                  .then(
                (m) {
                  if (m.docs.isNotEmpty) {
                    List<MessageModel> messages = [];
                    for (var message in m.docs) {
                      setState(() {
                        messages.add(
                          MessageModel(
                            id: message['id'],
                            sender: message['sender'],
                            receiver: message['receiver'],
                            text: message['text'],
                            time: message['time'].toDate(),
                          ),
                        );
                      });
                    }
                    if (messages.isNotEmpty) {
                      ChatModel chatModel =
                          ChatModel(user: chat['id'], messages: messages);
                      if (m.docs.isNotEmpty &&
                          chats.contains(chatModel) == false) {
                        setState(() {
                          chats.add(chatModel);
                        });
                      }
                    }
                  }
                },
              );
            }
          }
        }
      },
    );
  }

  handleNotification() {
    if (widget.receivedAction != null) {
      Map userMap = widget.receivedAction!.payload!;
      UserModel user = UserModel(
          id: userMap['user'],
          name: userMap['name'],
          photo: userMap['photo'],
          email: userMap['email']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ChatPage(fromHome: true, user: user);
          },
        ),
      );
    }
  }

  @override
  void initState() {
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        usersCollection.doc(currentUser).update(
          {
            'tokens': FieldValue.arrayUnion([newToken]),
          },
        );
      },
    );

    super.initState();
    streamChats().then(
      (value) async {
        await Future.delayed(const Duration(milliseconds: 1000)).then(
          (value) {
            handleNotification();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: userData(id: currentUser),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserModel currentUserModel = UserModel(
                id: snapshot.data?['id'],
                name: snapshot.data?['name'],
                photo: snapshot.data?['photo'],
                email: snapshot.data?['email']);
            return SafeArea(
              child: Scaffold(
                appBar: AppBar(
                  leading: Center(
                      child:
                          userPhoto(radius: 15, url: currentUserModel.photo)),
                  title: const Text("my_chat"),
                ),
                body: chats.isEmpty
                    ? Center(
                        child: Text(
                          "No chats",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontSize: 20,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: chats.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return chatWidget(chat: chats[index]);
                        },
                      ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const UsersPage();
                        },
                      ),
                    );
                  },
                  child: const Icon(Ionicons.chatbubbles),
                ),
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}
