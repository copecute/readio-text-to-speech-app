package com.copecute.readio.readio

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StrictMode
import android.provider.DocumentsContract
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.copecute.readio/storage"
    private val STORAGE_PERMISSION_CODE = 1001

    private val NOTIFICATION_PERMISSION_CODE = 1002

    private fun checkNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= 33) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= 33) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_CODE
            )
            true
        } else {
            true
        }
    }

    private fun checkStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.data = Uri.parse("package:" + applicationContext.packageName)
                startActivity(intent)
                return true
            } catch (e: Exception) {
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                    startActivity(intent)
                    return true
                } catch (e2: Exception) {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = Uri.parse("package:" + applicationContext.packageName)
                        startActivity(intent)
                        return true
                    } catch (e3: Exception) {
                        return false
                    }
                }
            }
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    Manifest.permission.READ_EXTERNAL_STORAGE
                ),
                STORAGE_PERMISSION_CODE
            )
            return true
        }
    }

    private fun openFolderInFileManager(folderPath: String): Boolean {
        val dir = File(folderPath)
        if (!dir.exists()) {
            dir.mkdirs()
        }

        // Allow file:// URI without FileUriExposedException on legacy receivers
        try {
            val m = StrictMode::class.java.getMethod("disableDeathOnFileUriExposure")
            m.invoke(null)
        } catch (_: Exception) {}

        val extStorage = Environment.getExternalStorageDirectory().absolutePath
        val relativePath = if (dir.absolutePath.startsWith(extStorage)) {
            dir.absolutePath.removePrefix(extStorage).trimStart('/')
        } else {
            ""
        }
        val encodedDocId = Uri.encode(if (relativePath.isNotEmpty()) "primary:$relativePath" else "primary:")

        // 1. Try DocumentsContract / DocumentsUI Document URI (Files by Google & AOSP)
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(
                    Uri.parse("content://com.android.externalstorage.documents/document/$encodedDocId"),
                    "vnd.android.document/directory"
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            return true
        } catch (_: Exception) {}

        // 2. Try MIME type "resource/folder"
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(
                    Uri.parse("content://com.android.externalstorage.documents/document/$encodedDocId"),
                    "resource/folder"
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            return true
        } catch (_: Exception) {}

        // 3. Samsung My Files specific intent
        try {
            val intent = Intent("com.sec.android.app.myfiles.VIEW_FOLDER").apply {
                putExtra("FOLDER_PATH", dir.absolutePath)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            return true
        } catch (_: Exception) {}

        // 4. Try root documents provider URI
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(
                    Uri.parse("content://com.android.externalstorage.documents/root/primary"),
                    "vnd.android.document/root"
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            return true
        } catch (_: Exception) {}

        // 5. Direct file:// URI with resource/folder (for third party file managers)
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.fromFile(dir), "resource/folder")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            return true
        } catch (_: Exception) {}

        // 6. Launch installed File Manager directly
        val fileManagerPackages = listOf(
            "com.google.android.apps.nbu.files",
            "com.sec.android.app.myfiles",
            "com.mi.android.globalFileexplorer",
            "com.android.fileexplorer",
            "com.coloros.filemanager",
            "com.vivo.filemanager",
            "com.huawei.hidisk",
            "com.oneplus.filemanager",
            "com.asus.filemanager",
            "com.android.documentsui",
            "com.google.android.documentsui"
        )

        for (pkg in fileManagerPackages) {
            try {
                val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(launchIntent)
                    return true
                }
            } catch (_: Exception) {}
        }

        return false
    }

    private fun openAudioFile(filePath: String): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        try {
            val m = StrictMode::class.java.getMethod("disableDeathOnFileUriExposure")
            m.invoke(null)
        } catch (_: Exception) {}

        val mimeType = when {
            filePath.endsWith(".mp3", ignoreCase = true) -> "audio/mpeg"
            filePath.endsWith(".wav", ignoreCase = true) -> "audio/wav"
            filePath.endsWith(".m4a", ignoreCase = true) -> "audio/mp4"
            else -> "audio/*"
        }

        // 1. Try FileProvider for modern Android securely
        try {
            val uri = androidx.core.content.FileProvider.getUriForFile(
                applicationContext,
                "${applicationContext.packageName}.fileprovider",
                file
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val chooser = Intent.createChooser(intent, "Mở bằng ứng dụng...")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            return true
        } catch (_: Exception) {}

        // 2. Fallback to direct file URI
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.fromFile(file), mimeType)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val chooser = Intent.createChooser(intent, "Mở bằng ứng dụng...")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            return true
        } catch (_: Exception) {}

        return false
    }

    private val NOTIFICATION_CHANNEL_ID = "readio_tts_channel"
    private val NOTIFICATION_ID = 1002

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Readio Audio Synthesis",
                android.app.NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Thông báo tiến trình tạo tệp âm thanh"
            }
            val manager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun updateProgressNotification(title: String, progress: Int, isFinished: Boolean) {
        try {
            createNotificationChannel()
            val manager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

            if (isFinished) {
                val builder = androidx.core.app.NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                    .setSmallIcon(android.R.drawable.stat_sys_download_done)
                    .setContentTitle("Hoàn tất tạo âm thanh")
                    .setContentText(title)
                    .setPriority(androidx.core.app.NotificationCompat.PRIORITY_DEFAULT)
                    .setAutoCancel(true)
                manager.notify(NOTIFICATION_ID, builder.build())
            } else {
                val builder = androidx.core.app.NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                    .setSmallIcon(android.R.drawable.stat_sys_download)
                    .setContentTitle("Đang tạo tệp MP3 ($progress%)...")
                    .setContentText(title)
                    .setProgress(100, progress, progress <= 0)
                    .setOngoing(true)
                    .setPriority(androidx.core.app.NotificationCompat.PRIORITY_LOW)
                manager.notify(NOTIFICATION_ID, builder.build())
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Notification error: ${e.message}")
        }
    }

    private fun cancelProgressNotification() {
        try {
            val manager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            manager.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {}
    }

    private val MEDIA_NOTIFICATION_CHANNEL_ID = "readio_media_channel"
    private val MEDIA_NOTIFICATION_ID = 1003

    private fun createMediaNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                MEDIA_NOTIFICATION_CHANNEL_ID,
                "Readio Audio Player",
                android.app.NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Trình phát âm thanh Readio"
            }
            val manager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun showMediaNotification(title: String, subtitle: String, isPlaying: Boolean) {
        try {
            createMediaNotificationChannel()
            val manager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

            val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingOpen = android.app.PendingIntent.getActivity(
                this,
                0,
                openAppIntent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                else
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT
            )

            val builder = androidx.core.app.NotificationCompat.Builder(this, MEDIA_NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(if (isPlaying) android.R.drawable.ic_media_play else android.R.drawable.ic_media_pause)
                .setContentTitle(title)
                .setContentText(subtitle)
                .setContentIntent(pendingOpen)
                .setOngoing(isPlaying)
                .setAutoCancel(!isPlaying)
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_LOW)

            manager.notify(MEDIA_NOTIFICATION_ID, builder.build())
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Media notification error: ${e.message}")
        }
    }

    private fun dismissMediaNotification() {
        try {
            val manager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            manager.cancel(MEDIA_NOTIFICATION_ID)
        } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasStoragePermission" -> {
                    result.success(checkStoragePermission())
                }
                "requestStoragePermission" -> {
                    result.success(requestStoragePermission())
                }
                "hasNotificationPermission" -> {
                    result.success(checkNotificationPermission())
                }
                "requestNotificationPermission" -> {
                    result.success(requestNotificationPermission())
                }
                "openFolder" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        result.success(openFolderInFileManager(path))
                    } else {
                        result.success(false)
                    }
                }
                "openFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        result.success(openAudioFile(path))
                    } else {
                        result.success(false)
                    }
                }
                "showProgressNotification" -> {
                    val title = call.argument<String>("title") ?: "Readio Audio"
                    val progress = call.argument<Int>("progress") ?: 0
                    val isFinished = call.argument<Boolean>("isFinished") ?: false
                    updateProgressNotification(title, progress, isFinished)
                    result.success(true)
                }
                "dismissProgressNotification" -> {
                    cancelProgressNotification()
                    result.success(true)
                }
                "showMediaNotification" -> {
                    val title = call.argument<String>("title") ?: "Readio Audio"
                    val subtitle = call.argument<String>("subtitle") ?: "Đang phát âm thanh"
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: true
                    showMediaNotification(title, subtitle, isPlaying)
                    result.success(true)
                }
                "dismissMediaNotification" -> {
                    dismissMediaNotification()
                    result.success(true)
                }
                "exportAudioFile" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    if (sourcePath == null || fileName == null) {
                        result.error("INVALID_ARGS", "sourcePath and fileName are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val srcFile = File(sourcePath)
                        if (!srcFile.exists() || srcFile.length() == 0L) {
                            result.error("SOURCE_NOT_FOUND", "Source audio file does not exist or is empty", null)
                            return@setMethodCallHandler
                        }

                        // Target folder: strictly /storage/emulated/0/copecute/readio
                        val targetDir = File(Environment.getExternalStorageDirectory(), "copecute/readio")
                        if (!targetDir.exists()) {
                            val created = targetDir.mkdirs()
                            if (!created && !targetDir.exists()) {
                                if (!checkStoragePermission()) {
                                    result.error(
                                        "PERMISSION_DENIED",
                                        "Chưa cấp quyền quản lý bộ nhớ để tạo thư mục /copecute/readio. Vui lòng cấp quyền trong Cài đặt.",
                                        null
                                    )
                                    return@setMethodCallHandler
                                }
                            }
                        }

                        val targetFile = File(targetDir, fileName)

                        // Stream copy bytes to completely avoid Linux/Android cross-mount EPERM (errno = 1)
                        FileInputStream(srcFile).use { input ->
                            FileOutputStream(targetFile).use { output ->
                                input.copyTo(output)
                                output.flush()
                            }
                        }

                        // Delete temporary synth file safely
                        try {
                            srcFile.delete()
                        } catch (_: Exception) {}

                        // Scan file with MediaScanner so it instantly shows in File Explorers and Music apps
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(targetFile.absolutePath),
                            arrayOf("audio/mpeg", "audio/mp3", "audio/wav", "audio/*"),
                            null
                        )

                        result.success(
                            mapOf(
                                "success" to true,
                                "path" to targetFile.absolutePath,
                                "size" to targetFile.length()
                            )
                        )
                    } catch (e: SecurityException) {
                        result.error(
                            "PERMISSION_DENIED",
                            "Quyền truy cập bộ nhớ bị từ chối: ${e.message}",
                            null
                        )
                    } catch (e: Exception) {
                        result.error(
                            "COPY_FAILED",
                            e.localizedMessage ?: e.message ?: "Failed to copy audio",
                            null
                        )
                    }
                }
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(path),
                            arrayOf("audio/mpeg", "audio/mp3", "audio/*"),
                            null
                        )
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun mixSpeechAndBgm(
        speechFile: File,
        bgmFile: File,
        bgmVolume: Float,
        playMode: String,
        outputFile: File
    ): Boolean {
        if (!speechFile.exists() || speechFile.length() < 44) return false
        if (!bgmFile.exists() || bgmFile.length() == 0L) return false

        val speechBytes = speechFile.readBytes()
        val speechDataInfo = findWavDataChunk(speechBytes) ?: return false
        val speechHeader = speechBytes.copyOfRange(0, speechDataInfo.first)
        val speechPcm = speechBytes.copyOfRange(
            speechDataInfo.first + 8,
            (speechDataInfo.first + 8 + speechDataInfo.second).coerceAtMost(speechBytes.size)
        )

        val speechByteBuffer = ByteBuffer.wrap(speechHeader).order(ByteOrder.LITTLE_ENDIAN)
        val speechChannels = speechByteBuffer.getShort(22).toInt().coerceAtLeast(1)
        val speechSampleRate = speechByteBuffer.getInt(24).coerceAtLeast(8000)

        val bgmPcmResult = decodeBgmToPcm(bgmFile) ?: return false
        val bgmPcm = bgmPcmResult.pcmBytes
        val bgmSampleRate = bgmPcmResult.sampleRate
        val bgmChannels = bgmPcmResult.channels

        if (speechPcm.isEmpty() || bgmPcm.isEmpty()) return false

        val speechShorts = ShortArray(speechPcm.size / 2)
        ByteBuffer.wrap(speechPcm).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(speechShorts)

        val bgmShorts = ShortArray(bgmPcm.size / 2)
        ByteBuffer.wrap(bgmPcm).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(bgmShorts)

        val outputShorts = ShortArray(speechShorts.size)

        val ratio = bgmSampleRate.toDouble() / speechSampleRate.toDouble()
        val isRepeat = (playMode == "repeatOne" || playMode == "repeatAll")

        val totalBgmFrames = bgmShorts.size / bgmChannels
        val totalSpeechFrames = speechShorts.size / speechChannels

        for (frame in 0 until totalSpeechFrames) {
            val bgmFrame = (frame * ratio).toLong()
            val bgmTargetFrame = if (bgmFrame >= totalBgmFrames) {
                if (isRepeat && totalBgmFrames > 0) bgmFrame % totalBgmFrames else -1L
            } else {
                bgmFrame
            }

            for (c in 0 until speechChannels) {
                val speechIdx = frame * speechChannels + c
                if (speechIdx >= speechShorts.size) break
                val speechSample = speechShorts[speechIdx].toInt()

                val bgmSample = if (bgmTargetFrame >= 0) {
                    val bgmChanIdx = c.coerceAtMost(bgmChannels - 1)
                    val bgmIdx = (bgmTargetFrame * bgmChannels + bgmChanIdx).toInt()
                    if (bgmIdx in bgmShorts.indices) bgmShorts[bgmIdx].toInt() else 0
                } else 0

                var mixed = speechSample + (bgmSample * bgmVolume).toInt()
                if (mixed > 32767) mixed = 32767
                if (mixed < -32768) mixed = -32768

                outputShorts[speechIdx] = mixed.toShort()
            }
        }

        val outputPcmBytes = ByteArray(outputShorts.size * 2)
        ByteBuffer.wrap(outputPcmBytes).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().put(outputShorts)

        val totalDataSize = outputPcmBytes.size
        val totalRiffSize = (speechHeader.size - 8) + totalDataSize

        val headerBytes = speechHeader.clone()
        val headerBuffer = ByteBuffer.wrap(headerBytes).order(ByteOrder.LITTLE_ENDIAN)
        headerBuffer.putInt(4, totalRiffSize)
        headerBuffer.putInt(speechDataInfo.first + 4, totalDataSize)

        FileOutputStream(outputFile).use { out ->
            out.write(headerBytes)
            out.write(outputPcmBytes)
            out.flush()
        }

        return outputFile.exists() && outputFile.length() > 44
    }

    private fun findWavDataChunk(bytes: ByteArray): Pair<Int, Int>? {
        if (bytes.size < 12) return null
        if (bytes[0] != 'R'.code.toByte() || bytes[1] != 'I'.code.toByte() || bytes[2] != 'F'.code.toByte() || bytes[3] != 'F'.code.toByte()) return null
        if (bytes[8] != 'W'.code.toByte() || bytes[9] != 'A'.code.toByte() || bytes[10] != 'V'.code.toByte() || bytes[11] != 'E'.code.toByte()) return null

        var offset = 12
        val buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        while (offset + 8 <= bytes.size) {
            val chunkId = String(bytes, offset, 4)
            val chunkSize = buffer.getInt(offset + 4)
            if (chunkId == "data") {
                return Pair(offset, chunkSize)
            }
            offset += 8 + chunkSize
            if (chunkSize % 2 != 0) offset += 1
        }
        return null
    }

    private data class PcmDecodeResult(val pcmBytes: ByteArray, val sampleRate: Int, val channels: Int)

    private fun writePcmAsWav(pcm: ByteArray, sampleRate: Int, channels: Int, outFile: File) {
        val bitsPerSample = 16
        val byteRate = sampleRate * channels * (bitsPerSample / 8)
        val blockAlign = channels * (bitsPerSample / 8)
        val dataSize = pcm.size
        val riffSize = 36 + dataSize

        FileOutputStream(outFile).use { fos ->
            val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
            // RIFF chunk
            header.put("RIFF".toByteArray())
            header.putInt(riffSize)
            header.put("WAVE".toByteArray())
            // fmt sub-chunk
            header.put("fmt ".toByteArray())
            header.putInt(16)          // PCM chunk size
            header.putShort(1)         // PCM format
            header.putShort(channels.toShort())
            header.putInt(sampleRate)
            header.putInt(byteRate)
            header.putShort(blockAlign.toShort())
            header.putShort(bitsPerSample.toShort())
            // data sub-chunk
            header.put("data".toByteArray())
            header.putInt(dataSize)
            fos.write(header.array())
            fos.write(pcm)
            fos.flush()
        }
    }

    private fun decodeBgmToPcm(file: File): PcmDecodeResult? {
        if (!file.exists()) return null

        val fileBytes = try { file.readBytes() } catch (e: Exception) { null }
        if (fileBytes != null) {
            val wavData = findWavDataChunk(fileBytes)
            if (wavData != null) {
                val buf = ByteBuffer.wrap(fileBytes).order(ByteOrder.LITTLE_ENDIAN)
                val channels = buf.getShort(22).toInt().coerceAtLeast(1)
                val sampleRate = buf.getInt(24).coerceAtLeast(8000)
                val pcm = fileBytes.copyOfRange(
                    wavData.first + 8,
                    (wavData.first + 8 + wavData.second).coerceAtMost(fileBytes.size)
                )
                return PcmDecodeResult(pcm, sampleRate, channels)
            }
        }

        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(file.absolutePath)
            var trackIndex = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) {
                    trackIndex = i
                    format = f
                    break
                }
            }

            if (trackIndex < 0 || format == null) {
                extractor.release()
                return null
            }

            extractor.selectTrack(trackIndex)
            val mime = format.getString(MediaFormat.KEY_MIME)!!
            val sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

            val codec = MediaCodec.createDecoderByType(mime)
            codec.configure(format, null, null, 0)
            codec.start()

            val pcmStream = ByteArrayOutputStream()
            val info = MediaCodec.BufferInfo()
            var isEOS = false

            val kTimeoutUs = 5000L

            while (!isEOS) {
                val inIndex = codec.dequeueInputBuffer(kTimeoutUs)
                if (inIndex >= 0) {
                    val inputBuffer = codec.getInputBuffer(inIndex)
                    if (inputBuffer != null) {
                        val sampleSize = extractor.readSampleData(inputBuffer, 0)
                        if (sampleSize < 0) {
                            codec.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            isEOS = true
                        } else {
                            val timeUs = extractor.sampleTime
                            codec.queueInputBuffer(inIndex, 0, sampleSize, timeUs, 0)
                            extractor.advance()
                        }
                    }
                }

                var outIndex = codec.dequeueOutputBuffer(info, kTimeoutUs)
                while (outIndex >= 0) {
                    val outputBuffer = codec.getOutputBuffer(outIndex)
                    if (outputBuffer != null && info.size > 0) {
                        outputBuffer.position(info.offset)
                        outputBuffer.limit(info.offset + info.size)
                        val chunk = ByteArray(info.size)
                        outputBuffer.get(chunk)
                        pcmStream.write(chunk)
                    }
                    codec.releaseOutputBuffer(outIndex, false)
                    if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        isEOS = true
                        break
                    }
                    outIndex = codec.dequeueOutputBuffer(info, 0)
                }
            }

            codec.stop()
            codec.release()
            extractor.release()

            return PcmDecodeResult(pcmStream.toByteArray(), sampleRate, channels)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error decoding BGM to PCM", e)
            try { extractor.release() } catch (_: Exception) {}
            return null
        }
    }
}

