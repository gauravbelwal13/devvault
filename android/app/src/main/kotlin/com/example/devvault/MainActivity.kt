package com.example.devvault

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "devvault/image_generation"
    }

    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "generateImage" -> {
                    val prompt = call.argument<String>("prompt")
                    val iterations = call.argument<Int>("iterations") ?: 20
                    val seed = call.argument<Int>("seed") ?: 12345

                    if (prompt.isNullOrBlank()) {
                        result.error(
                            "INVALID_PROMPT",
                            "Prompt cannot be empty.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    executor.execute {
                        try {
                            val outputPath = generateImage(
                                prompt = prompt,
                                iterations = iterations,
                                seed = seed,
                            )

                            runOnUiThread {
                                result.success(outputPath)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error(
                                    "GENERATION_FAILED",
                                    e.message ?: "Image generation failed.",
                                    null
                                )
                            }
                        }
                    }
                }

                "isModelAvailable" -> {
                    result.success(isModelAvailable())
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isModelAvailable(): Boolean {
        val modelDirectory = File(
            filesDir,
            "devvault/models/image_generator"
        )

        return modelDirectory.exists() &&
            modelDirectory.isDirectory &&
            modelDirectory.listFiles()?.isNotEmpty() == true
    }

    private fun generateImage(
        prompt: String,
        iterations: Int,
        seed: Int,
    ): String {

        /*
         * MediaPipe ImageGenerator initialization will go here.
         *
         * IMPORTANT:
         * The foundation model is NOT bundled into the APK.
         *
         * Google specifically recommends downloading the converted
         * model during runtime because the model is too large to
         * bundle into an APK.
         */

        throw IllegalStateException(
            "Local image generation model is not installed yet."
        )
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}