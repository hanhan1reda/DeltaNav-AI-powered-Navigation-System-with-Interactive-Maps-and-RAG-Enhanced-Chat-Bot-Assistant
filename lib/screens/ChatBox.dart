import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Zain',
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  Future<String> getAIResponse(String userInput) async {
    final String? apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      print('Error: API Key is missing in .env file');
      return 'Error: Missing API Key';
    }
    final String apiUrl =
        'https://api-inference.huggingface.co/models/distilgpt2';

    try {
      print('Sending request to API with input: $userInput');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': userInput,
          'parameters': {'max_length': 50, 'temperature': 0.7},
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]['generated_text'].trim();
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      print('API Error: $e');
      return 'Error: $e';
    }
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    String timestamp = DateFormat('hh:mm a').format(DateTime.now());
    setState(() {
      messages.add({"sender": "user", "text": text, "time": timestamp});
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    String aiResponse = await getAIResponse(text);
    setState(() {
      messages.add({"sender": "bot", "text": aiResponse, "time": timestamp});
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    _controller.clear();
    _focusNode.requestFocus(); // Keep focus on TextField
  }

  void _clearChat() {
    setState(() {
      messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Deep blue
              Color(0xFF60A5FA), // Light blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [_buildAppBar(), _buildChatArea(), _buildInputArea()],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text(
            "AI Campus Assistant",
            style: TextStyle(
              fontFamily: 'Zain',
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: _clearChat,
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoading && index == messages.length) {
            return TypingIndicator();
          }
          final message = messages[index];
          return ChatBubble(
            text: message["text"]!,
            time: message["time"]!,
            isUser: message["sender"] == "user",
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: "Ask about your campus...",
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'Zain',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(fontFamily: 'Zain', fontSize: 16),
              onSubmitted: (text) {
                _sendMessage(text);
                print('Submitted: $text'); // Debug
              },
              autofocus: true,
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _controller.text.isNotEmpty
                      ? Color(0xFF1E40AF)
                      : Colors.grey.shade400,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed:
                  _controller.text.isNotEmpty
                      ? () => _sendMessage(_controller.text)
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isUser;

  const ChatBubble({
    required this.text,
    required this.time,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Color(0xFF60A5FA) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: isUser ? Radius.circular(20) : Radius.circular(0),
            bottomRight: isUser ? Radius.circular(0) : Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Zain',
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Zain',
                color: isUser ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(context),
            SizedBox(width: 4),
            _buildDot(context, delay: 0.2),
            SizedBox(width: 4),
            _buildDot(context, delay: 0.4),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(BuildContext context, {double delay = 0.0}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Color(0xFF1E40AF),
        shape: BoxShape.circle,
      ),
      child: FadeTransition(
        opacity: _createDotAnimation(context, delay),
        child: Container(),
      ),
    );
  }

  Animation<double> _createDotAnimation(BuildContext context, double delay) {
    final controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: TickerProviderImpl(),
    )..repeat(reverse: true);
    return Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }
}

class TickerProviderImpl extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
