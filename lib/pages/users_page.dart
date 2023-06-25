import 'package:flutter/material.dart';
import 'package:my_chat/models/user_model.dart';
import 'package:my_chat/pages/chat_page.dart';
import 'package:my_chat/utils.dart';
import 'package:my_chat/widgets/user_photo.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Available Users"),
        ),
        body: StreamBuilder(
          stream: usersData(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  UserModel user = UserModel(
                      id: snapshot.data![index]['id'],
                      name: snapshot.data![index]['name'],
                      photo: snapshot.data![index]['photo'],
                      email: snapshot.data![index]['email']);
                  return user.id == currentUser
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return ChatPage(
                                        fromHome: false, user: user);
                                  },
                                ),
                              );
                            },
                            child: ListTile(
                              leading: userPhoto(radius: 20, url: user.photo),
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                              ),
                              subtitle: Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.8),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        );
                },
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
