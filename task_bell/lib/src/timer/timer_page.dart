import 'package:flutter/material.dart';
import 'package:task_bell/src/alarm_clock/alarm_clock_page.dart';
import '../alarm/timer_folder.dart';
import '../alarm/timer_instance.dart';
import '../settings/settings_view.dart';
import '../alarm/alarm_folder.dart';
import '../alarm/helpers/timer_or_folder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../alarm/alarm_instance.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../settings/settings_global_references.dart';

class TimerPage extends AlarmClockPage {
  const TimerPage({super.key});

  @override
  AlarmClockPageState createState() => TimerPageState();
}

class TimerPageState extends AlarmClockPageState {


  @override
  void initState() {
    super.shouldLoadData = false;
    super.initState();
    loadData();
  }

  @override
  Future<void> loadData() async {

    // get all the child folders, assign to list representing default folder
    topLevelFolders = await tDB.getAllChildFolders(-2);
    topLevelFolders = topLevelFolders.map((alarmFolder) => TimerFolder(
      id: alarmFolder.id,
      parentId: alarmFolder.parentId,
      name: alarmFolder.name, 
      position: alarmFolder.position)).toList();
    topLevelFolders.sort(compareFolders);
    debugPrint('Fetched ${topLevelFolders.length} folders');

    // get all the child timers, assign to list representing default folder
    topLevelAlarms = await tDB.getAllChildAlarms(-2);
    topLevelAlarms = topLevelAlarms.map((alarm) => TimerInstance(
      name: alarm.name,
      parentId: alarm.parentId,
      alarmSettings: alarm.alarmSettings,
      recur: alarm.recur)).toList();
    topLevelAlarms.sort(compareAlarms);
    
    debugPrint('Fetched ${topLevelAlarms.length} timers');
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload to cloud successful')),
        );
      }
    } catch (e) {
      debugPrint('Error uploading to cloud: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading to cloud: $e')),
        );
      }
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download from cloud successful')),
      );
    }
  } catch (e) {
    debugPrint('Error downloading from cloud: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading from cloud: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.timer, style: TextStyle(fontSize: SettingGlobalReferences.appBarFontSize.toDouble())),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          // dialog to create timers/folders and add them to the default folder
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return TimerOrFolderDialog(
                parentId: -2, // Provide the necessary parentId
                folderPos: items.length, // Provide the necessary folderPos
                onCreateTimer: (alarmInstance) async {
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