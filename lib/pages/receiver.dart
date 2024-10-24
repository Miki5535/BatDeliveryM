import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:lotto/pages/profileuser.dart';
import 'package:lotto/pages/sender.dart';
import 'package:lotto/shared/appdata.dart';
import 'package:provider/provider.dart';

class UserReceiverPages extends StatefulWidget {
  const UserReceiverPages({super.key});

  @override
  State<UserReceiverPages> createState() => _UserReceiverPagesState();
}

class _UserReceiverPagesState extends State<UserReceiverPages>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  late TabController _tabController; // Add TabController

  final storageF = GetStorage();
  var db = FirebaseFirestore.instance;
  final MapController mapController = MapController();
  final double zoomIncrement = 1.0;
  final FirebaseStorage storage = FirebaseStorage.instance;

  String? _firebaseImageUrl;
  String? userId;
  String? name;
  String? email;
  String? phone;
  String? pic;
  double? latitude;
  double? longitude;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> receiverall = [];

  LatLng? point1;
  List<LatLng> points = [];

  List<String> ridernumber = [];
  List<LatLng> riderPoints = [];
  List<String> ridernames = [];
  LatLng? currentLocation;
  List<Map<String, dynamic>> senderall = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeDB();
  }

  Future<void> initializeDB() async {
    await startRealtimeOrder();
    await loadData();
    await readAllreceiver();
    await _loadFirebaseImage();
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
        readAllreceiver();
        // var data = event.data();
        log('Order LT'); 
        // log("current data: ${event.data()}");
      },
      onError: (error) => log("Listen failed: $error"),
    );
  }

  Future<void> loadData() async {
    userId = storageF.read('userId');
    name = storageF.read('name');
    email = storageF.read('email');
    phone = storageF.read('phone');
    pic = storageF.read('pic');
    // log('$name');

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

  Future<void> readAllreceiver() async {
    var filteredOrders =
        await db.collection('Order').where('receiver', isEqualTo: userId).get();
    var result =
        filteredOrders.docs.where((doc) => doc['status'] != 'ส่งแล้ว').toList();
    List<Map<String, dynamic>> tempSenderList = [];
    List<LatLng> pointsadd = [];
    List<String> ridernumberadd = [];
    List<LatLng> riderPointsAdd = [];

    List<String> ridernamesadd = [];

    for (var doc in result) {
      double pointX = doc['pointX'] ?? 0.0;
      double pointY = doc['pointY'] ?? 0.0;
      if (pointX != 0.0 && pointY != 0.0) {
        riderPointsAdd.add(LatLng(pointX, pointY));
        ridernamesadd.add(doc['rider']);
      }

      String imageUrlr = '';
      var result2 = await db.collection('User').doc(doc['sender']).get();

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

      String senderName = result2.data()?['name']?.toString() ?? 'Unknown';
      String senderphone = result2.data()?['phone']?.toString() ?? 'Unknown';
      String? senderpic = result2.data()?['pic']?.toString();

      double receiverlatitude = 0.0;
      double receiverlongitude = 0.0;

      try {
        receiverlatitude =
            double.parse(result2.data()?['latitude']?.toString() ?? '0.0');
        receiverlongitude =
            double.parse(result2.data()?['longitude']?.toString() ?? '0.0');
      } catch (e) {
        log('Error parsing coordinates: $e');
      }

      String senderPicUrl = '';
      if (senderpic != null && senderpic.isNotEmpty) {
        try {
          senderPicUrl =
              await storage.ref('/uploads/$senderpic').getDownloadURL();
        } catch (e) {
          log('Failed to load receiver pic: $e');
          senderPicUrl = '';
        }
      }

      if (receiverlatitude != 0.0 && receiverlongitude != 0.0) {
        pointsadd.add(LatLng(receiverlatitude, receiverlongitude));
        ridernumberadd.add(senderName);

        // log('$senderPicUrl');

        tempSenderList.add({
          'order_id': doc.id,
          'createAt': doc['createAt'],
          'detail': doc['detail'] ?? '',
          'photosender': imageUrlr,
          'sendername': senderName,
          'rider': doc['rider'] ?? '',
          'status': doc['status'] ?? '',
          'sender': doc['sender'] ?? '',
          'phone': senderphone,
          'picR': senderPicUrl,
          'latitude': receiverlatitude,
          'longitude': receiverlongitude,
        });
      }
    }

    setState(() {
      receiverall = tempSenderList;
      points = pointsadd;
      ridernumber = ridernumberadd;
      riderPoints = riderPointsAdd;
      ridernames = ridernamesadd;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 143, 56, 158),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // Shadow position
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // TabBar for selecting between Search and Map
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'ของที่ต้องรับ'), // "Search" in Thai
                  Tab(text: 'แผนที่'), // "Map" in Thai
                ],
                labelColor: Colors.purple, // Selected tab color
                unselectedLabelColor: Colors.black, // Unselected tab color
                indicatorColor: Colors.purple, // Tab indicator color
              ),
              const SizedBox(height: 10), // Space between TabBar and TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // First tab: Search Page
                    Column(
  children: [
    Expanded(
      child: receiverall.isNotEmpty
          ? ListView.builder(
              itemCount: receiverall.length,
              itemBuilder: (context, index) {
                var receiver = receiverall[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text('Receiver : ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ผู้ส่ง : ${receiver['sendername']}'),
                        Text('เบอร์ผู้ส่ง : ${receiver['phone']}'),
                        Text('สถานะ : ${receiver['status']}'),
                        Text('รายละเอียด : ${receiver['detail']}'),
                        if (receiver['status'] == 'รอยืนยันการส่งงาน')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: FilledButton(
                              onPressed: () {
                                statussubmit('${receiver['order_id']}', '${receiver['rider']}');
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(Colors.green),
                              ),
                              child: Text('ยืนยัน'),
                            ),
                          ),
                      ],
                    ),
                    leading: Image.network(receiver['photosender']),
                  ),
                );
              },
            )
          : Center(
              child: Text('ไม่มีรายการผู้รับในขณะนี้', style: TextStyle(fontSize: 18)),
            ),
    ),
  ],
),

                    
                    
                    // Second tab: Map Page
                    SizedBox(
                      width: double.infinity,
                      height: 300.0,
                      child: MapAll(),
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

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the TabController
    super.dispose();
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
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255)
                        .withOpacity(0.7),
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
                  child: url != null
                      ? ClipOval(
                          child: Image.network(
                            url,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, size: 40, color: Colors.grey),
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
        points: [point1!, currentLocation!],
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
      String riderNumber =
          index < ridernumber.length ? ridernumber[index] : 'Unknown';
      String receiverPic =
          index < receiverall.length ? receiverall[index]['picR'] ?? '' : '';
      // log('$receiverPic');

      return _buildImageMarkerWithPic(point, receiverPic, riderNumber);
    }).toList();
  }

  MarkerLayer _buildImageMarkerWithPic(
      LatLng point, String imageUrl, String riderNumber) {
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

  Future<void> statussubmit(String id, String rider) async {
    log('$id');
    await db.collection('Order').doc(id).update({'status': 'ส่งแล้ว'});

    await db.collection('Rider').doc(rider).update({'status': 'ว่าง'});

    readAllreceiver();
    Get.snackbar("ยืนยันการส่งงานแล้ว", "คุณได้ยืนยันการส่งงานจากไรเดอร์แล้วว");
  }
}
