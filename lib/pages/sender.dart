import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lotto/pages/profileuser.dart';
import 'package:lotto/pages/receiver.dart';
import 'package:provider/provider.dart';

import '../shared/appdata.dart';

class Senderpages extends StatefulWidget {
  const Senderpages({super.key});

  @override
  State<Senderpages> createState() => _SenderpagesState();
}

class _SenderpagesState extends State<Senderpages>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  final storageF = GetStorage();
  var db = FirebaseFirestore.instance;
  final ImagePicker picker = ImagePicker();
  final MapController mapController = MapController();
  final double zoomIncrement = 1.0;
  final FirebaseStorage storage = FirebaseStorage.instance;

  LatLng? currentLocation;
  LatLng? tappedLocation;
  LatLng? point1;

  String? _firebaseImageUrl;
  String? userId;
  String? name;
  String? email;
  String? phone;
  String? pic;
  double? latitude;
  double? longitude;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> senderall = [];

  XFile? selectedImage;

     List<LatLng> points = [];

   List<String> ridernumber = [];
   List<LatLng> riderPoints = [];
     List<String> ridernames = [];



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    initializeDB();
  }

  Future<void> initializeDB() async {
    await startRealtimeOrder();
    await loadData();
    await _loadFirebaseImage();
    await readAllUsers();
    await readAllsender();
  }

  Future<void> loadData() async {
    userId = storageF.read('userId');
    name = storageF.read('name');
    email = storageF.read('email');
    phone = storageF.read('phone');
    pic = storageF.read('pic');

    // ตรวจสอบค่าที่อ่านมาจาก storage ว่าไม่เป็น null
    final latitudeString = storageF.read('latitude');
    final longitudeString = storageF.read('longitude');

    // แปลงค่า latitude และ longitude เป็น double หากไม่เป็น null
    if (latitudeString != null && longitudeString != null) {
      try {
        latitude = double.parse(latitudeString);
        longitude = double.parse(longitudeString);
        if (latitude != null && longitude != null) {
          setState(() {
            point1 = LatLng(latitude!, longitude!);
          });
        }
      } catch (e) {
        log('Error parsing latitude or longitude: $e');
        point1 = null;
      }
    } else {
      log('Latitude or longitude is null');
      point1 = null;
    }
  }



  Future<void> readAllUsers() async {
    var result = await db.collection('User').get();
    setState(() {
      users = result.docs.where((doc) => doc.id != userId).map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'email': doc['email'],
          'phone': doc['phone'],
          'latitude': doc['latitude'],
          'longitude': doc['longitude'],
          'createdAt': (doc['createAt'] as Timestamp).millisecondsSinceEpoch,
          'pic': doc['pic'],
        };
      }).toList();
    });
  }

  Future<void> startRealtimeOrder() async {
    final docRef = db.collection("Order");

    if (context.read<AppData>().listener != null) {
      context.read<AppData>().listener!.cancel();
      context.read<AppData>().listener = null;
      log('Listener Stop');
    }

    context.read<AppData>().listener = docRef.snapshots().listen(
      (event) {
        readAllsender();
        // var data = event.data();
        log('Order LT'); 
        // log("current data: ${event.data()}");
      },
      onError: (error) => log("Listen failed: $error"),
    );
  }

Future<void> readAllsender() async {
  // var result = await db.collection('Order')
  // .where('sender', isEqualTo: userId ) 
  // .get();

  var filteredOrders = await db.collection('Order')
  .where('sender', isEqualTo: userId)
  .get();



var result = filteredOrders.docs.where((doc) => doc['status'] != 'ส่งแล้ว').toList();
 


  List<Map<String, dynamic>> tempSenderList = [];
  List<LatLng> pointsadd = [];
  List<String> ridernumberadd = [];
  List<LatLng> riderPointsAdd = []; 

  List<String> ridernamesadd=[];
  
  for (var doc in result) {

        // Check if rider point exists (not zero)
    double pointX = doc['pointX'] ?? 0.0;
    double pointY = doc['pointY'] ?? 0.0;
    if (pointX != 0.0 && pointY != 0.0) {
      riderPointsAdd.add(LatLng(pointX, pointY));
      ridernamesadd.add(doc['rider']);
      
    }

    String imageUrlr = '';
    var result2 = await db.collection('User').doc(doc['receiver']).get();
    
    try {
      if (doc['photosender'] != null) {
        imageUrlr = await storage
            .ref('/order/${doc['photosender']}')
            .getDownloadURL();
      }
    } catch (e) {
      log('Failed to load image: $e');
      imageUrlr = ''; 
    }

    String receiverName = result2.data()?['name']?.toString() ?? 'Unknown'; 
    String receiverphone = result2.data()?['phone']?.toString() ?? 'Unknown';
    String? receiverpic = result2.data()?['pic']?.toString();
    
    double receiverlatitude = 0.0;
    double receiverlongitude = 0.0;
    
    try {
      receiverlatitude = double.parse(result2.data()?['latitude']?.toString() ?? '0.0');
      receiverlongitude = double.parse(result2.data()?['longitude']?.toString() ?? '0.0');
    } catch (e) {
      log('Error parsing coordinates: $e');
    }
    
    String receiverPicUrl = '';
    if (receiverpic != null && receiverpic.isNotEmpty) {
      try {
        receiverPicUrl = await storage.ref('/uploads/$receiverpic').getDownloadURL();
      } catch (e) {
        log('Failed to load receiver pic: $e');
        receiverPicUrl = ''; 
      }
    }



    if (receiverlatitude != 0.0 && receiverlongitude != 0.0) {
      pointsadd.add(LatLng(receiverlatitude, receiverlongitude));
      ridernumberadd.add(receiverName);
      
      tempSenderList.add({
        'order_id': doc.id,
        'createAt': doc['createAt'],
        'detail': doc['detail'] ?? '',
        'photosender': imageUrlr,
        'receiver': receiverName,
        'rider': doc['rider'] ?? '',
        'status': doc['status'] ?? '',
        'sender': doc['sender'] ?? '', 
        'phone': receiverphone, 
        'picR': receiverPicUrl,
        'latitude': receiverlatitude,
        'longitude': receiverlongitude,
        // 'pointX': pointX,
        // 'pointY': pointY,
      });
    }
  }

  setState(() {
    senderall = tempSenderList;
    points = pointsadd;
    ridernumber = ridernumberadd;
    riderPoints = riderPointsAdd; 
    ridernames = ridernamesadd;
  });
}
 
 
 
  @override
  Widget build(BuildContext context) {
    // Filter users based on the search query
    final filteredUsers = users.where((user) {
      return user['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          user['phone'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 143, 56, 158),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'ค้นหาผู้รับ'), // "Search" in Thai
                  Tab(text: 'การส่ง'), // "Map" in Thai
                  Tab(text: 'แผนที่'),
                ],
                labelColor: Colors.purple,
                unselectedLabelColor: Colors.black,
                indicatorColor: Colors.purple,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 201, 201, 201),
                            labelText: 'ค้นหา',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return ListTile(
                                title: Text(user['name']),
                                subtitle: Text(user['phone']),
                                onTap: () => _showDialog(
                                    user), // Show dialog with user data
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Expanded(
                            child: ListView.builder(
                          itemCount: senderall.length,
                          itemBuilder: (context, index) {
                            var sender = senderall[index];
                            return Card(
                              margin: EdgeInsets.all(10),
                              child: ListTile(
                                title: Text('Sender : ${index+1}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ผู้รับ : ${sender['receiver']}'),
                                    Text('โทรศัพทร์ผู้รับ : ${sender['phone']}'),
                                    Text('ไรเดอร์ : ${sender['rider']}'),
                                    Text('สถานะ : ${sender['status']}'),
                                    Text('รายละเอียด : ${sender['detail']}'),
                                     
                                     if (sender['status'] ==
                                        'ไรเดอร์รับงานแล้ว')
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: FilledButton(
                                          onPressed: () {
                                            statussubmit(
                                                '${sender['order_id']}',
                                                '${sender['rider']}');
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all<Color>(
                                                    Colors.green),
                                          ),
                                          child: Text('ยืนยัน'),
                                        ),
                                      ),
                                    
                                  ],
                                ),
                                leading: Image.network(sender['photosender']),
                              ),
                            );
                          },
                        )),
                      ],
                    ),
                    SizedBox(
                                width: double
                                    .infinity, 
                                height: 300.0, 
                                child:
                                    MapAll(), 
                              )
                  ],
                ),
              ),
            ],
          ),
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
              label: 'Sender',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/images/map.png',
                width: 30,
                height: 30,
              ),
              label: 'Receiver',
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(Map<String, dynamic> user) async {
    final TextEditingController fromController =
        TextEditingController(text: name);
    final TextEditingController emailtoController =
        TextEditingController(text: user['email']);
    final TextEditingController nameController =
        TextEditingController(text: user['name']);
    final TextEditingController phoneController =
        TextEditingController(text: user['phone']);
    final TextEditingController detailsController = TextEditingController();

     String picR =
        await storage.ref('/uploads/${user['pic']}').getDownloadURL();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ข้อมูลการส่ง'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                // ใช้ StatefulBuilder เพื่ออัปเดตสถานะ
                return Column(
                  children: [
                    TextField(
                      controller: fromController,
                      decoration: const InputDecoration(labelText: 'ผู้ส่ง'),
                      enabled: false, // ป้องกันการแก้ไข
                    ),
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'ชื่อผู้รับ'),
                      enabled: false, // ป้องกันการแก้ไข
                    ),
                    TextField(
                      controller: phoneController,
                      decoration:
                          const InputDecoration(labelText: 'เบอร์ผู้รับ'),
                      enabled: false, // ป้องกันการแก้ไข
                    ),
                    TextField(
                      controller: emailtoController,
                      decoration:
                          const InputDecoration(labelText: 'อีเมล์ผู้รับ'),
                      enabled: false, // ป้องกันการแก้ไข
                    ),
                    TextField(
                      controller: detailsController,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียด',
                        hintText: 'รายละเอียดเพิ่มเติม',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Text('แผนที่'),
                    SizedBox(
                      width: double.infinity,
                      height: 250.0,
                      child: Scaffold(
                        body: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            center: currentLocation ?? point1,
                            zoom: 14.5,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: ['a', 'b', 'c'],
                            ),
                            buildMapWithMarkers(
                              point1: point1,
                              url1: _firebaseImageUrl,
                              url2: picR,

                              selectedUserLocation: LatLng(
                                double.parse(user['latitude'].toString()),
                                double.parse(user['longitude'].toString()),
                              ),
                            ),
                          ],
                        ),
                        floatingActionButton: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FloatingActionButton(
                              onPressed: _zoomIn,
                              child: const Icon(Icons.add),
                              tooltip: 'Zoom In',
                            ),
                            const SizedBox(height: 10),
                            FloatingActionButton(
                              onPressed: _zoomOut,
                              child: const Icon(Icons.remove),
                              tooltip: 'Zoom Out',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text('ภาพสินค้า'),
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        selectedImage =
                            await picker.pickImage(source: ImageSource.camera);
                        if (selectedImage != null) {
                          setState(() {
                            // ใช้ setState ของ StatefulBuilder
                            selectedImage = selectedImage;
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: selectedImage == null
                            ? const Center(child: Text('ที่ใส่ภาพ'))
                            : Image.file(File(selectedImage!.path),
                                fit: BoxFit.cover),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                submitOrder(user['id'], detailsController.text);
              },
              child: const Text('ส่ง'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  Widget buildMapWithMarkers({
    required LatLng? point1,
    required String? url1,
    required String? url2,
    required LatLng? selectedUserLocation,
  }) {
    List<LatLng> polylinePoints = [];

    // Add sender's location to polyline if available
    if (point1 != null) {
      polylinePoints.add(point1);
    }

    // Add selected user's location to polyline if available
    if (selectedUserLocation != null) {
      polylinePoints.add(selectedUserLocation);
    }

    return Stack(
      children: [
        // Polyline Layer (เส้นเชื่อม)
        if (polylinePoints.length == 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 3.0,
                color: Colors.purple.withOpacity(0.7),
                isDotted: true,
              ),
            ],
          ),

        // Marker Layer for sender (ผู้ส่ง)
        if (point1 != null)
                    MarkerLayer(
            markers: [
              Marker(
                point: point1,
                width: 50,
                height: 80, // เพิ่มความสูงเพื่อให้มีที่สำหรับข้อความ
                builder: (ctx) => Stack(
                  // alignment: Alignment.bottomLeft,
                  children: [
                    Positioned(
                      top: 0,
                      child: Text(
                        'คุณ',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child:  url1 != null
                            ? ClipOval(
                                child: Image.network(
                                  url1,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // Marker Layer for selected user (ผู้รับ)
        if (selectedUserLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: selectedUserLocation,
                width: 50,
                height: 80, // เพิ่มความสูงเพื่อให้มีที่สำหรับข้อความ
                builder: (ctx) => Stack(
                  // alignment: Alignment.bottomLeft,
                  children: [
                    Positioned(
                      top: 0,
                      child: Text(
                        'ผู้รับ',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: url2 != null
                            ? ClipOval(
                                child: Image.network(
                                  url2,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

      
      ],
    );
  }


  void _zoomIn() {
    final currentZoom = mapController.zoom;
    if (point1 != null) {
      mapController.move(point1!, currentZoom + zoomIncrement);
    }
  }

  void _zoomOut() {
    final currentZoom = mapController.zoom;
    if (currentZoom > 1 && point1 != null) {
      mapController.move(point1!, currentZoom - zoomIncrement);
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileuserPages()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Senderpages()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserReceiverPages()),
        );
        break;
    }
  }

  Future<void> submitOrder(String receiver, String detail) async {
    log('receiver : $receiver');
    log('sender : $userId');
    log('detail : $detail');
    log('$selectedImage');


    if (selectedImage != null) {
      var inboxRef = db.collection('Order');
      

      try {
        String newFileName = await getNextFileName();
        await storage
            .ref('order/$newFileName')
            .putFile(File(selectedImage!.path));

        String newDocId = await _getNextUserId(inboxRef, 'Order');
        var data = {
          'sender': userId,
          'receiver': receiver,
          'detail': detail,
          'photosender': newFileName,
          'rider': 'no',
          'status': 'ยังไม่มีไรเดอร์',
                    'pointX': 0.000000,
                              'pointY': 0.000000,
          'createAt': DateTime.now(),
        };
        await inboxRef.doc(newDocId).set(data);
        selectedImage = null;
        log('Document $newDocId added successfully');
        Get.snackbar("เพิ่มการส่งสำเร็จ", "คุณเพิ่มข้อมูลการส่ง $newDocId  สำเร็จแล้ววว");

            readAllsender();

              Navigator.pop(
            context,
            
          );

      } catch (e) {
        log('Failed to add document: $e');
        Get.snackbar("Error", "Failed to add document");
      }
    }else{
      Get.snackbar("ภาพไม่ได้ใส่", "กรุณาใส่ภาพในช่องใส่ภาพ");
    }
  }

  Future<String> _getNextUserId(
      CollectionReference inboxRef, String docType) async {
    var querySnapshot = await inboxRef
        .orderBy(FieldPath.documentId, descending: true)
        .limit(1)
        .get();
    int nextDocNumber = 1;
    if (querySnapshot.docs.isNotEmpty) {
      var lastDocId = querySnapshot.docs.first.id;
      var lastDocNumber = int.parse(lastDocId.split('-').last);
      nextDocNumber = lastDocNumber + 1;
    }
    return '$docType-$nextDocNumber';
  }

  Future<String> getNextFileName() async {
    final ListResult result = await storage.ref('order').listAll();
    int maxNumber = 0;

    for (var ref in result.items) {
      final name = ref.name;
      final match = RegExp(r'order-(\d+)').firstMatch(name);
      if (match != null) {
        int number = int.parse(match.group(1)!);
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    return 'order-${maxNumber + 1}';
  }

Widget MapAll() {
  return Scaffold(
    body: FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: currentLocation ?? point1 ?? LatLng(0, 0),
        zoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        PolylineLayer(
          polylines: _buildPolylines(),
        ),
        if (_firebaseImageUrl != null && point1 != null)
          _buildMarker(point1!, _firebaseImageUrl!),
        ..._buildMarkersWithReceiverPics(),
        ..._buildRiderMarkers(), // Add rider markers
      ],
    ),
    floatingActionButton: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: _zoomIn,
          child: const Icon(Icons.add),
          tooltip: 'Zoom In',
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          onPressed: _zoomOut,
          child: const Icon(Icons.remove),
          tooltip: 'Zoom Out',
        ),
      ],
    ),
  );
}


List<MarkerLayer> _buildRiderMarkers() {
  return riderPoints.asMap().entries.map((entry) {
    int index = entry.key;
    var point = entry.value;
    String riderName = ridernames.isNotEmpty && index < ridernames.length
        ? ridernames[index]
        : 'Unknown'; 

    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          height: 100,
          width: 60,
          builder: (ctx) => SizedBox(
            width: 60,
            height: 100,
            child: Column(
              children: [
                Container(
                  width: 60,
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      riderName, // ใช้ riderName ที่ได้จาก ridernames
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                ClipOval(
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: 'assets/images/riderpic.png'.isNotEmpty
                        ? Image.asset(
                            'assets/images/riderpic.png',
                            width: 40,
                            height: 40,
                          )
                        : const Icon(Icons.person, size: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }).toList();
}


  MarkerLayer _buildMarker(LatLng point, String url) {
    return MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 50,
                height: 80, // เพิ่มความสูงเพื่อให้มีที่สำหรับข้อความ
                builder: (ctx) => Stack(
                  // alignment: Alignment.bottomLeft,
                  children: [
                    Positioned(
                      top: 0,
                      child: Text(
                        'คุณ',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child:  url != null
                            ? ClipOval(
                                child: Image.network(
                                  url,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }




  List<Polyline> _buildPolylines() {
    List<Polyline> polylines = [];
    for (LatLng point in points) {
      polylines.add(Polyline(
        points: [point1!, point], 
        color: Colors.blue,
        strokeWidth: 4.0,
      ));
    }
    if (currentLocation != null) {
      polylines.add(Polyline(
        points: [
          point1!,
          currentLocation!
        ], 
        color: Colors.blue,
        strokeWidth: 4.0,
      ));
    }
    return polylines;
  }

List<MarkerLayer> _buildMarkersWithReceiverPics() {
  return points.asMap().entries.map((entry) {
    int index = entry.key;
    LatLng point = entry.value;
    // Make sure we don't access beyond array bounds
    String riderNumber = index < ridernumber.length ? ridernumber[index] : 'Unknown';
    String receiverPic = index < senderall.length ? senderall[index]['picR'] ?? '' : '';

    return _buildImageMarkerWithPic(point, receiverPic, riderNumber);
  }).toList();
}

MarkerLayer _buildImageMarkerWithPic(LatLng point, String imageUrl, String riderNumber) {
  return MarkerLayer(
    markers: [
      Marker(
        point: point,
        height: 100,
        width: 60,
        builder: (ctx) => SizedBox(
          width: 60,
          height: 100,
          child: Column(
            children: [
              Container(
                width: 40,
                color: Colors.white,
                child: Center(
                  child: Text(
                    riderNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ClipOval(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 40);
                          },
                        )
                      : const Icon(Icons.person, size: 40),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
  Future<void> statussubmit(String id, String rider) async {
    log('$id');
    await db.collection('Order').doc(id).update({'status': 'กำลังส่ง'});

    // await db.collection('Rider').doc(rider).update({'status': 'ว่าง'});

    readAllsender();
    Get.snackbar("ยืนยันการจัดส่งแล้ว", "คุณได้ยืนยันการจัดส่งสินค้าให้กับไรเดอร์แล้วว");
  }


}
