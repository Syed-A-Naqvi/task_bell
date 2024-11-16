import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AudioDownload {

  /// returns path to the audio file
  static Future<String> downloadAudio(String url) async {

    final yt = YoutubeExplode();

    final videoId = VideoId.parseVideoId(url);
    if (videoId == null) {
      return "";
    }

    final filePath = "/data/user/0/com.example.task_bell/files/yt:$videoId";
    final file = File(filePath);

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

    file.delete();

    yt.close();
    return path?? "";
  }
}