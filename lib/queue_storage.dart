import 'dart:io';
import 'package:path_provider/path_provider.dart';

class QueueStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    final localFile = File('$path/queue.txt');
    
    if (await localFile.exists() == false) return localFile.create();
    return localFile;
  }

  Future<List<String>> read() async {
    try {
      final queueFile = await _localFile;

      // Read the file
      final contents = await queueFile.readAsString();
      List<String> paths = contents.split("\n\n");
      /*paths.map((path) => {
        if (path.replaceAll(" ","") != "" && path.contains(".txt") == false) return path;
      })*/

      paths = paths.where((path) => (path.replaceAll(" ","") != "" && path.contains(".txt") == false)).toList();

      return paths; // Return all files
    } catch (e) {
      return []; // If encountering an error, return an empty list
    }
  }

  Future<File> writeFile(FileSystemEntity newFile) async {
    final queueFile = await _localFile;
    String stringQueue = await queueFile.readAsString();
    String resultString = '$stringQueue${newFile.path}\n\n';
    
    // Write the file
    return queueFile.writeAsString(resultString);
  }

  Future<File> removeFile(FileSystemEntity newFile) async {
    final queueFile = await _localFile;
    String stringQueue = await queueFile.readAsString();
    String resultString = stringQueue.replaceAll('${newFile.path}\n\n', '');

    // Write the file
    return queueFile.writeAsString(resultString);
  }
}