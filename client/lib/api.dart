import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class API extends ChangeNotifier {
  File? image;
  String cameraMode = "gallery";
  Future<void> getImage() async {
    if (cameraMode == "gallery") {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  
      if (pickedFile != null) {
        image = File(pickedFile.path);
      } else {
        Fluttertoast.showToast(msg: "No image selected");
      }
    } else if (cameraMode == "camera") {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        image = File(pickedFile.path);
      } else {
        Fluttertoast.showToast(msg: "No image selected");
      }
    } else {
      Fluttertoast.showToast(msg: "Please select an input");
    }

    _sendImage();
    notifyListeners();
  }

  // Future<void> getVideo() async {
  //     FilePicker.platform.pickFiles(
  //       type: FileType.video,
  //       allowedExtensions: ['mp4', 'mov'],
  //     ).then((value) {
  //       if (value != null) {
  //         image = File(value.files.single.path!);
          
  //       } else {
  //         Fluttertoast.showToast(msg: "No video selected");
  //       }
  //       notifyListeners();
  //     });
  // }

  String predictedClass = "None";
  Future<void> _sendImage() async {
    if (image == null) {
      Fluttertoast.showToast(msg: "Please select an image");
      return;
    }

    String apiUrl = "http://192.168.0.104:9000/predict";

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files.add(await http.MultipartFile.fromPath('image', image!.path));
    predictedClass = "";
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        double threshold = 0.5;
        var res = jsonDecode(responseBody);

        if (res['real'] > threshold) {
          predictedClass = 'Real';
          notifyListeners();
        } else {
          predictedClass = 'Fake';
          notifyListeners();
        }
      } else {
        Fluttertoast.showToast(msg: "Error: ${response.statusCode}");

        predictedClass = "None";
        notifyListeners();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
    notifyListeners();
  }
}
