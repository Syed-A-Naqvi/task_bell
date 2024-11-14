// create_alarm_dialog.dart
import 'package:flutter/material.dart';
import '../alarm_folder.dart';


class FolderDialog extends StatefulWidget {
 
  final String parentId;
  final ValueChanged<AlarmFolder> onCreate;
  final int position;

  const FolderDialog({
    required this.onCreate,
    this.position = 0,
    this.parentId = '-1',
    super.key,
  });

  @override
  FolderDialogState createState() => FolderDialogState();
}

class FolderDialogState extends State<FolderDialog> {
 final TextEditingController nameController = TextEditingController();

  void _createFolder() {
    if (nameController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Invalid name"),
        ),
      );
      return;
    }

    AlarmFolder folder = AlarmFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentId: widget.parentId,
      name: nameController.text,
      position: widget.position, // Adjust position as needed
    );

    widget.onCreate(folder);
    // Optionally close the dialog if needed
    // Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Folder'),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Enter Folder Name',
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _createFolder,
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}
