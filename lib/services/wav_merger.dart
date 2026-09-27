import 'dart:io';
import 'dart:typed_data';

/// Utility to merge multiple WAV audio files into a single continuous WAV file.
/// Standard RIFF/WAVE PCM format concatenation.
class WavMerger {
  /// Merges multiple WAV files into [outputFile].
  static Future<File> mergeWavFiles(List<File> files, File outputFile) async {
    if (files.isEmpty) {
      throw Exception('Không có tệp âm thanh nào để ghép nối.');
    }
    if (files.length == 1) {
      await files.first.copy(outputFile.path);
      return outputFile;
    }

    final List<Uint8List> audioDataChunks = [];
    Uint8List? firstFileHeader;
    int dataChunkOffsetInFirstHeader = -1;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      if (!file.existsSync() || file.lengthSync() < 44) {
        continue;
      }
      final bytes = await file.readAsBytes();
      final dataInfo = _findDataChunk(bytes);
      if (dataInfo == null) continue;

      final dataStart = dataInfo['offset']! + 8;
      final dataLength = dataInfo['size']!;
      final actualDataEnd = (dataStart + dataLength <= bytes.length)
          ? dataStart + dataLength
          : bytes.length;

      if (actualDataEnd > dataStart) {
        audioDataChunks.add(bytes.sublist(dataStart, actualDataEnd));
      }

      if (firstFileHeader == null) {
        firstFileHeader = bytes.sublist(0, dataStart);
        dataChunkOffsetInFirstHeader = dataInfo['offset']!;
      }
    }

    if (firstFileHeader == null || audioDataChunks.isEmpty) {
      // Fallback: If parsing headers fails, copy the largest file
      files.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
      await files.first.copy(outputFile.path);
      return outputFile;
    }

    // Calculate total audio sample data size
    int totalDataSize = 0;
    for (final chunk in audioDataChunks) {
      totalDataSize += chunk.length;
    }

    // Total RIFF size = (firstFileHeader.length - 8) + totalDataSize
    final int totalRiffSize = (firstFileHeader.length - 8) + totalDataSize;

    // Update RIFF chunk size at bytes 4..7 in header
    final headerBytes = Uint8List.fromList(firstFileHeader);
    final headerByteData = ByteData.sublistView(headerBytes);
    headerByteData.setUint32(4, totalRiffSize, Endian.little);

    // Update 'data' subchunk size at dataChunkOffsetInFirstHeader + 4
    headerByteData.setUint32(dataChunkOffsetInFirstHeader + 4, totalDataSize, Endian.little);

    // Write merged file
    final sink = outputFile.openWrite();
    sink.add(headerBytes);
    for (final chunk in audioDataChunks) {
      sink.add(chunk);
    }
    await sink.flush();
    await sink.close();

    return outputFile;
  }

  /// Locates the 'data' chunk in a WAV byte array.
  static Map<String, int>? _findDataChunk(Uint8List bytes) {
    if (bytes.length < 12) return null;
    // Check RIFF and WAVE magic headers
    if (bytes[0] != 0x52 || bytes[1] != 0x49 || bytes[2] != 0x46 || bytes[3] != 0x46) {
      return null;
    }
    if (bytes[8] != 0x57 || bytes[9] != 0x41 || bytes[10] != 0x56 || bytes[11] != 0x45) {
      return null;
    }

    int offset = 12;
    final byteData = ByteData.sublistView(bytes);

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);

      if (chunkId == 'data') {
        return {'offset': offset, 'size': chunkSize};
      }

      offset += 8 + chunkSize;
      if (chunkSize % 2 != 0) {
        offset += 1;
      }
    }
    return null;
  }
}
