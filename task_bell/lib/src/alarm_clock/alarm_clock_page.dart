import 'package:flutter/material.dart';
import 'package:task_bell/src/services/audio_download.dart';
import '../settings/settings_view.dart';
import '../alarm/alarm_folder.dart';
import '../storage/task_bell_database.dart';
import '../alarm/alarm_instance.dart';
import '../alarm/helpers/alarm_or_folder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AlarmClockPage extends StatefulWidget {
  const AlarmClockPage({super.key});

  @override
  AlarmClockPageState createState() => AlarmClockPageState();
}

class AlarmClockPageState extends State<AlarmClockPage> {

  // database instance
  TaskBellDatabase tDB = TaskBellDatabase();
  // items to be displayed on the main page
  List<Widget> items = [];

  // maintains list of elements to display
  List<dynamic> topLevelFolders = [];
  List<dynamic> topLevelAlarms = [];
  // sort folders and items in a custom way
  int compareFolders(dynamic a, dynamic b) {
    return (a as AlarmFolder).position.compareTo((b as AlarmFolder).position);
  }
  int compareAlarms(dynamic a, dynamic b) {
    return (a as AlarmInstance).alarmSettings.dateTime.millisecondsSinceEpoch
    .compareTo((b as AlarmInstance).alarmSettings.dateTime.millisecondsSinceEpoch);
  }

  bool shouldLoadData = true;

  @override
  void initState() {
    super.initState();
    if (shouldLoadData) {
      loadData();
    }
  }

  Future<void> loadData() async {
    topLevelFolders = await tDB.getAllChildFolders(-1);
    topLevelFolders.sort(compareFolders);
    debugPrint('Fetched ${topLevelFolders.length} folders');
    topLevelAlarms = await tDB.getAllChildAlarms(-1);
    topLevelAlarms.sort(compareAlarms);
    debugPrint('Fetched ${topLevelAlarms.length} alarms');
    setState(() {
      items = [...topLevelFolders, ...topLevelAlarms];
    });
  }

  Future<void> _uploadToCloud() async {
    try {
      // Fetch all folders and alarms from the local database
      List<AlarmFolder> allFolders = await tDB.getAllFolders();
      List<AlarmInstance> allAlarms = await tDB.getAllAlarms();

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      WriteBatch batch = firestore.batch();

      // Upload folders
      CollectionReference foldersCollection = firestore.collection('folders');
      for (AlarmFolder folder in allFolders) {
        Map<String, dynamic> folderMap = folder.toMap();
        DocumentReference docRef = foldersCollection.doc(folder.id.toString());
        batch.set(docRef, folderMap);
      }

      // Upload alarms
      CollectionReference alarmsCollection = firestore.collection('alarms');
      for (AlarmInstance alarm in allAlarms) {
        Map<String, dynamic> alarmMap = alarm.toMap();
        DocumentReference docRef = alarmsCollection.doc(alarm.alarmSettings.id.toString());
        batch.set(docRef, alarmMap);
      }

      // Commit batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload to cloud successful')),
      );
    } catch (e) {
      debugPrint('Error uploading to cloud: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading to cloud: $e')),
      );
    }
  }

  Future<void> _downloadFromCloud() async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch folders from Firestore
    QuerySnapshot foldersSnapshot = await firestore.collection('folders').get();
    List<AlarmFolder> folders = foldersSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return AlarmFolder.fromMap(data);
    }).toList();

    // Fetch alarms from Firestore
    QuerySnapshot alarmsSnapshot = await firestore.collection('alarms').get();
    List<AlarmInstance> alarms = alarmsSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return AlarmInstance.fromMap(data);
    }).toList();

    // Insert folders into local database
    for (AlarmFolder folder in folders) {
      await tDB.insertFolder(folder);
    }

    // Insert alarms into local database
    for (AlarmInstance alarm in alarms) {
      await tDB.insertAlarm(alarm);
    }

    // Reload data to update UI
    loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download from cloud successful')),
    );
  } catch (e) {
    debugPrint('Error downloading from cloud: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error downloading from cloud: $e')),
    );
  }
}

  void downloadAudio() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController urlController = TextEditingController();
        String? selectedTitle; // Track the selected title
        Map<String, String> videoOptions = {
          'America - A Horse With No Name': 'https://www.youtube.com/watch?v=na47wMFfQCo',
          'David Bowie - Starman': 'https://www.youtube.com/watch?v=tRcPA7Fzebw',
          'Mongolian Throat Music': 'https://www.youtube.com/watch?v=p_5yt5IX38I',
        }; // Map of titles to URLs

        return AlertDialog(
          title: const Text("Download audio from YouTube"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Enter YouTube Video URL',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: selectedTitle,
                hint: const Text("Select a YouTube video"),
                isExpanded: true,
                items: videoOptions.keys.map((title) {
                  return DropdownMenuItem<String>(
                    value: title,
                    child: Text(title),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedTitle = value;
                  urlController.text = videoOptions[selectedTitle]!; // Populate the text field with the URL
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                child: const Text("Download"),
                onPressed: () async {
                  String responsePath = await AudioDownload.downloadAudio(urlController.text);
                  if (responsePath.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(title: Text("Failed to download"));
                      },
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Alarm Clock'),
        title: Text(AppLocalizations.of(context)!.alarmClock),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _uploadToCloud,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: _downloadFromCloud,
          ),
          IconButton(
            icon: const Icon(Icons.audiotrack),
            onPressed: downloadAudio,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: ListView(
        children: items,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlarmOrFolderDialog(
                parentId: -1, // Provide the necessary parentId
                folderPos: items.length, // Provide the necessary folderPos
                // initialTime: TimeOfDay.now(),
                onCreateAlarm: (alarmInstance) async {
                  await tDB.insertAlarm(alarmInstance);
                  topLevelAlarms.add(alarmInstance);
                  topLevelAlarms.sort(compareAlarms);
                  items = [...topLevelFolders, ...topLevelAlarms];
                  setState(() {});
                },
                onCreateFolder: (folder) async {
                  await tDB.insertFolder(folder);
                  topLevelFolders.add(folder);
                  topLevelFolders.sort(compareFolders);
                  items = [...topLevelFolders, ...topLevelAlarms];
                  setState(() {});
                },
              );
            },
          );
        },
        foregroundColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        child: const Icon(Icons.add),
      ),
    );
  }
}
