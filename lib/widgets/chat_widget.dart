import 'package:flutter/material.dart';
import 'package:my_chat/models/chat_model.dart';
import 'package:my_chat/models/message_model.dart';
import 'package:my_chat/models/user_model.dart';
import 'package:my_chat/pages/chat_page.dart';
import 'package:my_chat/utils.dart';
import 'package:my_chat/widgets/user_photo.dart';

Widget chatWidget({required ChatModel chat}) {
  return StreamBuilder(
    stream: messagesCollection(user: currentUser, chat: chat.user)
        .orderBy('time', descending: true)
        .snapshots(),
    builder: (context, messageSnapshot) {
      if (messageSnapshot.hasData) {
        MessageModel lastMessage = MessageModel(
          id: messageSnapshot.data!.docs.first['id'],
          sender: messageSnapshot.data!.docs.first['sender'],
          receiver: messageSnapshot.data!.docs.first['receiver'],
          text: messageSnapshot.data!.docs.first['text'],
          time: messageSnapshot.data!.docs.first['time'].toDate(),
        );

        return StreamBuilder(
          stream: userData(id: chat.user),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasData) {
              UserModel userModel = UserModel(
                  id: userSnapshot.data!['id'],
                  name: userSnapshot.data!['name'],
                  photo: userSnapshot.data!['photo'],
                  email: userSnapshot.data!['email']);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ChatPage(fromHome: true, user: userModel);
                      },
                    ),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black12,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: userPhoto(radius: 20, url: userModel.photo),
                    title: Text(
                      userModel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        timeStatus(lastMessage: lastMessage, context: context),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      }
      return const SizedBox.shrink();
    },
  );
}

timeStatus({required MessageModel lastMessage, required BuildContext context}) {
  return Padding(
    padding: const EdgeInsets.only(left: 5),
    child: Text(
      formatChatDateTime(dateTime: lastMessage.time, context: context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black.withOpacity(0.5),
        fontSize: 15,
      ),
    ),
  );
}
