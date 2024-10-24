import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:lotto/pages/profilerider.dart';
import 'package:lotto/pages/riderreceiver.dart';

class RiderMainPages extends StatefulWidget {
  const RiderMainPages({super.key});

  @override
  State<RiderMainPages> createState() => _RiderMainPagesState();
}

class _RiderMainPagesState extends State<RiderMainPages> {
  int _selectedIndex = 1;
  Position? currentPosition;
  final storageF = GetStorage();
  var db = FirebaseFirestore.instance;
  final MapController mapController = MapController();
  final double zoomIncrement = 1.0;
  final double minZoom = 1.0;
  final double maxZoom = 18.0;
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
  List<Map<String, dynamic>> workrall = [];

  LatLng? currentLocation;
  LatLng? tappedLocation;
  LatLng? point1;

  @override
  void initState() {
    super.initState();
    initializeDB();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileriderPages()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RiderMainPages()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RiderReceiverPages()),
        );
        break;
    }
  }

  Future<void> initializeDB() async {
    await loadData();
    log('loadData');
    await readAllOder();
    log('readAllOder');
    await _loadFirebaseImage();
    log('_loadFirebaseImage');
    // getCurrentLocation();
    currentLocation = LatLng(16.251206403638957, 103.23923616148686);
  }



  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        currentPosition = position;
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      log('Error getting location: $e');
    }
  }

  Future<void> loadData() async {
    userId = storageF.read('userId');
    name = storageF.read('name');
    email = storageF.read('email');
    phone = storageF.read('phone');
    pic = storageF.read('pic');
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



  Future<void> readAllOder() async {
    var result =
        await db.collection('Order').where('rider', isEqualTo: 'no').get();

    List<Map<String, dynamic>> tempSenderList = [];

    for (var doc in result.docs) {
      String imageUrlr = '';
      var senderOr = await db.collection('User').doc(doc['sender']).get();
      var receiverOr = await db.collection('User').doc(doc['receiver']).get();

      try {
        if (doc['photosender'] != null) {
          imageUrlr = await storage
              .ref('/order/${doc['photosender']}')
              .getDownloadURL();
        }
      } catch (e) {
        log('Failed to load image: $e');
      }

      // ดึงแค่ชื่อ name จาก result2
      String sendername = senderOr.data()?['name'] ?? 'Unknown';
      String senderphone = senderOr.data()?['phone'] ?? 'Unknown';
      String senderlatitude =
          senderOr.data()?['latitude'].toString() ?? 'Unknown';
      String senderlongitude =
          senderOr.data()?['longitude'].toString() ?? 'Unknown';
      String picS = senderOr.data()?['pic'].toString() ?? 'Unknown';

      String receivername = receiverOr.data()?['name'] ?? 'Unknown';
      String receiverphone = receiverOr.data()?['phone'] ?? 'Unknown';
      String receiverlatitude =
          receiverOr.data()?['latitude'].toString() ?? 'Unknown';
      String receiverlongitude =
          receiverOr.data()?['longitude'].toString() ?? 'Unknown';
      String picR = receiverOr.data()?['pic'].toString() ?? 'Unknown';

      tempSenderList.add({
        'detail': doc['detail'],
        'photosender': imageUrlr,
        'sendername': sendername,
        'senderphone': senderphone,
        'receivername': receivername,
        'receiverphone': receiverphone,
        'receiver_id': doc['receiver'],
        'sender_id': doc['sender'],
        'order_id': doc.id,
        'latitudeR': receiverlatitude,
        'longitudeR': receiverlongitude,
        'latitudeS': senderlatitude,
        'longitudeS': senderlongitude,
        'picR': picR,
        'picS': picS,
      });
    }

    setState(() {
      workrall = tempSenderList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.purple[100],
        appBar: AppBar(
          title: Text('รับงาน'),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: workrall.length,
                  itemBuilder: (context, index) {
                    var work = workrall[index];
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        title: Text('Work : ${index + 1}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ผู้ส่ง : ${work['sendername']}'),
                            Text('ผู้รับ : ${work['receivername']}'),
                            Text('เบอร์ผู้ส่ง : ${work['senderphone']}'),
                            Text('เบอร์ผู้รับ : ${work['receiverphone']}'),
                            Text('รายละเอียด : ${work['detail']}'),
                          ],
                        ),
                        leading: Image.network(work['photosender']),
                        onTap: () {
                          workdailog(work);
                        },
                      ),
                    );
                  },
                ),
              )

              // Bottom Navigation Bar
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

  void workdailog(Map<String, dynamic> work) async {
    log('picS : ${work['picS']}');
    log('picR : ${work['picR']}');
    String picS =
        await storage.ref('/uploads/${work['picS']}').getDownloadURL();
    String picR =
        await storage.ref('/uploads/${work['picR']}').getDownloadURL();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('รายละเอียดงาน'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('ผู้ส่ง: ${work['sendername']}'),
                Text('ผู้รับ: ${work['receivername']}'),
                Text('เบอร์ผู้ส่ง: ${work['senderphone']}'),
                Text('เบอร์ผู้รับ: ${work['receiverphone']}'),
                Text('รายละเอียด: ${work['detail']}'),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 250.0,
                  child: Scaffold(
                    body: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        center: currentLocation ??
                            LatLng(
                              double.parse(work['latitudeS']),
                              double.parse(work['longitudeS']),
                            ),
                        zoom: 14.5,
                        minZoom: minZoom,
                        maxZoom: maxZoom,
                        bounds: currentLocation != null
                            ? LatLngBounds.fromPoints([
                                currentLocation!,
                                LatLng(double.parse(work['latitudeS']),
                                    double.parse(work['longitudeS'])),
                                LatLng(double.parse(work['latitudeR']),
                                    double.parse(work['longitudeR']))
                              ])
                            : null,
                        boundsOptions: const FitBoundsOptions(
                          padding: EdgeInsets.all(50.0),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        buildMapWithMarkers(
                          point1: LatLng(
                            double.parse(work['latitudeS']),
                            double.parse(work['longitudeS']),
                          ),
                          url1: picS,
                          url2: picR,
                          users: users,
                          receiverpoint: LatLng(
                            double.parse(work['latitudeR']),
                            double.parse(work['longitudeR']),
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
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ปิด'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('รับงาน'),
              onPressed: () {
                acceptOrder(work['order_id']);
              },
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
    required List<Map<String, dynamic>> users,
    required LatLng? receiverpoint,
  }) {
    List<List<LatLng>> polylinePoints = [];

    // Add polyline from current location to sender
    if (currentLocation != null && point1 != null) {
      polylinePoints.add([currentLocation!, point1]);
    }

    // Add polyline from sender to receiver
    if (point1 != null && receiverpoint != null) {
      polylinePoints.add([point1, receiverpoint]);
    }

    return Stack(
      children: [
        // Polyline Layers
        ...polylinePoints.map((points) => PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 3.0,
                  color: Colors.purple.withOpacity(0.7),
                  isDotted: true,
                ),
              ],
            )),

        // Current Location Marker
        if (currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentLocation!,
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
                        child: _firebaseImageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _firebaseImageUrl!,
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

        // Sender Marker
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
                        'ผู้ส่ง',
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
                        child: url1 != null
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
        
        // Receiver Marker
       
        if (receiverpoint != null)
         
          MarkerLayer(
            markers: [
              Marker(
                point: receiverpoint,
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
    if (currentLocation != null) {
      final currentZoom = mapController.zoom;
      if (currentZoom < maxZoom) {
        mapController.move(currentLocation!, currentZoom + zoomIncrement);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รอสักครู่ กำลังรับตำแหน่ง GPS')));
    }
  }

  void _zoomOut() {
    if (currentLocation != null) {
      final currentZoom = mapController.zoom;
      if (currentZoom > minZoom) {
        mapController.move(currentLocation!, currentZoom - zoomIncrement);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รอสักครู่ กำลังรับตำแหน่ง GPS')));
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      DocumentSnapshot riderSnapshot =
          await db.collection('Rider').doc(userId).get();
      String currentStatus = riderSnapshot['status'];

      if (currentStatus != 'ว่าง') {
            Get.snackbar("ไม่สามารถรับงานได้", "คุณยังทำงานไม่เสร็จ ไม่สามารถรับงานได้ในขณะนี้");
            Navigator.pop(context);
        return; 
      }

      log('${currentLocation!.latitude}');
      await db
          .collection('Order')
          .doc(orderId)
          .update({'rider': userId, 'status': 'ไรเดอร์รับงานแล้ว','pointX': currentLocation!.latitude, 'pointY': currentLocation!.longitude});


      await db.collection('Rider').doc(userId).update({'status': 'รับงานแล้ว'});

      Navigator.pop(context);
      Get.snackbar("รับงานสำเร็จ", "คุณสามารถเริ่มงานได้แล้ว");

      // Refresh the order list
      await readAllOder();
    } catch (e) {
      log('Error accepting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่')));
    }
  }


}
