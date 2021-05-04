import 'package:flutter/material.dart';

const int kSampRate = 50; // Hz - approximate sampling rate of acceleration data
const double kVerticalAxisSpace = 0.4; // x100% of the screen to be occupied by the axis when in portrait layout
const int kAccBufferSize = kSampRate*20*2; // maximal number of samples to be stored for showing (*2 to account for both time and acceleration samples)
const List<int> kSamplesToPlot = [1*kSampRate,5*kSampRate,10*kSampRate,20*kSampRate]; // Approximate time (s) to scale plot with acceleration values
const List<int> kAccelFullScale = [1, 2, 4, 8]; // full scale of the y axis for plotting acceleration values (g unit)
const int kMinBodyMass = 30; // minimal accepted body mass value
const int kMaxBodyMass = 100; // maximal accepted body mass value
const Color kThemeColor = Colors.grey;


final kPaintGrid = Paint()
  ..color = Colors.white
  ..strokeWidth = 1
  ..strokeCap = StrokeCap.butt;

final kPaintAccelX = Paint()
  ..color = Colors.purpleAccent
  ..strokeWidth = 4
  ..strokeCap = StrokeCap.round;

final kPaintAccelY = Paint()
  ..color = Colors.yellowAccent
  ..strokeWidth = 4
  ..strokeCap = StrokeCap.round;

final kPaintAccelZ = Paint()
  ..color = Colors.lightBlueAccent
  ..strokeWidth = 4
  ..strokeCap = StrokeCap.round;

final kPaintEEE = Paint()
  ..color = Colors.white
  ..strokeWidth = 2
  ..strokeCap = StrokeCap.round;