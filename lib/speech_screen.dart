import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_assistant/colors.dart';

import 'chat_model.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final Gemini gemini = Gemini.instance;

  SpeechToText speechToText = SpeechToText();

  var text = "Hold the button and start speaking";
  var isListening = false;

  List<ChatMessage> messages = [];

  var scrollController = ScrollController();

  scrollMethod() {
    scrollController.animateTo(scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButtonLocation: CustomFabLocation(),
      floatingActionButton: AvatarGlow(
        animate: isListening,
        glowColor: bgColor,
        repeat: true,
        glowRadiusFactor: 0.6,
        glowCount: 3,
        duration: const Duration(milliseconds: 1500),
        child: GestureDetector(
          onTapDown: (details) async {
            if (!isListening) {
              var available = await speechToText.initialize();
              if (available) {
                setState(() {
                  isListening = true;
                  speechToText.listen(onResult: (result) {
                    setState(() {
                      text = result.recognizedWords;
                    });
                  });
                });
              }
            }
          },
          onTapUp: (details) async {
            setState(() {
              isListening = false;
            });
            speechToText.stop();

            ChatMessage userText =
                ChatMessage(text: text, type: ChatMessageType.user);
            messages = [userText, ...messages];

            try {
              gemini.streamGenerateContent(text).listen((event) {
                ChatMessage? lastMessage = messages.firstOrNull;
                if (lastMessage != null &&
                    lastMessage.type == ChatMessageType.bot) {
                  lastMessage = messages.removeAt(0);
                  String res = event.content?.parts?.fold("",
                          (previous, current) => "$previous ${current.text}") ??
                      "";
                  lastMessage.text = (lastMessage.text ?? '') + res;
                  setState(() {
                    messages = [lastMessage!, ...messages];
                  });
                } else {
                  String res = event.content?.parts?.fold("",
                          (previous, current) => "$previous ${current.text}") ??
                      "";
                  ChatMessage msg =
                      ChatMessage(text: res, type: ChatMessageType.bot);
                  setState(() {
                    messages = [msg, ...messages];
                  });
                }
              });
            } catch (e) {
              // ignore: avoid_print
              print(e);
            }
          },
          child: CircleAvatar(
            backgroundColor: bgColor,
            radius: 35,
            child: Icon(isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white),
          ),
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0.0,
        title: const Text(
          "AI ChatApp",
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                  fontSize: 24,
                  color: isListening ? Colors.black87 : Colors.black54,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: chatBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: scrollController,
                    shrinkWrap: true,
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      var chat = messages[messages.length - index - 1];

                      return chatBubble(chattext: chat.text, type: chat.type);
                    }),
              ),
            ),
            const SizedBox(height: 75),
            const Text(
              "Developed by ASR",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

Widget chatBubble({required chattext, required ChatMessageType? type}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        backgroundColor:
            type == ChatMessageType.bot ? Colors.transparent : bgColor,
        child: type == ChatMessageType.bot
            ? Container(
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(30)),
                child: Image.asset('assets/icon.png'),
              )
            : const Icon(
                Icons.person,
                color: Colors.white,
              ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: type == ChatMessageType.bot ? bgColor : Colors.white,
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12)),
          ),
          child: Text(
            "$chattext",
            style: TextStyle(
              color: type == ChatMessageType.bot ? textColor : chatBgColor,
              fontSize: 15,
              fontWeight: type == ChatMessageType.bot
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    ],
  );
}

class CustomFabLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    double fabX = (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2;
    double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        40;
    return Offset(fabX, fabY);
  }
}
