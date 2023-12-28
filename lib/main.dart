import 'dart:async';
import 'dart:isolate';

import 'package:background/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:rxdart/rxdart.dart';
import 'package:workmanager/workmanager.dart';

const task = 'seizure_detection';
const MethodChannel _channel = MethodChannel('your_channel_name');

void handleAccelerometerEvent(AccelerometerEvent event) {
  // Handle accelerometer events here
  // print('Accelerometer Event: $event');
}


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) {
    switch (task){
      case 'seizure_detection':
        _startListening();
        // startBackgroundTask();
        break;
    }
    return Future.value(true);
  });
}

List<double> inputArray = [];// Concatenated array of 3 input arrays
List<double> inputArray2 = [];
List<double> inputArray3 = [];
List<double> array1 = [];
List<double> array2 = [];
List<double> array3 = [];

List<List<double>> output = List.filled(1, List.filled(4, 0.0));

List<List<double>> output2 = List.filled(1, List.filled(4, 0.0));
List<List<double>> output3 = List.filled(1, List.filled(4, 0.0));

int progress =0;
String hi = "abc";
late Timer printTimer;
// late Isolate isolate;
// late FlutterIsolate _isolate;

late tfl.Interpreter _interpreter;
// late tfl.Interpreter rfInterpreter;
// late tfl.Interpreter knnInterpreter;
// late tfl.Interpreter svmInterpreter;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(onPressed: () {
              print(array1.length);
              // Seiz
            } , child: Text("CHECKING array"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _incrementCounter();
          Workmanager().registerPeriodicTask("SeizureDetector", task);
          // print(array1.length);
          },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

  void _startListening() {
    print("Seizure detection is active.");
    NotificationService().showNotification(
      title: "MONITORING MOTION",
      body: "HI READING ACCELEROMETER DATA",
    );

    accelerometerEvents
        .throttleTime(const Duration(milliseconds: 50))
        .listen((AccelerometerEvent event) {
      handleAccelerometerEvent(event);
    });
    // NotificationService().showNotification(
    //   title: "MONITORING MOTION", body: "HI READING ACCELEROMETER DATA",);
    double modify_x = 1.0;
    double modify_y = 0.5;
    double modify_z = 0.5;
    double gravity = 9.80665;
    accelerometerEvents
        .throttleTime(
        const Duration(milliseconds: 50)) // Capture around 16 values per second
        .listen((AccelerometerEvent event) {
      print('Accelerometer Event Array Length: ${array1.length}');
      if (event.x < 0) {
        array1.add((event.x - modify_x) / gravity);
      } else {
        array1.add((event.x + modify_x) / gravity);
      }
      if (event.y < 0) {
        // print("____________________");
        array2.add((event.y - modify_y) / gravity);
      } else {
        // print("!!!!!!!!!!!!!!!!!!!!!!!!!");
        array2.add((event.y + modify_y) / gravity);
      }
      if (event.z < 0) {
        array3.add((event.z - modify_z) / gravity);
      } else {
        array3.add((event.z + modify_z) / gravity);
      }

      progress = array1.length;

      if (array1.length == 206) {
        _makePrediction();
        // Clear the arrays after making the prediction
        // array1.clear();
        // array2.clear();
        // array3.clear();
        array1 = [];
        array2 = [];
        array3 = [];
      } else if (array1.length > 206) {
        print("Excceed Length Not good");
        array1 = [];
        array2 = [];
        array3 = [];
        // array1.clear();
        // array2.clear();
        // array3.clear();
      }
    });
  }

  Future<void> _makePrediction() async {
    // Concatenate the arrays
    // inputArray = [];

    inputArray.addAll(array1);
    inputArray.addAll(array2);
    inputArray.addAll(array3);

    inputArray2.addAll(array2);
    inputArray2.addAll(array3);
    inputArray2.addAll(array1);

    inputArray3.addAll(array3);
    inputArray3.addAll(array2);
    inputArray3.addAll(array1);

    // Reshape the input to match the expected shape [1, 4]
    List<List<double>> reshapedInput = [inputArray];

    List<List<double>> reshapedInput2 = [inputArray2];
    List<List<double>> reshapedInput3 = [inputArray3];

    // Make prediction
    List<List<double>> outputRFNEW = List.filled(1, List.filled(4, 0.0));

    List<List<double>> outputKNNNEW = List.filled(1, List.filled(4, 0.0));
    List<List<double>> outputSVMNEW = List.filled(1, List.filled(4, 0.0));

    print(array1);
    print(array2);
    print(array3);

    _interpreter.run(reshapedInput, output);
    _interpreter.run(reshapedInput2, output2);
    _interpreter.run(reshapedInput3, output3);

    // rfInterpreter.run(inputArray, outputRFNEW);
    // print("Prediction of New RF: ${outputRFNEW[0]}");

    // knnInterpreter.invoke();

    // knnInterpreter.run(inputArray, outputKNNNEW);
    // print("Prediction of New KNNNew: ${outputKNNNEW[0]}");

    // svmInterpreter.run(inputArray, outputSVMNEW);
    // print("Prediction of New SVM: ${outputSVMNEW[0]}");

    // Handle the prediction output
    print("Prediction Output 1: ${output[0]}");

    print("Prediction Output 2: ${output2[0]}");
    print("Prediction Output 3: ${output3[0]}");
    String temp = "";
    // print(_interpreter.getOutputIndex(temp));
    // i=i+1;notification_services.dart
    output;
    output2;
    output3;

    if (output[0][0] > output[0][1] &&
        output[0][0] > output[0][2] &&
        output[0][0] > output[0][3]) {
      print("Seizure Detected!");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Seizure Detected!'),
      //     duration: Duration(seconds: 3),
      //   ),
      // );
      NotificationService().showNotification(title: "SHAKE DETECTED",
          body: "You might be experiencing Seizure");
    } else {
      print("No Seizure Detected Array 1.");
    }

    if (output2[0][0] > output2[0][1] &&
        output2[0][0] > output2[0][2] &&
        output2[0][0] > output2[0][3]) {
      print("Seizure Detected!");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Seizure Detected!'),
      //     duration: Duration(seconds: 3),
      //   ),
      // );
      NotificationService().showNotification(title: "SHAKE DETECTED",
          body: "You might be experiencing Seizure");
    } else {
      print("No Seizure Detected Array 2.");
    }

    if (output3[0][0] > output3[0][1] &&
        output3[0][0] > output3[0][2] &&
        output3[0][0] > output3[0][3]) {
      print("Seizure Detected!");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Seizure Detected!'),
      //     duration: Duration(seconds: 3),
      //   ),
      // );
      NotificationService().showNotification(title: "SHAKE DETECTED",
          body: "You might be experiencing Seizure");
    } else {
      print("No Seizure Detected Array 3.");
    }

    inputArray = [];
    inputArray2 = [];
    inputArray3 = [];
    _interpreter.close();
    // rfInterpreter.close();
    // knnInterpreter.close();
    // svmInterpreter.close();
    // loadknn();
    // loadsvm();
    _loadModel();
  }

  Future<void> _loadModel() async {
    // final interpreterOptions = tfl.InterpreterOptions()..threads = 2;
    // _interpreter = await tfl.ListShape.
    _interpreter = await tfl.Interpreter.fromAsset(
      'assets/rf_keras_model.tflite',
      options: tfl.InterpreterOptions(),
    );

    // rfInterpreter = await tfl.Interpreter.fromAsset(
    //     'assets/rfNEW.tflite', options: tfl.InterpreterOptions());
  }


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask("SeizureDetector", task);

  _loadModel();
  _startListening();

  runApp(const MyApp());
}