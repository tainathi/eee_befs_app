import 'dart:async';

import 'package:flutter/material.dart';
import 'LineAccelObject.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:eee_befs_app/constants.dart';

// widget used for setters of axes properties
Widget ScrollItemSelection(LineAccelObject lineObject, List<int> items, int id){
  // id indicates whether this is for setting x or y axis size
  return Expanded(
    child: CupertinoPicker(
      selectionOverlay: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.tealAccent.withOpacity(0.3),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      children: List.generate(
          kSamplesToPlot.length,
          (index) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "${id == 1 ? String.fromCharCode(0x00B1) : ""} ${items[index]}",
                  style: TextStyle(color: Colors.white),
                ),
              )),
      itemExtent: 40,
      onSelectedItemChanged: (int value) {
        if (id == 0)
          lineObject.updateNumberOfSamplesToPlot(kSamplesToPlot[value]);
        else
          lineObject.gain = kAccelFullScale[value].toDouble();
      },
    ),
  );
}


// Widget used for visualization of acceleration values
Widget AccelValuesAndLines(LineAccelObject lineObject, Color buttonColor,double gValue,int axisId,StreamSubscription? accelSubscription, Function setState) {

  return Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: MaterialButton(
        padding: EdgeInsets.all(0),
        height: 40,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: (){
          lineObject.showXYZ[axisId] = !lineObject.showXYZ[axisId];
          if(accelSubscription==null)
            setState((){});
        },
        color: buttonColor.withOpacity(lineObject.showXYZ[axisId]?1:0.4),
        child: FittedBox(
            fit: BoxFit.fill,
            child: Text("${axisId==0?"X":axisId==1?"Y":"Z"}: ${(gValue).toStringAsFixed(1)}",
              style: TextStyle(color: lineObject.showXYZ[axisId]?Colors.black:Colors.white),
            ),
        ),


      ),
    ),
  );
}