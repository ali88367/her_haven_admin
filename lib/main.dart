import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:herhaven_admin/SideBar/home_main.dart';
import 'Login.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      localizationsDelegates: const [
        // ... your other delegates
        FlutterQuillLocalizations.delegate,
      ],
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Login(),
    );
  }
}
