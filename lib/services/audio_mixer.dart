import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/bgm_track.dart';

/// Mixes background music into a speech audio file using FFmpeg.
/// Supports any BGM format (MP3, WAV, AAC, etc.).
/// Output format is determined by [outputFile]'s extension.
class AudioMixer {
  static Future<File> mixBgmIntoSpeech({
    required File speechFile,
    required BgmTrack bgmTrack,
    required double bgmVolume,
    required BgmPlayMode playMode,
    required File outputFile,
  }) async {
    if (!speechFile.existsSync() || speechFile.lengthSync() < 44) {
      return speechFile;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();

      // Resolve BGM to a real file path (extract from asset bundle if built-in)
      File bgmFile;
      if (bgmTrack.sourceType == BgmSourceType.asset || bgmTrack.isBuiltIn) {
        final ByteData data = await rootBundle.load(bgmTrack.path);
        final Uint8List bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        // Preserve original extension so FFmpeg picks correct demuxer
        final String ext = bgmTrack.path.split('.').last;
        bgmFile = File(
            '${tempDir.path}${Platform.pathSeparator}bgm_${bgmTrack.id}.$ext');
        await bgmFile.writeAsBytes(bytes, flush: true);
      } else {
        bgmFile = File(bgmTrack.path);
      }

      if (!bgmFile.existsSync() || bgmFile.lengthSync() == 0) {
        debugPrint('AudioMixer: BGM file not found – exporting speech only');
        return await _fallback(speechFile, outputFile);
      }

      // Clamp volume to safe range
      final double vol = bgmVolume.clamp(0.0, 1.0);

      // Build ffmpeg amix filter
      // - duration=first  → output length = speech length (TTS ends, music fades out)
      // - loop BGM if mode is repeat
      final bool loop = (playMode == BgmPlayMode.repeatOne ||
          playMode == BgmPlayMode.repeatAll);

      // Use stream_loop=-1 for looping BGM input
      final String loopFlag = loop ? '-stream_loop -1' : '';

      // amix weights: speech=1, bgm=vol
      final String cmd = [
        '-y',
        '-i "${speechFile.path}"',
        '$loopFlag -i "${bgmFile.path}"',
        '-filter_complex "[0:a]volume=1[speech];[1:a]volume=${vol.toStringAsFixed(3)}[bgm];[speech][bgm]amix=inputs=2:duration=first:dropout_transition=2[out]"',
        '-map "[out]"',
        // Encode according to output extension
        ...(_codecArgs(outputFile.path)),
        '"${outputFile.path}"',
      ].join(' ');

      debugPrint('AudioMixer FFmpeg cmd: $cmd');

      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) &&
          outputFile.existsSync() &&
          outputFile.lengthSync() > 100) {
        debugPrint(
            'AudioMixer: mixed OK → ${outputFile.path} (${outputFile.lengthSync()} bytes)');
        return outputFile;
      }

      // Log ffmpeg output for debugging
      final logs = await session.getAllLogsAsString();
      debugPrint('AudioMixer FFmpeg failed. Logs:\n$logs');

      return await _fallback(speechFile, outputFile);
    } catch (e, st) {
      debugPrint('AudioMixer error: $e\n$st');
      return await _fallback(speechFile, outputFile);
    }
  }

  /// Returns ffmpeg codec arguments based on output file extension.
  static List<String> _codecArgs(String outPath) {
    final ext = outPath.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp3':
        return ['-acodec libmp3lame', '-q:a 2'];
      case 'aac':
      case 'm4a':
        return ['-acodec aac', '-b:a 192k'];
      case 'wav':
      default:
        return ['-acodec pcm_s16le'];
    }
  }

  /// Converts [inputFile] (typically WAV) into the format implied by [outputFile]'s extension.
  static Future<File> convertFormat({
    required File inputFile,
    required File outputFile,
  }) async {
    if (!inputFile.existsSync() || inputFile.lengthSync() < 44) {
      return inputFile;
    }

    final inExt = inputFile.path.split('.').last.toLowerCase();
    final outExt = outputFile.path.split('.').last.toLowerCase();
    if (inExt == outExt) {
      try {
        await inputFile.copy(outputFile.path);
        return outputFile;
      } catch (_) {
        return inputFile;
      }
    }

    try {
      final String cmd = [
        '-y',
        '-i "${inputFile.path}"',
        ...(_codecArgs(outputFile.path)),
        '"${outputFile.path}"',
      ].join(' ');

      debugPrint('AudioMixer convert cmd: $cmd');
      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) &&
          outputFile.existsSync() &&
          outputFile.lengthSync() > 100) {
        debugPrint(
            'AudioMixer: convert OK → ${outputFile.path} (${outputFile.lengthSync()} bytes)');
        return outputFile;
      }

      final logs = await session.getAllLogsAsString();
      debugPrint('AudioMixer convert failed. Logs:\n$logs');
      return await _fallback(inputFile, outputFile);
    } catch (e, st) {
      debugPrint('AudioMixer convert error: $e\n$st');
      return await _fallback(inputFile, outputFile);
    }
  }

  static Future<File> _fallback(File src, File out) async {
    try {
      await src.copy(out.path);
      return out;
    } catch (_) {
      return src;
    }
  }
}
