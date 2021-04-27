import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors/sensors.dart';
import 'package:eee_befs_app/LineObject.dart';

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
  StreamSubscription<AccelerometerEvent>? accStream; // variable used to store subscriptions to the acceleration stream
  final double maxWidth = window.physicalSize.width /
      window.devicePixelRatio; // maximal number of logical pixels (width: vertical orientation)
  final double maxHeight = window.physicalSize.height /
      window.devicePixelRatio; // maximal number of logical pixels (height: vertical orientation)
  final LineObject _lineObject = LineObject();
  final Stopwatch timeStamps = Stopwatch();
  final ByteData rawPoints = ByteData(100 * 4);

  @override
  void initState() {
    _lineObject.addAxisSize(maxWidth, maxHeight); // setting dimensions for the line object
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          if (orientation == Orientation.portrait)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomPaint(
                  painter: LineDrawer(rawPoints: rawPoints.buffer.asFloat32List()),
                  child: Container(
                    height: maxHeight / 3,
                    // color: Colors.black,
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
    if (timeStamps.isRunning) {
      timeStamps.stop(); // stop timer
      accStream?.cancel(); // start listening to the acceleration stream
    } else {
      timeStamps.start(); // start timer
      accStream = accelerometerEvents.listen((event) {
        // start listening to the acceleration stream
        rawPoints.setFloat32(_counter * 8, _counter*maxWidth/49,Endian.little);
        rawPoints.setFloat32(_counter * 8 + 4, event.z/9.81*maxHeight/10 + maxHeight/2,Endian.little); // loss of precision as x is a double
        print("counter: $_counter [${event.z} ${rawPoints.getFloat32(_counter * 8+4,Endian.little)- maxHeight/2}]");
        if (_counter == 49) {
          _counter = 0;
          setState(() {
            // _lineObject.updateRawPoints(rawPoints.buffer.asFloat32List());
          });
        } else
          ++_counter;
      });
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
