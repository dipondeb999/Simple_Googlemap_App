import 'package:flutter/material.dart';
import 'package:simple_googlemap_app/ui/screens/home_screen.dart';

class SimpleGoogleMapApp extends StatelessWidget {
  const SimpleGoogleMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
