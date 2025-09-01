package com.example.noodle

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "noodle_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "giveResponse" -> {
                    try {
                        // Extract parameters from the method call
                        val message = call.argument<String>("message") ?: ""
                        val taskFilePath = call.argument<String>("taskFilePath") ?: ""
                        val sessionId = call.argument<Int>("sessionId")
                        val queryType = call.argument<String>("queryType") ?: ""
                        val hasImage = call.argument<Boolean>("hasImage") ?: false
                        val imagePath = call.argument<String>("imagePath")
                        val type = call.argument<String>("type") ?: "cpu"
                        
                        // Log the received data
                        Log.d("NoodleChannel", "Message received: $message")
                        Log.d("NoodleChannel", "Task file path: $taskFilePath")
                        Log.d("NoodleChannel", "Session ID: $sessionId")
                        Log.d("NoodleChannel", "Query type: $queryType")
                        Log.d("NoodleChannel", "Has image: $hasImage")
                        Log.d("NoodleChannel", "Image path: $imagePath")
                        Log.d("NoodleChannel", "Processing type: $type")
                        
                        // Process with LLM if task file exists
                        val taskFile = File(taskFilePath)
                        if (taskFile.exists()) {
                            // Prepare image paths list
                            val imagePaths = mutableListOf<String>()
                            if (hasImage && imagePath != null) {
                                imagePaths.add(imagePath)
                            }
                            
                            // Initialize LLM with the task file
                            LlmHelper.initialize(
                                context = this@MainActivity,
                                modelPath = taskFilePath,
                                prompt = message,
                                imagePaths = imagePaths,
                                llmSupportImage = hasImage,
                                type = type
                            ) { initResult ->
                                if (initResult.status) {
                                    result.success(initResult.message)
                                } else {
                                    result.error("LLM_ERROR", initResult.message, null)
                                }
                            }
                        } else {
                            // Task file doesn't exist, return error
                            val response = "Error: Task file not found at path: $taskFilePath"
                            result.error("TASK_FILE_NOT_FOUND", response, null)
                        }
                        
                    } catch (e: Exception) {
                        Log.e("NoodleChannel", "Error processing method call", e)
                        result.error("ERROR", "Failed to process request", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Clean up LLM resources
        LlmHelper.cleanUp()
    }
}
