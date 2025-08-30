package com.example.noodle

import android.content.Context
import android.graphics.BitmapFactory
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.genai.llminference.GraphOptions
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import java.io.File

private const val DEFAULT_MAX_TOKEN = 4096
private const val DEFAULT_TOPK = 32
private const val DEFAULT_TOPP = 0.8f
private const val DEFAULT_TEMPERATURE = 0.8f
private const val TAG = "LLMHelper"

private data class LlmModelInstance(val engine: LlmInference, var session: LlmInferenceSession)

class AppLlmModel(
    val modelPath: String,
    val llmSupportImage: Boolean = true,
    var maxTokens: Int = DEFAULT_MAX_TOKEN,
    var topK: Int = DEFAULT_TOPK,
    var topP: Float = DEFAULT_TOPP,
    var temperature: Float = DEFAULT_TEMPERATURE,
    var accelerator: String = "GPU"
)

data class InitResult(val status: Boolean, val message: String)

object LlmHelper {
    private var activeModelInstance: LlmModelInstance? = null

    fun initialize(
        context: Context,
        modelPath: String,
        prompt: String,
        imagePaths: List<String>,
        llmSupportImage: Boolean,
        type: String = "cpu",
        onDone: (InitResult) -> Unit
    ) {
        // Run on background thread to avoid blocking UI
        Thread {
            initializeInternal(context, modelPath, prompt, imagePaths, llmSupportImage, type, onDone)
        }.start()
    }

    private fun initializeInternal(
        context: Context,
        modelPath: String,
        prompt: String,
        imagePaths: List<String>,
        llmSupportImage: Boolean,
        type: String,
        onDone: (InitResult) -> Unit
    ) {
        Log.d(TAG, "Initializing LLM with model at: $modelPath")
        cleanUp()

        // Validate model file
        if (!isValidModelFile(modelPath)) {
            onDone(InitResult(false, "Invalid or missing model file at: $modelPath"))
            return
        }

        try {
            val config = AppLlmModel(modelPath, llmSupportImage)

            // Determine backend based on type parameter
            val backend = when (type.lowercase()) {
                "gpu" -> LlmInference.Backend.GPU
                else -> LlmInference.Backend.CPU
            }
            
            Log.d(TAG, "Using backend: $backend (type: $type)")
            
            val options = LlmInference.LlmInferenceOptions.builder()
                .setModelPath(modelPath)
                .setMaxTokens(config.maxTokens)
                .setPreferredBackend(backend)
                .setMaxNumImages(1)
                .build()

            val engine = LlmInference.createFromOptions(context, options)

            val sessionOptions = LlmInferenceSession.LlmInferenceSessionOptions.builder()
                .setTopK(config.topK)
                .setTopP(config.topP)
                .setTemperature(config.temperature)
                .setGraphOptions(
                    GraphOptions.builder().setEnableVisionModality(llmSupportImage).build()
                )
                .build()

            val session = LlmInferenceSession.createFromOptions(engine, sessionOptions)
            session.addQueryChunk(prompt)
            Log.d(TAG, "prompt: $prompt")

            if (llmSupportImage) {
                imagePaths.forEach { path ->
                    try {
                        Log.d(TAG, "Image path: $path")
                        BitmapFactory.decodeFile(path)?.let {
                            val mpImage: MPImage = BitmapImageBuilder(it).build()
                            session.addImage(mpImage)
                            Log.d(TAG, "Image added: $path")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Image error: $path", e)
                    }
                }
            }

            val result = session.generateResponse()
            activeModelInstance = LlmModelInstance(engine, session)
            Log.d(TAG, "Response From LLM: $result")
            onDone(InitResult(true, result))

        } catch (e: Exception) {
            val errorMsg = "LLM init failed: ${e.message}"
            Log.e(TAG, errorMsg, e)
            onDone(InitResult(false, errorMsg))
        }
    }

    fun cleanUp() {
        activeModelInstance?.let {
            try {
                it.session.close()
                it.engine.close()
                Log.d(TAG, "Cleaned up previous session!!")
            } catch (e: Exception) {
                Log.e(TAG, "Cleanup error: ${e.message}", e)
            } finally {
                activeModelInstance = null
            }
        }
    }

    private fun isValidModelFile(modelPath: String): Boolean {
        return try {
            val file = File(modelPath)
            file.exists() && file.isFile && file.length() > 0
        } catch (e: Exception) {
            Log.e(TAG, "Error checking model file: ${e.message}", e)
            false
        }
    }
}
