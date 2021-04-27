import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:eee_befs_app/LineObject.dart';
import 'package:eee_befs_app/constants.dart';
import 'package:flutter/cupertino.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: MainPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  int _counter = 0;
  bool _accelAvailable = false;  // check for whether accelerometer is present in the user device
  StreamSubscription? _accelSubscription; // variable managing subscription to the stream receiving acc data
  final List<List<double>> _accelData = List.generate(4, (index) => List.filled(kSampRate,0)); // creates a list where acc data will be temporarily stored
  final double maxWidth = window.physicalSize.width /
      window.devicePixelRatio; // maximal number of logical pixels (width: vertical orientation)
  final double maxHeight = window.physicalSize.height /
      window.devicePixelRatio; // maximal number of logical pixels (height: vertical orientation)
  final LineObject _lineObject = LineObject();
  final Stopwatch timeStamps = Stopwatch();

  @override
  void initState() {
    // check for the presence of acceleration sensor in the target device
    SensorManager()
        .isSensorAvailable(Sensors.ACCELEROMETER)
        .then((result) {
      if (result) { // if there is an accelerometer then
        SensorManager().sensorUpdates(
          sensorId: Sensors.ACCELEROMETER,  // Start listening to incoming values,
          interval: Sensors.SENSOR_DELAY_GAME, // sampling roughly 1s of data (~50 Hz sampling rate),
        ).then((value) => _accelSubscription = value.listen((SensorEvent event) { // and then estimate gravity acceleration
          _accelData[0][_counter] = event.data[0]; // updating x accel data
          _accelData[1][_counter] = event.data[1]; // updating y accel data
          _accelData[2][_counter] = event.data[2]; // updating z accel data

          if(_counter == kSampRate-1){
            _counter = 0;
            _lineObject.updateGravityAccValue(_accelData); // estimate gravity acceleration value
            _accelSubscription?.cancel(); // stop listening to the incoming data
            _accelSubscription = null;
          } else ++_counter; // incrementing or reseting counter
        }));
      }
    });

    // Setting size of axes of the line object
    _lineObject.initializeLineObject(maxWidth, maxHeight*kVerticalAxisSpace); // setting dimensions for the line object

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(),
          ),
          Container(
            child: Row(
              children: [

              ],
            ),
          ),
          Container(
            color: Colors.black,
            height: maxHeight*kVerticalAxisSpace,
            child: ClipRect(
              child: CustomPaint(
                painter: LineDrawer(rawPoints: _lineObject.zRawPoints),
                // painter: LineDrawer(rawPoints: rawPoints.buffer.asFloat32List()),
              ),
            ),
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: startRetrievingAccData,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // Method managing the start and stop of acceleration sampling
  void startRetrievingAccData() {
    if (_accelSubscription != null){
      _accelSubscription?.cancel();
      _accelSubscription = null;
      timeStamps.stop();
    } else {
      if(!timeStamps.isRunning) timeStamps.start(); // start time event
      SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        interval: Sensors.SENSOR_DELAY_FASTEST, // This should correspond to ~50 Hz sampling rate
      ).then((value) => _accelSubscription = value.listen((SensorEvent event) {
        // timeStamps.elapsedMilliseconds/1000
        // print(_lineObject.xRawPoints);
        _accelData[0][_counter] = event.data[0]; // updating x accel data
        _accelData[1][_counter] = event.data[1]; // updating y accel data
        _accelData[2][_counter] = event.data[2]; // updating z accel data
        if(_counter == kSampRate-1){
          print("x: ${event.data[0]} y: ${event.data[1]} z: ${event.data[2]}");
          _counter = 0;
          setState(() => _lineObject.updateRawPoints(_accelData));  // passing the vector with acceleration data and time stamps
          print("x: ${_lineObject.xRawPoints.last} z: ${_lineObject.zRawPoints.last}");
        } else ++_counter; // incrementing or resetting counter

      }));
    }
  }
}


Widget ScrollItemSelection(LineObject lineObject){
  if (Platform.isIOS)
    return CupertinoPicker(
      children: List.generate(kSamplesToPlot.length, (index) => Text("${kSamplesToPlot[index]} s")),
      itemExtent: 20,
      onSelectedItemChanged: (int value) => null,
    );
  else
    return Container();//DropdownButton(items: items)
}

class LineDrawer extends CustomPainter {
  LineDrawer({required this.rawPoints});

  Float32List rawPoints;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawRawPoints(PointMode.polygon, rawPoints, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// method used to estimate the average sampling rate of acceleration data retrieving
// void getAverageSamplingRate() {
//   final List<int> firstSamples = []; // variable created with the goal of knowing the sampling frequency of acceleration data
//
//   timeStamps.start(); // initialize the timer
//   if (accStream == null) // start listening to the acceleration stream
//     accStream =
//         accelerometerEvents.listen((event) => setState(() {
//           firstSamples.add(DateTime.now().millisecond);
//           print(DateTime.now().millisecond);
//         }));
//
//   // set a timer, during which acceleration time stamps will be stored
//   Timer(
//     Duration(seconds: 2), // after the first 2 s
//         () => accStream?.cancel().then((value) {
//       // stop listening to the stream
//       accStream = null; // set it back to null
//       timeStamps.stop(); // stop the counter
//       double sf = 0; // initialize the sampling rate value at 0
//       for (int i = 1; i < firstSamples.length; i++) sf += (firstSamples[i] - firstSamples[i - 1]);
//       // for used to compute the sum of sampling intervals
//       sf = (firstSamples.length - 1) *1000/ sf; // averaging sampling rate
//       print("N=${firstSamples.length}\n$firstSamples\nSF = $sf");
//       firstSamples.clear();
//       setState(() => _counter = sf);
//     }),
//   );
// }
