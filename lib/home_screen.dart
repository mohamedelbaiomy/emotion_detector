import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tensorflow_lite/flutter_tensorflow_lite.dart';
import 'main.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController cameraController;
  String output = '';
  String confidence = '';
  loadCamera() {
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.max,
    );
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController.startImageStream((imageStream) {
            runModel(imageStream);
          });
        });
      }
    });
  }

  runModel(CameraImage image) async {
    try {
      var predections = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.1,
        asynch: true,
      );
      for (var element in predections!) {
        setState(() {
          output = element['label'];
          confidence =
              (element['confidence'] * 100).toStringAsFixed(0).toString();
        });
      }
    } catch (e) {}
  }

  loadModel() async {
    //await Tflite.close();
    try {
      await Tflite.loadModel(
        model: 'assets/model_unquant.tflite',
        labels: 'assets/labels.txt',
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Emotion Detector"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          spacing: 50,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 300,
              width: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: cameraController.value.isInitialized
                    ? CameraPreview(cameraController)
                    : Container(),
              ),
            ),
            Row(
              spacing: 15,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  output,
                  style: TextStyle(fontSize: 30),
                ),
                Text(
                  "$confidence %",
                  style: TextStyle(fontSize: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
