import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RingtoneService {
  static const MethodChannel _channel = MethodChannel("com.example.task_bell.ringtones");

  Future<List<String>> getRingtones() async {
    try {
      final List<dynamic> ringtones = await _channel.invokeMethod('getRingtones');
      return ringtones.cast<String>();
    } on PlatformException catch (e) {
      debugPrint("unable to grab ringtones: ${e.message}");
      return [];
    }
  }
}