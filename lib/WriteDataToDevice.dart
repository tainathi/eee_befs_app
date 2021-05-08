import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class WriteDataToDevice {
  late Directory localDirectory;
  IOSink? ioSink;

  void setFileForDataStorage() async {
    Directory? tempDirectory;
    if (Platform.isAndroid) {
      // tempDirectory = await getExternalStorageDirectory();
      // if (tempDirectory != null) localDirectory=tempDirectory;
       if (await _requestPermission(Permission.storage)) {
        tempDirectory = await getExternalStorageDirectory();
        if (tempDirectory != null) {
          print(tempDirectory.path);
          localDirectory = tempDirectory;
          String newPath = "";
          List<String> paths = localDirectory.path.split("/");
          for (String folder in paths) {
            if (folder.isNotEmpty) if (folder != "Android") {
              newPath += "/" + folder;
            } else {
              break;
            }
          }
          newPath = newPath + "/EEEBefs";
          localDirectory = Directory(newPath);

          if (!await localDirectory.exists()) {
            print("before");
            await localDirectory.create(recursive: true);
            print("after");
          }

        }
      }
    } else {
      // this is an iOS platform
      localDirectory = await getApplicationDocumentsDirectory();
    }

    print("path: ${localDirectory.path}");
    // if (directory != null) {
    //   // Creating the directory where files will be saved
    //   localDirectory = directory;
    // }
  }

  void startAcquisition() async {
    String now = DateTime.now().toIso8601String();
    now = now
        .substring(0, now.lastIndexOf('.'))
        .replaceAll(':', '-')
        .replaceAll('T', '_'); // formatting string to name current file
    ioSink = File(localDirectory.path + Platform.pathSeparator + now + ".fta")
        .openWrite(mode: FileMode.write);
  }

  void stopAcquisition() {
    ioSink?.close().then((value) {
      print(value);
      ioSink = null;
    });
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }
}
