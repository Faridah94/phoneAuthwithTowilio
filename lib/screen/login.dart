import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phone_auth_project/screen/utils.dart';
import 'package:phone_auth_project/screen/home_screen.dart';
import 'dart:io' as io;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  late GlobalKey<FormState> formKey;
  bool isLogin = true;
  late String deviceId;
  bool User_isFound = false;
  late int noOfDevices = 0;
  var No_of_docs = 0;
  String emaildata = '';
  bool is_PasswordCorrect = false;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  Future<dynamic> register() async {
    //1- Returns number of device in document(pGZbbbfdSE01hxJCUSUR) in users collection
    var devicesNo = await FirebaseFirestore.instance
        .collection('users')
        .doc('pGZbbbfdSE01hxJCUSUR');
    devicesNo.get().then((document) {
      noOfDevices = document.data()?['deviceNo'];
      print('number of devices: +++++++++++++++++++   $noOfDevices');
    });

    //2- Returns number of documents in users collection
    FirebaseFirestore.instance.collection("users").count().get().then(
          (res) => No_of_docs = res.count,
          onError: (e) => print("Error completing: $e"),
        );

    print(
        'number of documents in collection users: ----------------------   ${No_of_docs} '
        'one of these docs contains deviceNo so we do not count is, that means No_of_docs - 1 always');

    //3-
    try {
      // check if user not in database and user not allowed to register by admin
      if (!User_isFound && noOfDevices == No_of_docs - 1) {
        showSnackbar(
            context, 'ليس لديك صلاحية القيام بالتسجيل في التطبيق!', false);

        // check if user not in database and user is allowed to register by admin
        // then register in database and add deviceId to database
      } else if (!User_isFound && noOfDevices > No_of_docs - 1) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .add({
              "email": emailController.text,
              "deviceId": deviceId // John Doe42
            })
            .then((value) => print("User Added to Firestore"))
            .catchError(
                (error) => print("Failed to add user Firestore: $error"));

        // simply add a document in messages sub-collection when needed.
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Home(),
          ),
        );

        // ignore: use_build_context_synchronously
        showSnackbar(context, 'تمت عملية التسجيل بنجاح', true);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showSnackbar(context, 'كلمة المرور ضعيفة.', false);
      } else if (e.code == 'email-already-in-use') {
        showSnackbar(context, 'يوجد حساب مسبق بالفعل لهذا الإيميل!', false);
      }
    } catch (e) {
      print(e.toString());
      showSnackbar(context, e.toString(), false);
    }
  }

  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();

    if (io.Platform.isIOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      deviceId = iosDeviceInfo.identifierForVendor!; // unique ID on iOS
    } else if (io.Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      deviceId = androidDeviceInfo.id; // unique ID on Android
    }
    print('deviceId :---------------$deviceId');
    return deviceId;
  }

  // Future<void> login() async {
  //   try {
  //     authListener();
  //     if (User_isFound){
  //       await FirebaseAuth.instance.signInWithEmailAndPassword(
  //         email: emailController.text,
  //         password: passwordController.text,
  //       );
  //       // ignore: use_build_context_synchronously
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => const Home(),
  //         ),
  //       );
  //     }else{
  //       showSnackbar(context, 'ليس من المسموح لك تسجيل الدخول', false);
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'user-not-found') {
  //       showSnackbar(context, 'No user found for that email.', false);
  //     } else if (e.code == 'wrong-password') {
  //       showSnackbar(context, 'Wrong password provided for that user.', false);
  //     }
  //   } catch (e) {
  //     showSnackbar(context, e.toString(), false);
  //   }
  // }

  // Future<void> verify() async {
  //     try {
  //       final user =  (await FirebaseAuth.instance.signInWithEmailAndPassword(
  //               email: emailController.text, password: passwordController.text))
  //           .user;
  //        if(user!.emailVerified){
  //
  //          is_PasswordCorrect = true;
  //        }else{
  //          showSnackbar(context, 'قد تكون كلمة المرور خاطئة, يرجى التحقق!', false);
  //          is_PasswordCorrect = false;
  //        }
  //     } on FirebaseAuthException catch (e) {
  //       if (e.code == 'user-not-found') {
  //         print('No user found for that email.');
  //       } else if (e.code == 'wrong-password') {
  //         is_PasswordCorrect = false;
  //         print('Wrong password provided for that user.');
  //       }
  //     }
  //
  // }

  Future<void> authListener() async {
    try {
      final _fireStore = FirebaseFirestore.instance;

      QuerySnapshot querySnapshot = await _fireStore.collection('users').get();
      final allData = querySnapshot.docs.map((doc) => doc.data()).toList();

      // Get current device id and saved it to database

      print(
          'get deviceId using _getId() method = //////////////////////////////////////$deviceId');

      for (var data in allData) {
        if (data is Map) {
          // Check if the same id, if not same then logout and navigate to login screen
          for (var value in data.values) {
            // print('------------------------------------------${value}');
            if (value['deviceId'] == deviceId) {
              User_isFound = true;
              print(
                  'deviceId stored in firebase ://////////////////////////////////////  $value');
              print(
                  '----------------------user found but User_deviceId is not matched!');
            } else {
              print(
                  'deviceId stored in firebase ://////////////////////////////////////  $value');
              print(
                  '---------------------- user found and User_deviceId is matched');
            }
          }
        }
      }
    } catch (e) {
      print('Error in authListener() method: ${e.toString()}');
    }
  }

  Future<void> LogMEin() async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final _mainCollection = _firestore.collection('users');

      await _mainCollection
          .where('email', isEqualTo: emailController.text)
          .get()
          .then(
            (QuerySnapshot snapshot) => {
              snapshot.docs.forEach((f) {
                final data = f.data() as Map<String, dynamic>;

                print("Email---- " + data['email']);
                emaildata = data['email'];
              }),
            },
          );

      if (emaildata == emailController.text) {
          showSnackbar(context, 'تم تسجيل الدخول بنجاح', true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const Home(),
            ),
          );
        } else {
        showSnackbar(
            context,
            'لايمكنك تسجيل الدخول, قم بتسجيل حساب أولاً أو تحقق من صحة الإيميل أو كلمة المرور ان كان لديك حساب بالفعل',
            false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showSnackbar(context, 'No user found for that email.', false);
      } else if (e.code == 'wrong-password') {
        showSnackbar(context, 'Wrong password provided for that user.', false);
      }
    } catch (e) {
      showSnackbar(context, e.toString(), false);
    }
  }

  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    formKey = GlobalKey<FormState>();
    authListener();
    // Get current device id and saved it to database
    _getId();
    // authListener();
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: SizedBox(
          height: double.maxFinite,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isLogin ? "Login Page" : "Register Page",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    label: Text('Email'),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Email required';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    label: Text('Password'),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Password required';
                    }

                    return null;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        isLogin = !isLogin;
                        emailController.clear();
                        passwordController.clear();
                        setState(() {});
                      },
                      child: const Text("Don't have an account?"),
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        // We will add login & register function later
                        if (formKey.currentState!.validate()) {
                          if (isLogin) {
                            await LogMEin();
                          } else {
                            await register();
                          }
                        }
                      },
                      child: Text(isLogin ? "Login" : "Register"),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
