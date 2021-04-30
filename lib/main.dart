import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:eee_befs_app/LineObject.dart';
import 'package:eee_befs_app/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:eee_befs_app/customised_widgets.dart';


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
  Float32x4List _accelData = Float32x4List(kSampRate*4); // creates a list where acc data will be temporarily stored
  final double maxWidth = window.physicalSize.width /
      window.devicePixelRatio; // maximal number of logical pixels (width: vertical orientation)
  final double maxHeight = window.physicalSize.height /
      window.devicePixelRatio; // maximal number of logical pixels (height: vertical orientation)
  late final LineObject _lineObject;
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
          _accelData[_counter] = Float32x4(event.data[0],event.data[1],event.data[2],0); // updating accel data

          if(_counter == kSampRate*4-1){
            _counter = 0;
            _lineObject.updateGravityAccValue(_accelData); // estimate gravity acceleration value
            _accelSubscription?.cancel(); // stop listening to the incoming data
            _accelSubscription = null;
            _accelData = Float32x4List(kSampRate); // creates a list where acc data will be temporarily stored
          } else ++_counter; // incrementing or reseting counter
        }));
      }
    });

    // Setting size of axes of the line object
    _lineObject = LineObject(samplesToPlot: kSampRate, xAxisSize: maxWidth, yAxisSize: maxHeight*kVerticalAxisSpace); // .initializeLineObject(maxWidth, maxHeight*kVerticalAxisSpace); // setting dimensions for the line object
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

          Container( // labels of settable properties
            height: 50,
            color: ThemeData.dark().primaryColor,
            child: Row(
              children: [
                // header x axis scalling
                Expanded(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(fit: BoxFit.fitWidth, child: Text("Samples\nto show", textAlign: TextAlign.center,)),
                )),
                // header y axis scalling
                Expanded(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(fit: BoxFit.fitWidth,child: Text("Full scale\n(g unit)", textAlign: TextAlign.center,)),
                )),
                // header x, y, z, values
                VerticalDivider(width: 0, thickness: 2, indent: 4, endIndent: 4),
                Expanded(flex: 3, child: FittedBox(fit: BoxFit.scaleDown,child: Text("Acceleration traces\nto plot (g unit)", textAlign: TextAlign.center,)))
              ],
            ),
          ),
          Container(
            color: Colors.black,
            child: Row(
              children: [
                ScrollItemSelection(_lineObject,kSamplesToPlot,0),
                ScrollItemSelection(_lineObject,kAccelFullScale,1),
                AccelValuesAndLines(_lineObject,Colors.purpleAccent,_lineObject.tempData.last.x,0),
                AccelValuesAndLines(_lineObject,Colors.yellowAccent,_lineObject.tempData.last.y,1), // TODO: update with y value
                AccelValuesAndLines(_lineObject,Colors.lightBlueAccent,_lineObject.tempData.last.z,2)
              ],
            ),
          ),
          Container(
            color: Colors.black,
            height: maxHeight*kVerticalAxisSpace,
            child: ClipRect(
              child: CustomPaint(
                painter: LineDrawer(lineObject: _lineObject, gridPaint: kPaintGrid),
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
        _accelData[_counter] = Float32x4(event.data[0],event.data[1],event.data[2],0); // updating accel data
        if(_counter == kSampRate-1){
//          print("x: ${event.data[0]} y: ${event.data[1]} z: ${event.data[2]}");
          _counter = 0;
          setState(() => _lineObject.updateRawPoints(_accelData));  // passing the vector with acceleration data and time stamps
//          print("x: ${_lineObject.xRawPoints.last} z: ${_lineObject.zRawPoints.last}");
        } else ++_counter; // incrementing or resetting counter

      }));
    }
  }
}

class LineDrawer extends CustomPainter {
  LineDrawer({required this.lineObject,required this.gridPaint});

  Paint gridPaint;
  LineObject lineObject;

  @override
  void paint(Canvas canvas, Size size) {

    canvas.drawPoints(PointMode.lines,List.generate(32, (index) => Offset(index/31*size.width,size.height/2)), gridPaint);
    if(lineObject.showXYZ[0])
      canvas.drawRawPoints(PointMode.polygon, lineObject.xRawPoints, kPaintAccelX);
    if(lineObject.showXYZ[1])
      canvas.drawRawPoints(PointMode.polygon, lineObject.yRawPoints, kPaintAccelY);
    if(lineObject.showXYZ[2])
      canvas.drawRawPoints(PointMode.polygon, lineObject.zRawPoints, kPaintAccelZ);


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}