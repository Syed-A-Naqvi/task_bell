import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';

class AudioDownload {

  /// returns path to the audio file
  static Future<String> downloadAudio(String url) async {

    final yt = YoutubeExplode();

    final videoId = VideoId.parseVideoId(url);
    if (videoId == null) {
      return "";
    }

    // check if the file already exists
    final Directory dir = await getApplicationDocumentsDirectory();
    // prepending with yt: to indicate it is a video from yt, and will be stored separately from default ringtones
    // and also for benefit of downloading when syncing between devices
    final filePath = "${dir.path}/yt:$videoId";
    final file = File(filePath);

    if (await file.exists()) {
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

    yt.close();
    return filePath;
  }
}