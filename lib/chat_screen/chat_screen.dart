import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat_flutter/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
late User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String? messageText;

  getCurrentUser() {
    try {
      if (_auth.currentUser != null) {
        loggedInUser = _auth.currentUser!;
      }
    } on Exception catch (e) {
      // TODO
      print(e);
    }
  }

  // void getMessages() async {
  //   try {
  //     final messages = await _firestore.collection('messages').get();
  //     if (messages != null) {
  //       for (var message in messages.docs) {
  //         print(message.data());
  //       }
  //     }
  //
  //     setState(() {
  //       _spinnerState = false;
  //     });
  //   } on Exception catch (e) {
  //     // TODO
  //     print(e);
  //   }
  // }

  void messagesStream() async {
    try {
      await for (var snapshot
          in _firestore.collection('messages').snapshots()) {
        if (!snapshot.docs.isEmpty) {
          // setState(() {
          //   _spinnerState = false;
          // });
          for (var message in snapshot.docs.reversed) {
            print(message.data());
          }
        }
      }
    } on Exception catch (e) {
      // TODO
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
    setState(() {
      //  _spinnerState = true;
    });
    //getMessages();
    messagesStream();
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
                //Implement logout functionality
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
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  MaterialButton(
                    onPressed: () {
                      //Implement send functionality.
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'date': DateTime.now()
                      });
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

class MessageStream extends StatelessWidget {
  const MessageStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _firestore
            .collection('messages')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.grey,
              ),
            );
          }

          final messages = snapshot.data?.docs;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages!) {
            final messageText = message.data()['text'];
            final messageSender = message.data()['sender'];
            final currentUser = loggedInUser;

            final messageBubble = MessageBubble(
              sender: messageSender,
              msg: messageText,
              isMe: messageSender == currentUser.email,
            );

            messageBubbles.add(messageBubble);
          }
          return Expanded(
              child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
            children: messageBubbles,
          ));
        });
  }
}

class MessageBubble extends StatelessWidget {
  final String? sender;
  final String? msg;
  final bool isMe;

  const MessageBubble({Key? key, this.sender, this.msg, required this.isMe})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            '$sender',
            style: TextStyle(fontSize: 12.0, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0)),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                '$msg',
                style: TextStyle(
                    fontSize: 15.0, color: isMe ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
