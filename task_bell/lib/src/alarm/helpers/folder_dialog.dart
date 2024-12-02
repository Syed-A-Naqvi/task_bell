// create_alarm_dialog.dart
import 'package:flutter/material.dart';
import 'package:task_bell/src/settings/settings_global_references.dart';
import '../alarm_folder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.invalidName, style: TextStyle(fontSize: SettingGlobalReferences.defaultFontSize.toDouble())),
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
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.enterFolderName,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _createFolder,
              child: widget.namePrefill.isEmpty ? 
                Text(AppLocalizations.of(context)!.create, style: TextStyle(fontSize: SettingGlobalReferences.defaultFontSize.toDouble())) : 
                Text(AppLocalizations.of(context)!.update, style: TextStyle(fontSize: SettingGlobalReferences.defaultFontSize.toDouble())),
            ),
          ),
        ],
      ),
    );
  }
}
