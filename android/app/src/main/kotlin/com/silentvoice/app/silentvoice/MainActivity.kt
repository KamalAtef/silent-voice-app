package com.silentvoice.app.silentvoice
import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "asl_landmark_channel"
        private const val CAMERA_PERMISSION_CODE = 100
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var cameraExecutor: ExecutorService
    private var handLandmarker: HandLandmarker? = null

    @Volatile
    private var latestLandmarks: List<List<Double>>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        cameraExecutor = Executors.newSingleThreadExecutor()

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startCamera" -> {
                    if (hasCameraPermission()) {
                        initMediaPipe()
                        startCamera()
                        result.success("Camera started")
                    } else {
                        requestCameraPermission()
                        result.error("NO_PERMISSION", "Camera permission denied", null)
                    }
                }
                "getLandmarks" -> {
                    result.success(latestLandmarks)
                }
                "stopCamera" -> {
                    stopCamera()
                    result.success("Camera stopped")
                }
                else -> result.notImplemented()
            }
        }
    }

    // ─── MediaPipe ──────────────────────────────────────────────────────────

    private fun initMediaPipe() {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("hand_landmarker.task")
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setNumHands(1)
            .setMinHandDetectionConfidence(0.3f)
            .setMinHandPresenceConfidence(0.3f)
            .setMinTrackingConfidence(0.3f)
            .setRunningMode(RunningMode.IMAGE)
            .build()

        handLandmarker = HandLandmarker.createFromOptions(this, options)
    }

    // ─── CameraX ────────────────────────────────────────────────────────────

    private var cameraProvider: ProcessCameraProvider? = null

    private fun startCamera() {
        val providerFuture = ProcessCameraProvider.getInstance(this)

        providerFuture.addListener({
            cameraProvider = providerFuture.get()

            val imageAnalysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
                .build()

            imageAnalysis.setAnalyzer(cameraExecutor) { imageProxy ->
                processFrame(imageProxy)
            }

            cameraProvider?.unbindAll()
            cameraProvider?.bindToLifecycle(
                this as LifecycleOwner,
                CameraSelector.DEFAULT_FRONT_CAMERA,
                imageAnalysis
            )

        }, ContextCompat.getMainExecutor(this))
    }

    private fun stopCamera() {
        cameraProvider?.unbindAll()
        latestLandmarks = null
    }

    // ─── Frame processing ───────────────────────────────────────────────────

    private fun processFrame(imageProxy: ImageProxy) {
        try {
            val bitmap = imageProxy.toBitmap()
            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = handLandmarker?.detect(mpImage)

            latestLandmarks = if (result != null && result.landmarks().isNotEmpty()) {
                result.landmarks()[0].map { lm ->
                    listOf(lm.x().toDouble(), lm.y().toDouble(), lm.z().toDouble())
                }
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            imageProxy.close()
        }
    }

    // ─── YUV → Bitmap ───────────────────────────────────────────────────────

    private fun ImageProxy.toBitmap(): Bitmap {
        val yBuffer = planes[0].buffer
        val uBuffer = planes[1].buffer
        val vBuffer = planes[2].buffer
        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()
        val nv21 = ByteArray(ySize + uSize + vSize)
        yBuffer.get(nv21, 0, ySize)
        vBuffer.get(nv21, ySize, vSize)
        uBuffer.get(nv21, ySize + vSize, uSize)
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 85, out)
        return BitmapFactory.decodeByteArray(out.toByteArray(), 0, out.size())
    }

    // ─── Permissions ─────────────────────────────────────────────────────────

    private fun hasCameraPermission() =
        ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED

    private fun requestCameraPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_CODE
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
        handLandmarker?.close()
    }
}