import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'SideBar/home_main.dart';
import 'colors.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize UserController
    Get.put(UserController());
  }
  // Login function to authenticate user
  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Validate inputs
      if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email and password cannot be empty')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      print('Attempting login with Email: ${emailController.text.trim()}, Password: ${passwordController.text.trim()}');

      // Check if email exists in admincollection
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('email', isEqualTo: emailController.text.trim())
          .get();

      print('Firestore query returned ${adminSnapshot.docs.length} documents');

      if (adminSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not found in admin records')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Attempt to sign in with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Store UID in UserController
      Get.find<UserController>().setUid(userCredential.user!.uid);

      // Navigate to HomeMain screen
      Get.off(() => const HomeMain());
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'invalid-credential':
          errorMessage = 'The email or password is incorrect.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
          print('FirebaseAuthException: Code=${e.code}, Message=${e.message}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: pink,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              double width = constraints.maxWidth;

              double size;
              double imagePadding;

              if (width <= 1440) {
                size = 120;
                imagePadding = size * 0.25;
              } else if (width > 1440 && width <= 2550) {
                size = 150;
                imagePadding = size * 0.2;
              } else {
                size = 200;
                imagePadding = size * 0.15;
              }

              return SizedBox(
                width: size,
                height: size,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(imagePadding),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Login',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildTextField(emailController, Icons.mail_outline, 'Enter email'),
          const SizedBox(height: 15),
          _buildTextField(passwordController, Icons.lock, 'Password', isPassword: true),
          const SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 425
                ? (MediaQuery.of(context).size.width - 280) / 2
                : MediaQuery.of(context).size.width < 768
                ? (MediaQuery.of(context).size.width - 300) / 2
                : MediaQuery.of(context).size.width <= 1440
                ? (MediaQuery.of(context).size.width - 400) / 2
                : (MediaQuery.of(context).size.width - 700) / 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                GestureDetector(
                  onTap: () {
                    _login();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.pink))
                        : const Icon(Icons.arrow_forward_ios, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String hintText, {bool isPassword = false}) {
    return Container(
      width: MediaQuery.of(context).size.width < 425
          ? 280
          : MediaQuery.of(context).size.width < 768
          ? 300
          : MediaQuery.of(context).size.width <= 1440
          ? 400
          : 700,
      height: 50,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.black),
        controller: controller,
        obscureText: isPassword ? !isPasswordVisible : false,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(14.0),
          prefixIcon: Icon(icon, color: Colors.red),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.red),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          )
              : null,
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class UserController extends GetxController {
  var uid = ''.obs;

  void setUid(String uid) {
    this.uid.value = uid;
  }
}