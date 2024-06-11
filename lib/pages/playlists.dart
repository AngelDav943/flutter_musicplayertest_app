import 'package:flutter/material.dart';
import 'package:music_testapp/pages/queue.dart';

import '../widgets/inputs.dart';
import '../widgets/bottom_bar.dart' as bottom_bar;

import '../widgets/queue_dialog.dart' as queue_dialog;
import 'queue.dart' as queue;

import '../main.dart' as main;

// NOTE: PLAYLIST PAGE (temporal?)
class Playlists extends StatefulWidget {
  const Playlists({super.key});

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  /*late List<String> playlists = [];

  void getPlaylists() async {
    List<String> storagePlaylists = await storage.getPlaylists();
    setState(() {
      playlists = storagePlaylists;
    });
  }*/

  @override
  void initState() {
    //getPlaylists();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        toolbarOpacity: 0,
        toolbarHeight: screenWidth / 6,
        leadingWidth: screenWidth / 4,
        leading: ImageButton(
          image: "back.png",
          color: Theme.of(context).colorScheme.onBackground,
          pressUp: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      floatingActionButton: GestureDetector(
        child: Image.asset(
          "assets/addqueue.png",
          color: Theme.of(context).colorScheme.onBackground,
        ),
        onTap: () async {
          await showDialog(
              context: context,
              builder: (dialogContext) =>
                  queue_dialog.createPlaylistDialog(dialogContext));
          //getPlaylists();
          await updatePlaylists();
          setState(() {});
        },
      ),
      body: Center(
        child: ListView.builder(
            itemCount: playlists.length,
            itemBuilder: ((context, index) {
              String playlistName = playlists[index];
              int internalIndex = queue.internalPlaylists.indexOf(playlistName);

              return Card(
                color: main.randomColors[internalIndex % main.randomColors.length],
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                      vertical: screenWidth / 100,
                      horizontal: screenWidth / 25),
                  leading: Image.asset(
                    'assets/folder.png',
                    color:
                        Theme.of(context).colorScheme.onSurface, // foreground
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
                  trailing: ImageButton(
                    image: 'delete.png',
                    color:
                        Theme.of(context).colorScheme.onSurface, // foreground
                    width: screenWidth / 10,
                    pressUp: () async {
                      await showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              content: Text(
                                  "Are you sure to delete playlist '$playlistName'"),
                              actions: [
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text("No")),
                                FilledButton(
                                    onPressed: () {
                                      queue.storage
                                          .removeQueueFile(playlistName);
                                      Navigator.pop(dialogContext, false);
                                    },
                                    child: const Text("Yes")),
                              ],
                            );
                          });
                      await queue.updatePlaylists();
                      setState(() {});
                    },
                  ),
                  onTap: () async {
                    bool success = await setQueue(playlistName);
                    if (success) {
                      // ignore: use_build_context_synchronously
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const queue.Queue();
                      }));
                      setState(() {});
                    }
                  },
                ),
              );
            })),
      ),
      bottomNavigationBar: const bottom_bar.BottomNav(),
    );
  }
}
