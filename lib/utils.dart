import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String currentUser = FirebaseAuth.instance.currentUser!.uid;

CollectionReference usersCollection =
    FirebaseFirestore.instance.collection("users");

CollectionReference chatsCollection({required String user}) {
  return usersCollection.doc(user).collection("chats");
}

CollectionReference messagesCollection(
    {required String user, required String chat}) {
  return chatsCollection(user: user).doc(chat).collection("messages");
}

Stream<DocumentSnapshot> userData({required String id}) async* {
  yield await usersCollection.doc(id).get();
}

Stream<List<DocumentSnapshot>> usersData() async* {
  List<DocumentSnapshot> users = [];
  await usersCollection.get().then(
    (value) {
      if (value.docs.isNotEmpty) {
        for (var element in value.docs) {
          users.add(element);
        }
      }
    },
  );
  
  yield users;
}

String formatChatDateTime(
    {required DateTime dateTime, required BuildContext context}) {
  final now = DateTime.now();
  bool is24HoursFormat = MediaQuery.of(context).alwaysUse24HourFormat;

  String formattedTime = is24HoursFormat
      ? DateFormat.Hm().format(dateTime)
      : DateFormat('h:mm a').format(dateTime);

  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    return formattedTime;
  }

  final yesterday = now.subtract(const Duration(days: 1));
  if (dateTime.year == yesterday.year &&
      dateTime.month == yesterday.month &&
      dateTime.day == yesterday.day) {
    return 'Yesterday, $formattedTime';
  }

  return DateFormat('MMM d').format(dateTime);
}

double deviceHeight({required BuildContext context}) {
  return MediaQuery.of(context).size.height;
}

double deviceWidth({required BuildContext context}) {
  return MediaQuery.of(context).size.width;
}
