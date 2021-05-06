import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WriteDataToDevice{

  late Directory localDirectory;
  IOSink? ioSink;

  void setFileForDataStorage(Directory? directory){
    if(directory!=null){
      // Creating the directory where files will be saved
      localDirectory = directory;
    }
  }

  void startAcquisition(){
    String now = DateTime.now().toIso8601String();
    now = now.substring(0,now.lastIndexOf('.')).replaceAll(':','-').replaceAll('T', '_'); // formatting string to name current file
    ioSink = File(localDirectory.path+Platform.pathSeparator+now+".fta").openWrite(mode: FileMode.write);
  }

  void stopAcquisition(){
    ioSink?.close().then((value) {
      print(value);
      ioSink = null;
    });
  }
}