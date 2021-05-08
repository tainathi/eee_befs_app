import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:eee_befs_app/LineEnExEsObject.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:eee_befs_app/LineAccelObject.dart';
import 'package:eee_befs_app/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:eee_befs_app/customised_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity/connectivity.dart';
import 'package:path_provider/path_provider.dart';
import 'WriteDataToDevice.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((_) {
    runApp(new EeeBefsApp());
  });
  
  runApp(EeeBefsApp());
}

class EeeBefsApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Properties for managing Thingspeak communication and data storage
  final Connectivity _connectivity = Connectivity();
  final List<String> _users = [];
  final List<String> _apiKeyWrite = [];
  final List<String> _apiKeyRead = [];
  final List<bool> _selectedUser = [];
  final WriteDataToDevice _writeDataToDevice = WriteDataToDevice();
  SharedPreferences? _sharedPreferences;
  ConnectivityResult networkStatus = ConnectivityResult.none;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _timer; // timer used to indicate the time elapsed from acquisition start

  // Properties for managing acceleration data retrieval and display
  int _counter = 0;
  bool _accelAvailable = false; // check for whether accelerometer is present in the user device
  StreamSubscription? _accelSubscription; // variable managing subscription to the stream receiving acc data
  Float32x4List _accelData = Float32x4List(kSampRate * 4); // creates a list where acc data will be temporarily stored
  final double maxWidth = window.physicalSize.width /
      window.devicePixelRatio; // maximal number of logical pixels (width: vertical orientation)
  final double maxHeight = window.physicalSize.height /
      window.devicePixelRatio; // maximal number of logical pixels (height: vertical orientation)
  late final LineAccelObject _accLineObject;
  final LineEnExEsObject _eeeLineObject = LineEnExEsObject();
  final Stopwatch timeStamps = Stopwatch();


  @override
  void initState() {


    _writeDataToDevice.setFileForDataStorage();
    // // Retrieving the directory where data will be stored
    // Platform.isAndroid
    //     ? getExternalStorageDirectory().then((value) => _writeDataToDevice.setFileForDataStorage(value))
    //     : getApplicationDocumentsDirectory().then((value) => _writeDataToDevice.setFileForDataStorage(value));

    // Checking for the existence of shared preferences
    SharedPreferences.getInstance().then((value) => getSharedPreferences(value)).catchError((object) => print(object));

    // setting methods for listening to changes in connection status
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_checkConnectionStatus); // _checkConnectionStatus
    _connectivity.checkConnectivity().then((connectivityResult) => networkStatus = connectivityResult);

    // check for the presence of acceleration sensor in the target device
    SensorManager().isSensorAvailable(Sensors.ACCELEROMETER).then((result) {
      if (result) {
        // if there is an accelerometer then
        SensorManager()
            .sensorUpdates(
              sensorId: Sensors.ACCELEROMETER, // Start listening to incoming values,
              interval: Sensors.SENSOR_DELAY_GAME, // sampling roughly 1s of data (~50 Hz sampling rate),
            )
            .then((value) => _accelSubscription = value.listen((SensorEvent event) {
                  // and then estimate gravity acceleration
                  _accelData[_counter] =
                      Float32x4(event.data[0], event.data[1], event.data[2], 0); // updating accel data

                  if (_counter == kSampRate * 4 - 1) {
                    _counter = 0;
                    _accLineObject.updateGravityAccValue(_accelData); // estimate gravity acceleration value
                    _accelSubscription?.cancel(); // stop listening to the incoming data

                    _accelData = Float32x4List(kSampRate); // creates a list where acc data will be temporarily stored
                    _accelAvailable = true;
                    setState(() => _accelSubscription = null);
                  } else
                    ++_counter; // incrementing or reseting counter
                }));
      }
    });

    // Setting size of axes of the line object
    _accLineObject =
        LineAccelObject(samplesToPlot: kSampRate, xAxisSize: maxWidth, yAxisSize: maxHeight * kVerticalAxisSpace*0.95);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
                message: "$networkStatus",
                child: Icon(networkStatus==ConnectivityResult.none ? Icons.signal_wifi_off_rounded : Icons.signal_wifi_4_bar_rounded)),
          ),
        ],
        title: Text("EEE BEFS"),
      ),
      drawer: _sharedPreferences == null ? null : _accLineObject.running ? null : createDrawer(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Body mass setter and Energy Expenditure display
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
              color: Colors.black,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Body mass setter
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: FittedBox(
                                fit: BoxFit.fill,
                                child: GestureDetector(
                                    onTap: setBodyMass,
                                    child: Text(
                                      "${_eeeLineObject.bodyMass}",
                                      style: TextStyle(fontSize: 1000),
                                    ))),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18.0),
                            child: Text(
                              "body mass (kg)",
                              style: TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          )
                        ],
                      ),
                    ),

                    // Energy expenditure display
                    Expanded(
                      child: Container(
                        color: Colors.teal.shade900,
                        child: Stack(children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: FittedBox(
                                      fit: BoxFit.fitHeight,
                                      child: Text(
                                        "Cumulative, energy expenditure\nestimated (0-${_eeeLineObject.maxEEValue} kcal)",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white),
                                      )),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: ClipRect(
                                  child: CustomPaint(
                                    painter: EnExEslLineDrawer(lineObject: _eeeLineObject),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Display of the current EE value
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                shape: BoxShape.circle,
                              ),
                              height: 48,
                              width: 48,
                              child: FittedBox(
                                  fit: BoxFit.fitHeight,
                                  child: Text("${_eeeLineObject.dataPoints.last.toStringAsFixed(0)}")),
                            ),
                          ),
                        ]),
                      ),
                    )
                  ]),
            ),
          ),

          // Switchers defining when to estimate EE and send data to server
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Estimate EE
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Estimate energy expenditure:',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: CupertinoSwitch(
                            activeColor: Colors.tealAccent.withOpacity(0.4),
                            trackColor: ThemeData.dark().secondaryHeaderColor,
                            value: _eeeLineObject.estimateEE,
                            onChanged: (status) {
                              _eeeLineObject.estimateEE = status;
                              if (!_accLineObject.running) setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                  ),

                  // Send data to ThingSpeak
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Send data data to ThingSpeak:',
                              textAlign: TextAlign.start,
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: CupertinoSwitch(
                            activeColor: Colors.tealAccent.withOpacity(0.4),
                            trackColor: ThemeData.dark().secondaryHeaderColor,
                            value: _eeeLineObject.sendData,
                            onChanged: networkStatus == ConnectivityResult.none
                                ? null
                                : _selectedUser.isEmpty
                                    ? null
                                    : (status) {
                                        _eeeLineObject.sendData = status;
                                        if (!_accLineObject.running) setState(() {});
                                      },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Labels of settable properties
          Container(
            margin: EdgeInsets.only(top: 4.0),
            height: 50,
            color: ThemeData.dark().primaryColor,
            child: Row(
              children: [
                // header x axis scalling
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: Text(
                        "Samples\nto show",
                        textAlign: TextAlign.center,
                      )),
                )),
                VerticalDivider(width: 0, thickness: 2, indent: 4, endIndent: 4),
                // header y axis scalling
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: Text(
                        "Full scale\n(g unit)",
                        textAlign: TextAlign.center,
                      )),
                )),
                // header x, y, z, values
                VerticalDivider(width: 0, thickness: 2, indent: 4, endIndent: 4),
                Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Text(
                            "Acceleration traces\nto plot (g unit)",
                            textAlign: TextAlign.center,
                          )),
                    ))
              ],
            ),
          ),

          // Controller for setting properties
          Container(
            color: Colors.black,
            child: Row(
              children: [
                ScrollItemSelection(_accLineObject, kSamplesToPlot, 0),
                ScrollItemSelection(_accLineObject, kAccelFullScale, 1),
                AccelValuesAndLines(_accLineObject, Colors.purpleAccent, _accLineObject.tempData.last.x, 0,
                    _accelSubscription, setState),
                AccelValuesAndLines(_accLineObject, Colors.yellowAccent, _accLineObject.tempData.last.y, 1,
                    _accelSubscription, setState),
                AccelValuesAndLines(_accLineObject, Colors.lightBlueAccent, _accLineObject.tempData.last.z, 2,
                    _accelSubscription, setState)
              ],
            ),
          ),

          // Graphic where signal will be plotted
          Container(
            color: Colors.black,
            height: maxHeight * kVerticalAxisSpace,
            child: Stack(
              children: [
                Container(
                  height: maxHeight * kVerticalAxisSpace,
                  width: double.infinity,
                  child: ClipRect(
                    child: CustomPaint(
                      painter: AccelLineDrawer(lineObject: _accLineObject),
                      // painter: LineDrawer(rawPoints: rawPoints.buffer.asFloat32List()),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: _timer==null ? null : Container(
                    padding: EdgeInsets.only(bottom: 16.0, left: 64.0),
                    height: 64,
                    width: 128,
                    child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Text("${_timer?.tick} s")),
                  ),
                ),
              ]),
          ),
        ],
      ),
      floatingActionButton: !_accelAvailable ? null : Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: ThemeData.dark().secondaryHeaderColor,
          shape: BoxShape.circle,
        ),
        child: RawMaterialButton(
          shape: CircleBorder(),
          highlightColor: Colors.teal,
          child: Icon(_accLineObject.recording ? Icons.save_alt : _accLineObject.running ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: _accLineObject.recording ? Colors.redAccent : Colors.white,
          ),
          onPressed: () {
            if(_accLineObject.recording){
              _accLineObject.recording = false;
              _writeDataToDevice.stopAcquisition();
              _timer?.cancel();
              _timer=null;
            } else
              startRetrievingAccData();
            },
          onLongPress: (){
            if(_accLineObject.running){
              _timer = Timer.periodic(Duration(seconds: 1), (timer) {});
              _writeDataToDevice.startAcquisition();
              _accLineObject.recording = true;
            }
            },
        ),
      ),
    );
  }

  // Method managing the start and stop of acceleration sampling
  void startRetrievingAccData() {

    setState(() => _accLineObject.running = !_accLineObject.running);
    if (_accelSubscription != null) {
      _accelSubscription?.cancel();
      _accelSubscription = null;
      timeStamps.stop();
    } else {
      if (!timeStamps.isRunning) timeStamps.start(); // start time event
      SensorManager()
          .sensorUpdates(
            sensorId: Sensors.ACCELEROMETER,
            interval: _accLineObject.fastestSampRate ? Sensors.SENSOR_DELAY_FASTEST : Sensors.SENSOR_DELAY_GAME, // This should correspond to ~50 Hz sampling rate
          )
          .then((value) => _accelSubscription = value.listen((SensorEvent event) {
                // timeStamps.elapsedMilliseconds/1000
                _accelData[_counter] = Float32x4(event.data[0]/_accLineObject.gravityAcc, event.data[1]/_accLineObject.gravityAcc, event.data[2]/_accLineObject.gravityAcc, timeStamps.elapsedMilliseconds/1000); // updating accel data

                if (_counter == kSampRate - 1) {
                  _counter = 0;
                  // _eeeLineObject.sendDataToThingSpeak(); // TODO: call this method when 15 s have elapsed
                  setState(() => _accLineObject
                      .updateRawPoints(_accelData,_writeDataToDevice.ioSink)); // passing the vector with acceleration data and time stamps

                } else
                  ++_counter; // incrementing or resetting counter
              }),
      );
    }
  }

  // Method used to set body mass value
  void setBodyMass() {
    int bodyMass = _eeeLineObject.bodyMass - kMinBodyMass;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        height: maxHeight * 0.3,
        decoration: BoxDecoration(
          color: Colors.teal.shade900,
          borderRadius: new BorderRadius.only(
            topLeft: const Radius.circular(10.0),
            topRight: const Radius.circular(10.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  "Select body mass (kg) for EE estimation",
                  style: TextStyle(color: Colors.white),
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100.0),
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: bodyMass),
                itemExtent: maxHeight * 0.15,
                onSelectedItemChanged: (value) => bodyMass = value + kMinBodyMass,
                children: List.generate(
                  kMaxBodyMass - kMinBodyMass,
                  (index) => FittedBox(
                      fit: BoxFit.fitHeight,
                      child: Text(
                        "${index + kMinBodyMass}",
                        style: TextStyle(color: Colors.white),
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((value) => setState(() => _eeeLineObject.bodyMass = bodyMass));
  }

  // Method used to create the drawer
  Align createDrawer() {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        height: MediaQuery.of(context).size.height / 3,
        child: Drawer(
            child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top,
              child: DrawerHeader(
                child: Text(
                  'System Configuration',
                  style: TextStyle(color: Colors.white),
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
              ),
            ),
            // Hardware configuration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('API Key settings'),
                  IconButton(icon: Icon(Icons.vpn_key), color: Colors.white,
                    onPressed: () {
                    Navigator.pop(context);
                    apiKeySettings();
                  }),
                ],
              ),
            ),
            Divider(thickness: 2, indent: 8, endIndent: 8,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Sampling rate:"),
                  ChoiceChip(label: Text("50 Hz"), selected: !_accLineObject.fastestSampRate,
                    onSelected: (selected)=> setState(()=>_accLineObject.fastestSampRate=!_accLineObject.fastestSampRate),
                  ),
                  ChoiceChip(label: Text("Fastest"), selected: _accLineObject.fastestSampRate,
                    onSelected: (selected)=> setState(()=>_accLineObject.fastestSampRate=!_accLineObject.fastestSampRate),
                  )
                  ],
                ),
            ),
            // Visualization settings
          ],
        )),
      ),
    );
  }

  // Method called to update hardware settings
  Future<void> apiKeySettings() async {
    String? tempUser;
    String? tempApiKeyWrite;
    String? tempApiKeyRead;
    //TODO: add channel ID
    StreamController<List<String>> controller = StreamController<List<String>>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          contentTextStyle: TextStyle(fontSize: 15, color: Colors.black),
          title: Text(
            'Change API Key settings',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // user with valid, API Keys
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _users.isEmpty ? 'Set and then add user' : 'Select user:',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                StreamBuilder(
                    stream: controller.stream,
                    initialData: _users,
                    builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                      // _users.isEmpty ? Container():
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: kThemeColor, width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        height: MediaQuery.of(context).size.height / 4,
                        width: MediaQuery.of(context).size.width / 2,
                        child: ListView.separated(
                          itemCount: _users.length,
                          itemBuilder: (context, item) => Container(
                            color: _selectedUser[item] ? Colors.black : ThemeData.dark().secondaryHeaderColor,
                            child: ListTile(
                              dense: true,
                              title: Text('${snapshot.data?[item]}'),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(child: Text('Write API: ${_apiKeyWrite[item]}')),
                                  Expanded(child: Text('Read API: ${_apiKeyRead[item]}')),
                                  //TODO: add channel ID
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _users.removeAt(item);
                                  _apiKeyWrite.removeAt(item);
                                  _apiKeyRead.removeAt(item);
                                  _selectedUser.removeAt(item);
                                  // TODO: add channel ID
                                  controller.add(_users);
                                },
                              ),
                              onTap: () {
                                _selectedUser.replaceRange(
                                    0, _selectedUser.length, List.generate(_selectedUser.length, (index) => false));
                                _selectedUser[item] = true;
                                controller.add(_users);
                              },
                            ),
                          ),
                          separatorBuilder: (context, item) => Divider(height: 0),
                        ),
                      );
                    }),

                // User API Key for writing to be added
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Enter API key for writing:', style: TextStyle(color: Colors.white)),
                ),
                TextFormField(
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'input a valid key write',
                    border: OutlineInputBorder(borderSide: BorderSide(color: kThemeColor)),
                  ),
                  keyboardType: TextInputType.text,
                  onChanged: (value) => value.length < 1 ? tempApiKeyWrite = null : tempApiKeyWrite = value,
                ),
                SizedBox(height: 10),

                // User API Key for reading to be added
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Enter API key for reading:',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextFormField(
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'input a valid key read',
                    border: OutlineInputBorder(borderSide: BorderSide(color: kThemeColor)),
                  ),
                  keyboardType: TextInputType.text,
                  onChanged: (value) => value.length < 1 ? tempApiKeyRead = null : tempApiKeyRead = value,
                ),
                SizedBox(height: 10),

                // adding probe if necessary
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: 'New User Name',
                            border: OutlineInputBorder(borderSide: BorderSide(color: kThemeColor)),
                          ),
                          keyboardType: TextInputType.text,
                          onChanged: (value) => value.length < 1 ? tempUser = null : tempUser = value,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: kThemeColor),
                          child: RawMaterialButton(
                            shape: CircleBorder(),
                            child: Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              if (tempUser == null || tempApiKeyRead == null || tempApiKeyWrite == null) {
                                return;
                              }
                              _users.add(tempUser ?? "");
                              _apiKeyRead.add(tempApiKeyRead ?? "");
                              _apiKeyWrite.add(tempApiKeyWrite ?? "");
                              if (_selectedUser.isNotEmpty)
                                _selectedUser.replaceRange(
                                    0, _selectedUser.length, List.generate(_selectedUser.length, (index) => false));
                              _selectedUser.add(true);
                              print(_selectedUser);
                              print(_users);
                              print(_apiKeyWrite);
                              print(_apiKeyRead);
                              print(tempUser);
                              controller.add(_users);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // Confirm deletion button
            FlatButton(
              child: Text('Done', style: TextStyle(fontWeight: FontWeight.w900, color: kThemeColor)),
              onPressed: _users.isEmpty
                  ? () => Navigator.pop(context)
                  : () async {
                      await _sharedPreferences?.setStringList("users", _users);
                      await _sharedPreferences?.setStringList("apiKeyRead", _apiKeyRead);
                      await _sharedPreferences?.setStringList("apiKeyWrite", _apiKeyWrite);
                      await _sharedPreferences?.setInt("selectedUser", _selectedUser.indexOf(true));
                      _eeeLineObject.apiKeyWrite = _apiKeyWrite[_selectedUser.indexOf(true)];
                      setState(() => Navigator.pop(context));
                    },
            ),
            // Cancel deletion
          ],
        );
      },
    );
  }

  // Method for getting any shared preferences
  void getSharedPreferences(SharedPreferences sharedPreferences) {
    // Assigning api keys from the list in shared preferences
    if (sharedPreferences.containsKey("users")) {
      _users.addAll(sharedPreferences.getStringList("users") ?? []);
      _apiKeyRead.addAll(sharedPreferences.getStringList("apiKeyRead") ?? []);
      _apiKeyWrite.addAll(sharedPreferences.getStringList("apiKeyWrite") ?? []);
      _selectedUser.addAll(List.generate(_users.length, (index) => false));
      int? user = sharedPreferences.getInt("selectedUser");

      if (user != null) {
        _eeeLineObject.apiKeyWrite = _apiKeyWrite[user];
        user >= _selectedUser.length ? _selectedUser.first = true : _selectedUser[user] = true;
      }
    }
    setState(() => _sharedPreferences = sharedPreferences);
  }

  // method for updating connection status upon connection changes
  void _checkConnectionStatus(ConnectivityResult connectivityResult) {
    print(connectivityResult);
    // TODO: update this for iOS (see https://github.com/johnwargo/flutter-android-connectivity-permissions/blob/master/lib/main.dart)
    setState(() => networkStatus = connectivityResult);
  }
}

class AccelLineDrawer extends CustomPainter {
  AccelLineDrawer({required this.lineObject});

  LineAccelObject lineObject;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPoints(
        PointMode.lines, List.generate(32, (index) => Offset(index / 31 * size.width, size.height / 2)), kPaintGrid);

    if (lineObject.showXYZ[0]) canvas.drawRawPoints(PointMode.polygon, lineObject.xRawPoints, kPaintAccelX);
    if (lineObject.showXYZ[1]) canvas.drawRawPoints(PointMode.polygon, lineObject.yRawPoints, kPaintAccelY);
    if (lineObject.showXYZ[2]) canvas.drawRawPoints(PointMode.polygon, lineObject.zRawPoints, kPaintAccelZ);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class EnExEslLineDrawer extends CustomPainter {
  EnExEslLineDrawer({required this.lineObject});

  LineEnExEsObject lineObject;

  @override
  void paint(Canvas canvas, Size size) {
    // drawing grid lines (min, always 0, and max, currently set at 50 kcal)
    canvas.drawPoints(PointMode.lines, List.generate(24, (index) => Offset(index / 23 * size.width, size.height)),
        kPaintGrid); // min grid line
    canvas.drawPoints(
        PointMode.lines, List.generate(24, (index) => Offset(index / 23 * size.width, 1)), kPaintGrid); // max grid line

    if (lineObject.dataPoints.length > 1)
      canvas.drawPoints(
          PointMode.polygon,
          List.generate(
            lineObject.dataPoints.length,
            (index) => Offset(index / (lineObject.dataPoints.length - 1) * size.width,
                (-lineObject.dataPoints[index] / lineObject.maxEEValue + 1) * size.height),
          ),
          kPaintEEE);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}



// fid = fopen('2021-05-06_09-04-12.fta','r');
// data = fread(fid,[1 inf],'uint8');
// fclose all
//
// d  = typecast(uint8(data),'single');
// d = reshape(d,4,prod(size(d))/4)';