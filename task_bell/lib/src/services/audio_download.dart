import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AudioDownload {

  /// returns path to the audio file
  static Future<String> downloadAudio(String url) async {

    final yt = YoutubeExplode();

    final videoId = VideoId.parseVideoId(url);
    if (videoId == null) {
      return "";
    }

    // check if the file already exists
    // prepending with yt: to indicate it is a video from yt, and will be stored separately from default ringtones
    // and also for benefit of downloading when syncing between devices

    // final filePath = "${dir.path}/yt:$videoId.mp3";
    final filePath = "/data/user/0/com.example.task_bell/files/yt:$videoId";
    final file = File(filePath);

    

    if (await file.exists()) {
      debugPrint("File already exists, not downloading");
      return filePath;
    }

    // this is the video metadata
    // final video = await yt.videos.get(videoId);

    final manifest = await yt.videos.streams.getManifest(videoId);

    final audio = manifest.audioOnly;

    final stream = yt.videos.streams.get(audio.first);
    
    
    final fileStream = file.openWrite();

    await stream.pipe(fileStream);

    await fileStream.flush();
    await fileStream.close();

    String? path = await FilePicker.platform.saveFile(
      bytes: await file.readAsBytes(),
      fileName: 'yt:$videoId',
      allowedExtensions: ['txt', 'csv'],
    );

    yt.close();
    return path?? "";
  }
}