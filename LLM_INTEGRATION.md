# LLM Integration Documentation

## Overview

This Flutter app now includes MediaPipe LLM integration for AI-powered chat responses. The integration allows the app to process user messages and images through a local LLM model.

## Architecture

### Flutter Side

- **Method Channel**: `noddle_channel`
- **Method**: `giveResponse`
- **Parameters**:
  - `message`: User's input text
  - `taskFilePath`: Full path to the LLM model file
  - `sessionId`: Current chat session ID
  - `queryType`: CPU/GPU query type
  - `hasImage`: Boolean indicating if image is attached
  - `imagePath`: Full path to attached image (if any)

### Android Side

- **MainActivity.kt**: Handles method channel communication
- **LlmHelper.kt**: Manages LLM model initialization and inference
- **MediaPipe Integration**: Uses Google MediaPipe for LLM inference

## Dependencies

### Android Dependencies (build.gradle.kts)

```kotlin
dependencies {
    // MediaPipe dependencies for LLM inference
    implementation("com.google.mediapipe:tasks-genai:0.10.8")
    implementation("com.google.mediapipe:tasks-vision:0.10.8")
    implementation("com.google.mediapipe:framework:0.10.8")

    // Additional dependencies for image processing
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}
```

### Android Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## LLM Configuration

### Default Settings

- **Max Tokens**: 4096
- **Top-K**: 32
- **Top-P**: 0.8
- **Temperature**: 0.8
- **Backend**: CPU (configurable)
- **Max Images**: 3

### Model Requirements

- The model file should be a valid MediaPipe-compatible LLM model
- File format: `.task` (MediaPipe task format)
- Location: App's internal storage directory
- File name: `model.task`

## Usage Flow

1. **User sends message** → Flutter app
2. **Method channel call** → Android native code
3. **LLM initialization** → MediaPipe engine setup
4. **Model inference** → Process message and images
5. **Response generation** → Return AI response
6. **Cleanup** → Release resources

## Error Handling

### Common Errors

- **TASK_FILE_NOT_FOUND**: Model file doesn't exist at specified path
- **LLM_ERROR**: LLM initialization or inference failed
- **INVALID_ARGUMENTS**: Method channel parameters are invalid

### Error Responses

- All errors are logged with detailed information
- User-friendly error messages are returned to Flutter
- Graceful fallback responses are provided

## Performance Considerations

### Memory Management

- LLM resources are automatically cleaned up when activity is destroyed
- Previous sessions are cleaned up before starting new ones
- Background thread processing prevents UI blocking

### Model Loading

- Model validation before initialization
- File existence and size checks
- Error handling for corrupted model files

## Testing

### Manual Testing

1. Import a valid `.task` model file
2. Send a text message in the chat
3. Verify LLM response is received
4. Test with image attachments
5. Check error handling with invalid model

### Debug Logging

- All LLM operations are logged with TAG "LLMHelper"
- Model path, prompt, and response are logged
- Image processing status is logged
- Error details are logged for debugging

## Future Enhancements

### Planned Features

- GPU acceleration support
- Model caching for faster loading
- Batch processing for multiple messages
- Custom model configuration options
- Model performance metrics

### Platform Extensions

- iOS implementation with Core ML
- macOS implementation
- Linux implementation with TensorFlow Lite

## Troubleshooting

### Common Issues

1. **Model not loading**: Check file path and permissions
2. **Memory issues**: Ensure sufficient device memory
3. **Slow responses**: Consider using GPU backend
4. **Image processing errors**: Verify image format and size

### Debug Steps

1. Check Android logs for LLMHelper messages
2. Verify model file exists and is valid
3. Test with simple text-only messages first
4. Check device memory usage during inference
