const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

//TRIGGERED WHEN A NEW DOCUMENT IS CREATED IN MESSAGES COLLECTION
exports.sendMessage = functions.firestore
  .document("users/{user_id}/chats/{chat_id}/messages/{message_id}")
  .onCreate(async (messageSnapshot, context) => {
    //DOCUMENT DETAILS
    const message = messageSnapshot.data();

    //WE WILL NEED THE RECEIVER'S TOKENS SO THAT WE CAN SEND A NOTIFICATION TO ALL DEVICES THEY ARE REGISTERED IN.
    var receiverTokens = [];

    //STORE THE SENDER'S DATA
    var senderData;

    //FIND THE SENDER AND RECEIVER DETAILS SUCH AS; TOKENS, NAME, PHOTO
    await admin
      .firestore()
      .collection("users")
      .get()
      .then((r) => {
        if (r.empty) {
          console.log("No matching documents.");
          return;
        }
        r.forEach((doc) => {
          //RECEIVER TOKENS
          if (doc.id == message.receiver) {
            for (let t = 0; t < doc.data().tokens.length; t++) {
              const element = doc.data().tokens[t];
              receiverTokens.push(element);
            }
          }
          //SENDER DETAILS THAT WE WILL USE TO DISPLAY IN THE NOTIFICATION WHEN SENT
          if (doc.id == message.sender) {
            senderData = doc.data();
          }
        });
      });

      //THIS IS THE DATA THE NOTIFICATION WILL HOLD, IF YOU INCLUDE NOTIFICATION HERE, FCM WILL TRIGGER DEFAULT NOTIFICATION WHICH IS UGLY, SO WE WILL USE OUR OWN CUSTOM ONE.
    var receiverMessagePayload = {
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        user: senderData.id,
        photo: senderData.photo,
        name: senderData.name,
        email: senderData.email,
        id: message.id,
        text: message.text,
        sender: message.sender,
        receiver: message.receiver,
      },
    };

    //ONLY SEND A NOTIFICATION WHEN THE DOCUMENT CREATED HASN'T BEEN SENT YET ELSE IT WILL SEND NOTIFICATION TWICE SINCE HERE WE ARE GOING TO CREATE THAT MESSAGE TO THE RECEIVER
    if (message.sent == false) {
      //AVOID SENDING A NOTIFICATION TO THE SENDER THEN WE UPDATE THAT DOCUMENT SENT FIELD TO TRUE
      if (message.receiver != message.sender) {
        await db
          .collection("users")
          .doc(message.sender)
          .collection("chats")
          .doc(message.receiver)
          .collection("messages")
          .doc(message.id)
          .update({
            sent: true,
          })
          .then(async () => {
            //CREATE FOR RECEIVER
            await db
              .collection("users")
              .doc(message.receiver)
              .collection("chats")
              .doc(message.sender)
              .collection("messages")
              .doc(message.id)
              .set({
                id: message.id,
                text: message.text,
                receiver: message.receiver,
                sender: message.sender,
                time: message.time,
                sent: true,
              })
              .then(async () => {
                //SEND NOTIFICATION TO RECEIVER
                await admin
                  .messaging()
                  .sendToDevice(receiverTokens, receiverMessagePayload);
              });
          });
      }
    }
  });
