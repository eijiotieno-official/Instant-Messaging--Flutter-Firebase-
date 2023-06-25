import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_chat/pages/home.dart';
import 'package:my_chat/utils.dart';

class AuthServices {
  Future authenticateUser({required BuildContext context}) async {
    await signInWithGoogle().then(
      (UserCredential userCredential) async {
        await userExists(id: currentUser).then(
          (exists) async {
            if (exists) {
              FirebaseMessaging.instance.getToken().then(
                (token) async {
                  await usersCollection.doc(currentUser).update(
                    {
                      'tokens': FieldValue.arrayUnion([token]),
                    },
                  );
                },
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const Home(receivedAction: null);
                  },
                ),
              );
            } else {
              await createUser(userCredential: userCredential).then(
                (created) {
                  if (created) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const Home(receivedAction: null);
                        },
                      ),
                    );
                  }
                },
              );
            }
          },
        );
      },
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<bool> createUser({required UserCredential userCredential}) async {
    bool created = false;
    await FirebaseMessaging.instance.getToken().then(
      (token) async {
        await usersCollection.doc(currentUser).set(
          {
            'id': userCredential.user?.uid,
            'name': userCredential.user?.displayName,
            'email': userCredential.user?.email,
            'photo': userCredential.user?.photoURL,
            'tokens': [token],
          },
        ).then((value) async {
          created = true;
          await chatsCollection(user: currentUser).doc(currentUser).set(
            {
              'id': currentUser,
            },
          );
        });
      },
    );
    return created;
  }

  Future<bool> userExists({required String id}) async {
    bool exists = false;
    await usersCollection.where('id', isEqualTo: id).get().then(
      (user) {
        if (user.docs.isEmpty) {
          exists = false;
        } else {
          exists = true;
        }
      },
    );
    return exists;
  }
}
