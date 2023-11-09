import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class QueueStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  String _documentsPath = "ERROR";

  /*Future<File> get _localFile async {
    final path = await _localPath;
    final localFile = File('$path/queue.txt');
    
    if (await localFile.exists() == false) return localFile.create();
    return localFile;
  }*/

  void initialise() async
  {
    _documentsPath = await _localPath;
  }

  Future<List<String>> getPlaylists() async {
    final path = await _localPath;
    
    final queueFolder = Directory('$path/playlists');
    if (await queueFolder.exists() == false) queueFolder.create();
    
    List<String> playlists = (await queueFolder.list().toList()).map(
      (file) => basename(file.path)
      ).toList();

    return playlists;
  }

  File getQueueFile({String playlist = "default", bool autoCreate = false}) {    
    final queueFolder = Directory('$_documentsPath/playlists');
    if (queueFolder.existsSync()) queueFolder.create();
    
    File localFile = File('$_documentsPath/playlists/queue_$playlist.txt');
    
    if (localFile.existsSync() == false && autoCreate == true) 
    {
      localFile.createSync();
      localFile = File('$_documentsPath/playlists/queue_$playlist.txt');
    }

    return localFile;
  }

  Future<bool> removeQueueFile(String playlist) async
  {
    _documentsPath = await _localPath;
    final queueFolder = Directory('$_documentsPath/playlists');
    if (queueFolder.existsSync()) queueFolder.create();
    
    File localFile = File('$_documentsPath/playlists/queue_$playlist.txt');
    if (await localFile.exists()) {
      localFile.delete();
      return true;
    }

    return !(await localFile.exists());
  }

  Future<List<String>> read({String playlist = "default"}) async {
    try {
      _documentsPath = await _localPath;
      final queueFile = getQueueFile(playlist: playlist, autoCreate: true);

      // Read the file
      final contents = await queueFile.readAsString();
      List<String> paths = contents.split("\n<path>");

      // filter paths
      paths = paths.where((path) => (path.replaceAll(" ","") != "" && path.contains(".txt") == false)).toList();
      // decode paths
      paths = paths.map((path) => Uri.decodeComponent(path)).toList(); 

      return paths; // Return all files
    } catch (e) {
      return []; // If encountering an error, return an empty list
    }
  }

  bool checkFile(FileSystemEntity fileToCheck, {String playlist = "default"})
  {
    final queueFile = getQueueFile(playlist: playlist, autoCreate: true);
    final contents = queueFile.readAsStringSync();

    return contents.contains(Uri.encodeComponent(fileToCheck.path));
  }

  Future<File> writeFile(FileSystemEntity newFile, {String playlist = "default"}) async {
    _documentsPath = await _localPath;
    final queueFile = getQueueFile(playlist: playlist, autoCreate: true);

    String stringQueue = await queueFile.readAsString();
    String resultString = '$stringQueue\n<path>${Uri.encodeComponent(newFile.path)}';
    
    // Write the file
    return queueFile.writeAsString(resultString);
  }

  Future<File> removeFile(FileSystemEntity newFile, {String playlist = "default"}) async {
    _documentsPath = await _localPath;
    final queueFile = getQueueFile(playlist: playlist, autoCreate: true);

    String stringQueue = await queueFile.readAsString();
    String resultString = stringQueue.replaceAll('\n<path>${Uri.encodeComponent(newFile.path)}', '');

    // Write the file
    return queueFile.writeAsString(resultString);
  }
}