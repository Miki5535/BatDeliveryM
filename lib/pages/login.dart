import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lotto/pages/register.dart';
import 'package:lotto/pages/ridermain.dart';
import 'package:lotto/pages/sender.dart';

class LoginPages extends StatefulWidget {
  const LoginPages({super.key});

  @override
  _LoginPagesState createState() => _LoginPagesState();
}

class _LoginPagesState extends State<LoginPages> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isUser = true;
  var db = FirebaseFirestore.instance;
  final storage = GetStorage();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _emailController.text = 'mik@gmail.com';
    // _passwordController.text = '111111';
    //     _emailController.text = 'test@gmail.com';
    // _passwordController.text = '123456';
    //     _emailController.text = 'snack@gmail.com';
    // _passwordController.text = '666666';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 174, 63, 194),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 174, 63, 194),
        elevation: 0,
        automaticallyImplyLeading: false,
        
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 250,
                  width: 250,
                  fit: BoxFit.contain,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 20),
                        _buildRoleSwitch(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Email field with validation
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'อีเมล์',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  // Password field with validation
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'รหัสผ่าน',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  // Role switch for User/Rider
  Widget _buildRoleSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'User',
          style: TextStyle(color: Colors.purple),
        ),
        Switch(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          value: isUser,
          onChanged: (value) {
            setState(() {
              isUser = value;
            });
          },
        ),
        const Text(
          'Rider',
          style: TextStyle(color: Colors.purple),
        ),
      ],
    );
  }

  // Action buttons for login and registration
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              login();
            }
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('เข้าสู่ระบบ'),
        ),
        ElevatedButton(
          onPressed: register,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
          child: const Text('สมัครสมาชิก'),
        ),
      ],
    );
  }



  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    var userCollection;

    if (!isUser) {
      log('Logging in as User');
      userCollection = db.collection('User');
    } else {
      log('Logging in as Rider');
      userCollection = db.collection('Rider');
    }

    try {
      var querySnapshot = await userCollection
          .where('email', isEqualTo: email)
          .where('pass', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data();
        log('Login successful for user: ${userData['name']}');
        Get.snackbar("เข้าสู่ระบบสำเร็จ", "ยินดีต้อนรับ คุณ ${userData['name']}");


          storage.write('userId', querySnapshot.docs.first.id);
          storage.write('name', userData['name']);
          storage.write('email', userData['email']);
          storage.write('phone', userData['phone']);
          storage.write('pic', userData['pic']);

        if (!isUser) {
          storage.write('latitude', userData['latitude'].toString());
          storage.write('longitude', userData['longitude'].toString());


          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Senderpages()),
          );
        } else {
          storage.write('Carregistration', userData['Carregistration']);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RiderMainPages()),
          );
        }
      } else {
        log('Invalid email or password');
        Get.snackbar("เข้าสู่ระบบไม่สำเร็จ", "คุณเข้าสู่ระบบไม่สำเร็จโปรดลองอีกครั้ง");
      }
    } catch (e) {
      log('Failed to login: $e');
      Get.snackbar("เข้าสู่ระบบไม่สำเร็จ", "คุณเข้าสู่ระบบไม่สำเร็จโปรดลองอีกครั้ง");
    }
  }


  // Register function
  void register() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }
}
