import 'package:flutter/material.dart';
import 'package:music_testapp/queue.dart';

// NOTE: PLAYLIST PAGE (temporal?)
class Playlists extends StatefulWidget {
  const Playlists({super.key});

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  late List<String> playlists = [];

  void getPlaylists() async {
    List<String> storagePlaylists = await storage.getPlaylists();
    setState(() {
      playlists = storagePlaylists;
    });
  }

  @override
  void initState() {
    getPlaylists();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: ListView.builder(
          itemCount: playlists.length,
          itemBuilder: ((context, index) {
            String playlistName = playlists[index].replaceAll('queue_','').replaceAll('.txt', '');

            return ListTile(
                contentPadding: EdgeInsets.symmetric(
                    vertical: screenWidth / 100, horizontal: screenWidth / 25),
                leading: Image.asset(
                  'assets/folder.png',
                  color: Theme.of(context).colorScheme.onSurface, // foreground
                  height: screenWidth / 10,
                  fit: BoxFit.contain,
                ),
                title: Text(
                  playlistName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.normal,
                      fontSize: screenWidth / 30),
                ),
                onTap: () async {
                  setQueue(playlistName);
                });
          })),
    );
  }
}
