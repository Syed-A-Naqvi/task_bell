

import 'package:alarm/alarm.dart';

class MapConverters {

  static int boolToInt(bool value) {
    return value ? 1 : 0;
  }
  static bool intToBool(int value) {
    return value != 0;
  }

  static Map<String, dynamic> alarmSettingsToMap(AlarmSettings alarmSettings) {
    Map<String, dynamic> map = {
      "id": alarmSettings.id,
      "datetime": alarmSettings.dateTime.millisecondsSinceEpoch,
      "assetAudioPath": alarmSettings.assetAudioPath,
      "loopAudio": boolToInt(alarmSettings.loopAudio), // Convert boolean to int
      "vibrate": boolToInt(alarmSettings.vibrate), // Convert boolean to int
      "volume": alarmSettings.volume,
      "volumeEnforced": boolToInt(alarmSettings.volumeEnforced), // Convert boolean to int
      "fadeDuration": alarmSettings.fadeDuration,
      "warningNotificationOnKill": boolToInt(alarmSettings.warningNotificationOnKill), // Convert boolean to int
      "androidFullScreenIntent": boolToInt(alarmSettings.androidFullScreenIntent), // Convert boolean to int
    };
  
    map.addAll(notificationSettingsToMap(alarmSettings.notificationSettings));
  
    return map;
  }

  static AlarmSettings alarmSettingsFromMap(Map<String, dynamic> map) {
    NotificationSettings ns = notificationSettingsFromMap(map);
    return AlarmSettings(
      id: map["id"], 
      dateTime: DateTime.fromMillisecondsSinceEpoch(map["datetime"]), 
      assetAudioPath: map["assetAudioPath"], 
      notificationSettings: ns,
      loopAudio: intToBool(map["loopAudio"]), // Convert int to boolean
      vibrate: intToBool(map["vibrate"]), // Convert int to boolean
      volumeEnforced: intToBool(map["volumeEnforced"]), // Convert int to boolean
      fadeDuration: map["fadeDuration"],
      warningNotificationOnKill: intToBool(map["warningNotificationOnKill"]), // Convert int to boolean
      androidFullScreenIntent: intToBool(map["androidFullScreenIntent"]) // Convert int to boolean
    );
  }

  static Map<String, dynamic> notificationSettingsToMap(NotificationSettings notificationSettings) {
    return {
      "title": notificationSettings.title,
      "body": notificationSettings.body,
      "stopButton": notificationSettings.stopButton,
      "icon": notificationSettings.icon,
    };
  }

  static NotificationSettings notificationSettingsFromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      title: map["title"], 
      body: map["body"],
      stopButton: map["stopButton"],
      icon: map["icon"],
    );
  }

}