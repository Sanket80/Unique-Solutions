import 'dart:io';
import 'package:company/HomeScreen.dart';
import 'package:company/InputData.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  String storageBucketUrl = 'gs://company-805b3.appspot.com';
  Platform.isAndroid
      ? await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyAllijdJQf0f1i2FhdlHMzyoUeZVig4RSI',
      appId: '1:805456954493:android:d6fed05879543974949d14',
      messagingSenderId: '805456954493',
      projectId: 'company-805b3',
      storageBucket: storageBucketUrl,
    ),
  )
      : await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Company App',
      home: const HomeScreen(),
    );
  }
}


