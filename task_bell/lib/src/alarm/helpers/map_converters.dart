

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';

class MapConverters {

  static Map<String, dynamic> alarmSettingsToMap(AlarmSettings alarmSettings) {
    Map<String, dynamic> map = {
      "id": alarmSettings.id,
      "datetime": alarmSettings.dateTime.millisecondsSinceEpoch,
      "assetAudioPath": alarmSettings.assetAudioPath,
      "loopAudio": alarmSettings.loopAudio,
      "vibrate": alarmSettings.vibrate,
      "volume": alarmSettings.volume,
      "volumeEnforced": alarmSettings.volumeEnforced,
      "fadeDuration": alarmSettings.fadeDuration,
      "warningNotificationOnKill": alarmSettings.warningNotificationOnKill,
      "androidFullScreenIntent": alarmSettings.androidFullScreenIntent, 
    };

    map.addAll(notificationSettingsToMap(alarmSettings.notificationSettings));

    return map;
  }

  static AlarmSettings alarmSettingsFromMap(Map<String, dynamic> map) {
    NotificationSettings ns = notificationSettingsFromMap(map);
    return AlarmSettings(
      id: map["id"], 
      dateTime: map["dateTime"], 
      assetAudioPath: map["assetAudioPath"], 
      notificationSettings: ns,
      loopAudio: map["loopAudio"],
      vibrate: map["vibrate"],
      volumeEnforced: map["volumeEnforced"],
      fadeDuration: map["fadeDuration"],
      warningNotificationOnKill: map["warningNotificationOnKill"],
      androidFullScreenIntent: map["androidFullScreenIntent"]
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