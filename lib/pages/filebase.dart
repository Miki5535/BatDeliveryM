import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lotto/pages/firebase2.dart';
import 'package:lotto/shared/appdata.dart';
import 'package:provider/provider.dart';

class FilebasePages extends StatefulWidget {
  const FilebasePages({super.key});

  @override
  State<FilebasePages> createState() => _FilebasePagesState();
}

class _FilebasePagesState extends State<FilebasePages> {
  final TextEditingController docCtl = TextEditingController();
  final TextEditingController nameCtl = TextEditingController();
  final TextEditingController messageCtl = TextEditingController();
  var db = FirebaseFirestore.instance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    docCtl.text = 'Doc1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            const Text('Document'),
            TextField(
              controller: docCtl,
            ),
            const Text('Name'),
            TextField(
              controller: nameCtl,
            ),
            const Text('Message'),
            TextField(
              controller: messageCtl,
            ),
            FilledButton(
                onPressed: () {
                  var data = {
                    'name': nameCtl.text,
                    'message': messageCtl.text,
                    'createAt': DateTime.timestamp()
                  };

                  db.collection('inbox').doc(docCtl.text).set(data);
                },
                child: const Text('Add Data')),
            SizedBox(
              height: 10,
            ),
            FilledButton(onPressed: readData, child: const Text('Read Data')),
            SizedBox(
              height: 10,
            ),
            FilledButton(onPressed: queryData, child: const Text('Query Data')),
            SizedBox(
              height: 10,
            ),
            FilledButton(
                onPressed: startRealtimeGet,
                child: const Text('Start Real-time Get')),
            SizedBox(
              height: 10,
            ),
            FilledButton(
                onPressed: stopRealTime,
                child: const Text('Stop Real-time Get')),
                SizedBox(
              height: 10,
            ),
            FilledButton(
                onPressed: (){
                  Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Filebase2Pages()),
        );
                },
                child: const Text('Page2'))
          ],
        ),
      ),
    );
  }

  void readData() async {
    var result = await db.collection('inbox').doc(docCtl.text).get();
    var data = result.data();
    log(data!['message']);
    log((data['createAt'] as Timestamp).millisecondsSinceEpoch.toString());
  }

  void queryData() async {
    var inboxRef = db.collection("inbox");
    var query = inboxRef.where("name", isEqualTo: nameCtl.text);
    var result = await query.get();
    if (result.docs.isNotEmpty) {
      log(result.docs.first.data()['message']);
    }
  }

  void startRealtimeGet() {
    final docRef = db.collection("inbox").doc(docCtl.text);

    if (context.read<AppData>().listener != null) {
      context.read<AppData>().listener!.cancel();
      context.read<AppData>().listener = null;
      log('Listener Stop');
    }

    context.read<AppData>().listener = docRef.snapshots().listen(
      (event) {
        var data = event.data();
        Get.snackbar(data!['name'].toString(), data['message'].toString());
        log("current data: ${event.data()}");
      },
      onError: (error) => log("Listen failed: $error"),
    );
  }

  void stopRealTime() {
    if (context.read<AppData>().listener != null) {
      context.read<AppData>().listener!.cancel();
      context.read<AppData>().listener = null;
      log('Listener Stop');
    }
  }

  
}
