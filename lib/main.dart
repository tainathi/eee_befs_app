import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:eee_befs_app/LineObject.dart';
import 'package:eee_befs_app/constants.dart';



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
  final Float32x4List _accelData = Float32x4List(kSampRate); // Number of time samples to include in the list
  final double maxWidth = window.physicalSize.width /
      window.devicePixelRatio; // maximal number of logical pixels (width: vertical orientation)
  final double maxHeight = window.physicalSize.height /
      window.devicePixelRatio; // maximal number of logical pixels (height: vertical orientation)
  final LineObject _lineObject = LineObject();
  final Stopwatch timeStamps = Stopwatch();
  final ByteData rawPoints = ByteData(100 * 4);


  @override
  void initState() {
    SensorManager()
        .isSensorAvailable(Sensors.ACCELEROMETER)
        .then((result)=> setState(() => _accelAvailable = result));
    _lineObject.addAxisSize(maxWidth, maxHeight); // setting dimensions for the line object
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: maxHeight/8,
        title: Text(widget.title),
      ),
      body: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          if (orientation == Orientation.portrait)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.black,
                  height: maxHeight/2-maxHeight/8,
                  child: ClipRect(
                    child: CustomPaint(
                      painter: LineDrawer(rawPoints: rawPoints.buffer.asFloat32List()),
                    ),
                  ),
                ),

              ],
            );
          else
            return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: startRetrievingAccData,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

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
        print(event.accuracy);
        _accelData[_counter] = Float32x4(event.data[0],event.data[1],event.data[2],21);
        _counter == kSampRate ? _counter = 0 : ++_counter; // incrementing or reseting counter
      }));
    }
  }
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
    return false;
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
