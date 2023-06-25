import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_chat/utils.dart';

class ChatServices {
  sendTextMessage({required String receiver, required String text}) {
    //SENDER
    DocumentReference chatDocRef =
        chatsCollection(user: currentUser).doc(receiver);
    chatDocRef.set(
      {
        'id': chatDocRef.id,
      },
    );

    //RECEIVER
    DocumentReference receiverChatDocRef =
        chatsCollection(user: receiver).doc(currentUser);

    receiverChatDocRef.set(
      {
        'id': receiverChatDocRef.id,
      },
    );

    DocumentReference messageDocRef =
        messagesCollection(user: currentUser, chat: receiver).doc();

    messageDocRef.set(
      {
        'id': messageDocRef.id,
        'text': text,
        'sender': currentUser,
        'receiver': receiver,
        'time': DateTime.now(),
        'sent': false,
      },
    );
  }
}
