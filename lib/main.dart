import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEEF1F8),
        primarySwatch: Colors.blue,
        fontFamily: 'Arvo',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(height: 0),
          border: defaultInputBorder,
          enabledBorder: defaultInputBorder,
          focusedBorder: defaultInputBorder,
          errorBorder: defaultInputBorder,
        ),
      ),
      home: HomePage(),
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);

class Comment {
  final String text;
  final String timestamp;

  Comment({required this.text, required this.timestamp});

  Map<String, String> toJson() => {'text': text, 'timestamp': timestamp};

  static Comment fromJson(Map<String, dynamic> json) =>
      Comment(text: json['text'], timestamp: json['timestamp']);
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final List<Comment> _comments = [];
  Offset _iconPosition = Offset(20, 20);
  final Map<String, TextEditingController> _textControllers = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animationController.forward();
    _loadSavedData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _iconPosition = Offset(
        prefs.getDouble('icon_dx') ?? 20.0,
        prefs.getDouble('icon_dy') ?? 100.0,
      );
    });

    final commentsJson = prefs.getString('comments');
    if (commentsJson != null) {
      final List<dynamic> commentsList = jsonDecode(commentsJson);
      setState(() {
        _comments.addAll(
            commentsList.map((item) => Comment.fromJson(item)).toList());
      });
    }

    for (int i = 1; i <= 5; i++) {
      final fieldData = prefs.getString('textField_$i') ?? '';
      _textControllers['textField_$i'] = TextEditingController(text: fieldData);
    }
  }

  Future<void> _saveIconPosition(Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('icon_dx', position.dx);
    await prefs.setDouble('icon_dy', position.dy);
  }

  Future<void> _saveComments() async {
    final prefs = await SharedPreferences.getInstance();
    final commentsJson = jsonEncode(_comments.map((e) => e.toJson()).toList());
    await prefs.setString('comments', commentsJson);
  }

  Future<void> _saveFieldData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void _addComment(String comment) {
    if (comment.isNotEmpty) {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      setState(() {
        _comments.add(Comment(text: comment, timestamp: timestamp));
      });
      _saveComments();
    }
  }

  void _showScrollableWindow() {
    Get.bottomSheet(
      Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Logged Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.comment),
                    title: Text(_comments[index].text),
                    subtitle: Text(_comments[index].timestamp),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Comment Logger',style: TextStyle(fontFamily: "Alatsi",fontSize: 26),),
              centerTitle: true,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              elevation: 10.0,
              //shadowColor: Colors.purple.withOpacity(0.5),
            ),
            body: FadeTransition(
              opacity: _animationController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: List.generate(5, (index) {
                    final key = 'textField_${index + 1}';
                    final controller =
                        _textControllers[key] ?? TextEditingController();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controller,
                          onChanged: (value) => _saveFieldData(key, value),
                          decoration: InputDecoration(
                            labelText: 'Comment ${index + 1}',
                            labelStyle: const TextStyle(color: Colors.blueAccent),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save, color: Colors.blue),
                              onPressed: () {
                                _addComment(controller.text.trim());
                                controller.clear();
                                _saveFieldData(key, '');
                              },
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: _iconPosition.dx,
          top: _iconPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _iconPosition = Offset(
                  _iconPosition.dx + details.delta.dx,
                  _iconPosition.dy + details.delta.dy,
                );
              });
            },
            onPanEnd: (_) => _saveIconPosition(_iconPosition),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                shape: BoxShape.circle,
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.comment, size: 30),
                onPressed: _showScrollableWindow,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
