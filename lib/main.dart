import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/practice_screen.dart';

void main() {
  runApp(const PronounceProApp());
}

class PronounceProApp extends StatelessWidget {
  const PronounceProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PronouncePro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3F51B5),
          secondary: Color(0xFF00E5FF),
          background: Color(0xFF0F172A),
          surface: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        dividerColor: Colors.white10,
      ),
      home: const PracticeScreen(),
    );
  }
}
