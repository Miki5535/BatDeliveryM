import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lotto/pages/login.dart';
import 'package:lotto/pages/ridermain.dart';
import 'package:lotto/pages/riderreceiver.dart';

class ProfileriderPages extends StatefulWidget {
  const ProfileriderPages({super.key});

  @override
  State<ProfileriderPages> createState() => _ProfileriderPagesState();
}

class _ProfileriderPagesState extends State<ProfileriderPages> {
  int _selectedIndex = 0;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? _firebaseImageUrl;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final storageF = GetStorage();
  var db = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController carRegistrationController =
      TextEditingController();

  String? userId;
  String? name;
  String? email;
  String? phone;
  String? pic;
  String? carRegistration;

  @override
  void initState() {
    super.initState();
    initializeProfile();
  }

  Future<void> initializeProfile() async {
    await loadData();
    await _loadFirebaseImage();
  }

  Future<void> loadData() async {
    userId = storageF.read('userId');
    name = storageF.read('name');
    email = storageF.read('email');
    phone = storageF.read('phone');
    pic = storageF.read('pic');
    carRegistration = storageF.read('Carregistration');

    nameController.text = name ?? '';
    emailController.text = email ?? '';
    phoneController.text = phone ?? '';
    carRegistrationController.text = carRegistration ?? '';
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileriderPages()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RiderMainPages()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RiderReceiverPages()),
        );
        break;
    }
  }

  Future<void> _loadFirebaseImage() async {
    try {
      if (pic != null) {
        String imageUrl = await storage.ref('/uploads/$pic').getDownloadURL();
        setState(() {
          _firebaseImageUrl = imageUrl;
        });
      }
    } catch (e) {
      print('Failed to load image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 143, 56, 158),
        appBar: AppBar(
          title: const Text('โปรไฟล์ผู้ใช้'),
          backgroundColor: const Color.fromARGB(255, 218, 179, 224),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _imageFile != null
                      ? FileImage(File(_imageFile!.path))
                      : (_firebaseImageUrl != null
                          ? NetworkImage(_firebaseImageUrl!)
                          : null),
                  child: _imageFile == null && _firebaseImageUrl == null
                      ? const Icon(Icons.camera_alt,
                          size: 50, color: Colors.purple)
                      : const Icon(Icons.camera_alt,
                          size: 50, color: Colors.purple),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ProfileForm(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  logout();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                      Colors.red), // Set the background color to red
                ),
                child: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                      color: Colors
                          .white), // Optional: Set text color to white for better contrast
                ),
              )
            ],
          ),
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: Colors.purple,
            unselectedItemColor: Colors.black,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/images/pro2.png',
                  width: 30,
                  height: 30,
                ),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/images/batone.png',
                  width: 30,
                  height: 30,
                ),
                label: 'Rider',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/images/map.png',
                  width: 30,
                  height: 30,
                ),
                label: 'Work',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget ProfileForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'หมายเลขโทรศัพท์',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'อีเมล',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: carRegistrationController,
          decoration: InputDecoration(
            labelText: 'ป้ายทะเบียน',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // ฟังก์ชันแก้ไขรหัสผ่าน
            },
            child: const Text(
              'แก้ไขรหัสผ่าน',
              style: TextStyle(color: Colors.purple),
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            updateUser();
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                Colors.green), // Set the background color to green
          ),
          child: const Text('บันทึก',
              style: TextStyle(
                  color: Colors
                      .white)), // Optional: Set text color to white for better contrast
        )
      ],
    );
  }

  Future<String> getNextFileName() async {
    final ListResult result = await storage.ref('uploads').listAll();
    int maxNumber = 0;

    for (var ref in result.items) {
      final name = ref.name;
      final match = RegExp(r'pic-(\d+)').firstMatch(name);
      if (match != null) {
        int number = int.parse(match.group(1)!);
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    return 'pic-${maxNumber + 1}';
  }

  void updateUser() async {
    if (_imageFile != null) {
      try {
        if (pic != null && pic!.isNotEmpty) {
          await storage.ref('uploads/$pic').delete();
        }
        String newFileName = await getNextFileName();
        await storage
            .ref('uploads/$newFileName')
            .putFile(File(_imageFile!.path));
        setState(() {
          pic = newFileName;
        });
      } catch (e) {
        log('เกิดข้อผิดพลาดขณะอัปเดตรูปภาพ: $e');
      }
    }

    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('Rider').doc(userId);
      await userRef.update({
        'name': nameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'Carregistration': carRegistrationController.text,
        'pic': pic,
      });
      storageF.write('name', nameController.text);
      storageF.write('email', emailController.text);
      storageF.write('phone', phoneController.text);
      storageF.write('pic', pic);
      storageF.write('Carregistration', carRegistrationController.text);
      Get.snackbar("สำเร็จ", "อัปเดตข้อมูลผู้ใช้สำเร็จ");
    } catch (error) {
      Get.snackbar("ข้อผิดพลาด", "อัปเดตผู้ใช้ล้มเหลว: $error");
    }
  }

  void logout() {
    storageF.erase();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPages()),
    );
  }
}
