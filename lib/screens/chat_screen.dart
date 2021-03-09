import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firebase = Firestore();
final _auth = FirebaseAuth.instance;

class ChatScreen extends StatefulWidget {
  static const route = "chat_screen";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController textController = TextEditingController();
  FirebaseUser loggedUser;
  String message;

  void getCurrentUser() async {
    final user = await _auth.currentUser();
    setState(() {
      loggedUser = user;
    });
    if (loggedUser == null) {
      Navigator.pushNamed(context, WelcomeScreen.route);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilderBubbles(
              user: loggedUser,
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textController,
                      onChanged: (value) {
                        setState(() {
                          message = value;
                        });
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      textController.clear();
                      try {
                        if (message.isNotEmpty)
                          firebase.collection("message").add(
                              {"text": message, "sender": loggedUser.email});
                      } catch (e) {
                        print("error al momento de guardar un msaje");
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  MessageBubble({@required this.text, this.sender, this.isMe});

  BorderRadius generateBorders() {
    if (isMe) {
      return BorderRadius.only(
        topLeft: Radius.circular(30.0),
        bottomLeft: Radius.circular(30.0),
        bottomRight: Radius.circular(30.0),
      );
    } else {
      return BorderRadius.only(
        topRight: Radius.circular(30.0),
        bottomLeft: Radius.circular(30.0),
        bottomRight: Radius.circular(30.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(color: Colors.grey.shade800),
          ),
          Material(
            elevation: 5.0,
            borderRadius: generateBorders(),
            color: isMe ? Colors.lightBlue : Colors.grey,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
              child: Text(
                '$text',
                style: TextStyle(fontSize: 15.0, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamBuilderBubbles extends StatelessWidget {
  final FirebaseUser user;
  StreamBuilderBubbles({this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firebase.collection("message").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlue,
            ),
          );
        }
        List<MessageBubble> messagesList = [];
        for (DocumentSnapshot document in snapshot.data.documents.reversed) {
          print("usuario : " + user.toString());
          messagesList.add(MessageBubble(
              text: document.data["text"],
              sender: document.data["sender"],
              isMe: user != null
                  ? user.email == document.data["sender"]
                  : true //user.email == document.data["sender"],
              ));
        }
        return ListView(
          reverse: true,
          shrinkWrap: true,
          children: messagesList,
        );
      },
    );
  }
}

//  void getMessagesFromDB() async {
//    final snapshot = await _firebase.collection("message").getDocuments();
//    for (var document in snapshot.documents) {
//      print(document.data);
//    }
//  }
//
//  void getStreamDocuments() async {
//    await for (var snapshot in _firebase.collection("message").snapshots()) {
//     for(var document in snapshot.documents){
//       print(document.data;
//     }
//    }
//  }
