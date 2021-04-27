import 'dart:typed_data';
import 'dart:ui';
import 'package:eee_befs_app/constants.dart';
import 'dart:math';


class LineObject {

  double xAxisSize = 0; // maximal allowed number of logical pixels (dp) along x (s)
  double yAxisSize = 0; // maximal allowed number of logical pixels (dp) along y (s)
  double gravityAcc = 9.81; // used to store gravity acceleration measured in the first second of data retrieval
  int secondsToPlot = 10; // determines the number of samples to show
  Float32List xRawPoints = Float32List(2);  // initialize a list of Float 32 elements with a single element
  Float32List zRawPoints = Float32List(2);  // initialize a list of Float 32 elements with a single element
  List<List<double>> tempData = List.generate(3, (index) => List.empty(growable: true));
  List<List<double>> xyzData = List.generate(3, (index) => List.filled(kSampRate*2*10,0)); // List with the double of elements in each sublist wrt the previous list

  // method to set the maximal possible logical pixel dimensions
  void initializeLineObject(double maxWidth, double maxHeight){
    xAxisSize = maxWidth; // Axis size in x direction will be dictated by the width of the target device
    yAxisSize = maxHeight; // Axis size in y direction will be dictated by the height of the target device
  }

  void updateRawPoints(List<List<double>> newRawPoints) {

    // print(tempData.first.length);
    if (tempData.first.length>=kSampRate*secondsToPlot){ // remove samples if the requested window is shorter than that currently shown for
      tempData[0].removeRange(0,kSampRate); // x acceleration data
      tempData[1].removeRange(0,kSampRate); // y acceleration data
      tempData[2].removeRange(0,kSampRate); // z acceleration data
    }
    tempData[0].addAll(newRawPoints[0]); // concatenating new x accel data at the beginning of the list
    tempData[1].addAll(newRawPoints[1]); // concatenating new y accel data at the beginning of the list
    tempData[2].addAll(newRawPoints[2]); // concatenating new z accel data at the beginning of the list
    // print(tempData.first.length);


    for (int i = 0; i < tempData.length; i++) {
      // creating list with samples and x acceleration data
      xyzData[0][i * 2] = i * xAxisSize / (kSampRate*secondsToPlot-1);
      xyzData[0][i * 2 + 1] = tempData[0][i] * 0.5 * yAxisSize / gravityAcc + yAxisSize/2;
      // creating list with samples and z acceleration data
      xyzData[2][i * 2] = i * xAxisSize / (kSampRate*secondsToPlot-1);
      xyzData[2][i * 2 + 1] = tempData[2][i] * 0.5 * yAxisSize / gravityAcc + yAxisSize/2;
    }
    xRawPoints = Float32List.fromList(xyzData[0]);
    zRawPoints = Float32List.fromList(xyzData[2]);
  }

  // method used to estimate gravity acceleration from the first second of data (Nilsen 1998 Clin Biomech 13:320-327)
  void updateGravityAccValue(List<List<double>> xyzG){
    List<double> g = [0,0,0]; // list to store the sum of acc values in the three axes
    for (int i = 0; i < kSampRate; i++) {
      g[0] += xyzG[0][i]/kSampRate;
      g[1] += xyzG[1][i]/kSampRate;
      g[2] += xyzG[2][i]/kSampRate;
    }
    gravityAcc = sqrt(g.reduce((value, element) => value*value+element*element)); // gravtity acceleration value
    print(gravityAcc);
  }
}