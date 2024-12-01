// create_alarm_dialog.dart
import 'package:flutter/material.dart';
import '../alarm_folder.dart';


class FolderDialog extends StatefulWidget {
 
  final int parentId;
  final ValueChanged<AlarmFolder> onCreate;
  final int position;
  final String namePrefill;

  const FolderDialog({
    required this.onCreate,
    required this.parentId,
    this.position = 0,
    this.namePrefill = "",
    super.key,
  });

  @override
  FolderDialogState createState() => FolderDialogState();
}

class FolderDialogState extends State<FolderDialog> {
 late final TextEditingController nameController = TextEditingController(text: widget.namePrefill);

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
      id: DateTime.now().millisecondsSinceEpoch,
      parentId: widget.parentId,
      name: nameController.text,
      position: widget.position, // Adjust position as needed
    );

    widget.onCreate(folder);

  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              child: widget.namePrefill.isEmpty ? const Text('Create') : const Text("Update"), 
            ),
          ),
        ],
      ),
    );
  }
}
