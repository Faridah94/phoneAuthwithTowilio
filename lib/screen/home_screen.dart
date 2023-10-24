import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'utils.dart';
import 'dart:io' as io;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    // authListener();
    super.initState();
  }


  Future<void> logout(bool isShowSnackbar) async {
    await FirebaseAuth.instance.signOut();

    if (isShowSnackbar) {
      // ignore: use_build_context_synchronously
      showSnackbar(context, 'Your account logged in another device', false);
    }

    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Login(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Home Screen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Center(
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () async => await logout(false),
                child: const Text("Logout"),
              ),
            ),
          )
        ],
      ),
    );
  }
}
