import 'dart:ui';
import 'package:http/http.dart' as http;

// This class must be populated with properties and methods necessary for estimating energy expenditure from acceleration data

class LineEnExEsObject {

  int bodyMass = 70;
  int maxEEValue = 50; // set initially at 50 kcal (this is to be updated automatically according to the cumulative EEE)
  bool estimateEE = false; // determines whether energy expenditure should be estimated from acceleration data
  bool sendData = false; // determines whether to send data to ThingSpeak or not
  List<double> dataPoints = [0]; // List of data points containing energy expenditure estimates
  String? apiKeyWrite; // string with the key for writing EE values to ThingSpeak

  void sendDataToThingSpeak(){//https://api.thingspeak.com/update.json?api_key=<write_api_key>&field1=123
    http.get(Uri.parse("https://api.thingspeak.com/update.json?api_key=$apiKeyWrite&field1=${dataPoints.last}"));//.then((value)=>
         //print(value.statusCode));
  }

}