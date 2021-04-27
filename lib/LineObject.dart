import 'dart:typed_data';

class LineObject {

  double? xAxisSize; // maximal allowed number of logical pixels (dp) along y (s)
  double? yAxisSize; // maximal allowed number of logical pixels (dp) along y (ms-2)
  Float32List rawPoints = Float32List.fromList([]);

  // method to set the maximal possible logical pixel dimensions
  void addAxisSize(double maxWidth, double maxHeight){
    xAxisSize = maxWidth;
    yAxisSize = maxHeight;
  }

  void updateRawPoints(Float32List newRawPoints){
    rawPoints = newRawPoints;
  }
}