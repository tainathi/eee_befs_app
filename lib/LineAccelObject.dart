import 'dart:typed_data';
import 'package:eee_befs_app/constants.dart';
import 'dart:math';

class LineAccelObject {

  double xAxisSize; // maximal allowed number of logical pixels (dp) along x (s)
  double yAxisSize; // maximal allowed number of logical pixels (dp) along y (s)
  double gain = 1; // factor used to scale acceleration data (full scale)
  double gravityAcc = 9.81; // used to store gravity acceleration measured in the first second of data retrieval
  int samplesToPlot; // determines the number of samples to show
  bool running = false; // status of the object

  late Float32List xRawPoints;  // initialize a list of Float 32 elements with a single element X axis
  late Float32List yRawPoints;  // initialize a list of Float 32 elements with a single element Y axis
  late Float32List zRawPoints;  // initialize a list of Float 32 elements with a single element Z axis
  late Float32x4List tempData;
  List<bool> showXYZ = [false, false, false]; // determines whether to show each of the three axes
  List<List<double>> xyzData = List.generate(3, (index) => List.filled(kSampRate*2*1,0)); // List with the double of elements in each sublist wrt the previous list

  LineAccelObject({required this.samplesToPlot,required this.xAxisSize, required this.yAxisSize}){
    xRawPoints = Float32List(samplesToPlot*2);
    yRawPoints = Float32List(samplesToPlot*2);
    zRawPoints = Float32List(samplesToPlot*2);
    tempData = Float32x4List(samplesToPlot);

    // initialize the x and y values for the acceleration data to plot
    for(int i=0; i<samplesToPlot; i++){
      xRawPoints[i*2] = i * xAxisSize / (samplesToPlot-1);
      yRawPoints[i*2] = i * xAxisSize / (samplesToPlot-1);
      zRawPoints[i*2] = i * xAxisSize / (samplesToPlot-1);
      xRawPoints[i*2+1] = yAxisSize / 2;
      yRawPoints[i*2+1] = yAxisSize / 2;
      zRawPoints[i*2+1] = yAxisSize / 2;
    }
  }

  // Todo: update this method to update axes size rather than initialize the object
  // method to set the maximal possible logical pixel dimensions
  void initializeLineObject(double maxWidth, double maxHeight){
    xAxisSize = maxWidth; // Axis size in x direction will be dictated by the width of the target device
    yAxisSize = maxHeight; // Axis size in y direction will be dictated by the height of the target device
  }

  void updateRawPoints(Float32x4List newRawPoints) {

    if (tempData.length>kSampRate)
      // the next command shifts all blocks of kSampRate data to the beginning
      tempData.setRange(0, tempData.length-kSampRate, tempData.getRange(kSampRate, tempData.length));

    // setting the new batch of data to the last  kSampRate samples
    tempData.setRange(tempData.length-kSampRate, tempData.length, newRawPoints);

    for (int i = 0; i < tempData.length; i++) {
      xRawPoints[i*2+1] = (tempData[i].x/(gain*gravityAcc) + 1) * yAxisSize/2;
      yRawPoints[i*2+1] = (tempData[i].y/(gain*gravityAcc) + 1) * yAxisSize/2;
      zRawPoints[i*2+1] = (tempData[i].z/(gain*gravityAcc) + 1) * yAxisSize/2;
    }
  }

  // method used to update the number of samples to show
  void updateNumberOfSamplesToPlot(int newNumberOfSamples){
    xRawPoints = Float32List(newNumberOfSamples*2);
    yRawPoints = Float32List(newNumberOfSamples*2);
    zRawPoints = Float32List(newNumberOfSamples*2);
    tempData = Float32x4List(newNumberOfSamples);

    // initialize the x and y values for the accelration data to plot
    for(int i=0; i<newNumberOfSamples; i++){
      xRawPoints[i*2] = i * xAxisSize / (newNumberOfSamples-1);
      yRawPoints[i*2] = i * xAxisSize / (newNumberOfSamples-1);
      zRawPoints[i*2] = i * xAxisSize / (newNumberOfSamples-1);
      xRawPoints[i*2+1] = yAxisSize / 2;
      yRawPoints[i*2+1] = yAxisSize / 2;
      zRawPoints[i*2+1] = yAxisSize / 2;
    }
  }


  // method used to estimate gravity acceleration from the first second of data (Nilsen 1998 Clin Biomech 13:320-327)
  void updateGravityAccValue(Float32x4List xyzG){
    List<double> g = [0,0,0]; // list to store the sum of acc values in the three axes
    for (int i = 0; i < xyzG.length; i++) {
      g[0] += xyzG[i].x/xyzG.length;
      g[1] += xyzG[i].y/xyzG.length;
      g[2] += xyzG[i].z/xyzG.length;
    }
    gravityAcc = sqrt(g.reduce((value, element) => value*value+element*element)); // gravtity acceleration value
    print(gravityAcc);
  }
}