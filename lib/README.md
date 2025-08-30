# Noddle - Flutter Project Structure

This Flutter project follows a clean architecture pattern with organized folder structure for better maintainability and scalability.

## Project Structure

```
lib/
├── constants/           # App-wide constants
│   ├── app_colors.dart  # Color definitions and gradients
│   └── text_styles.dart # Typography styles
├── models/              # Data models (future use)
├── screens/             # Full-screen UI components
│   └── import_screen.dart # Main import screen
├── services/            # Business logic and external services
│   └── file_service.dart # File handling operations
├── utils/               # Utility functions (future use)
├── widgets/             # Reusable UI components
│   └── file_drop_zone.dart # Custom file drop zone widget
└── main.dart           # App entry point
```

## Key Features

### UI Design

- **Purple Gradient Background**: Matches the design specification with smooth gradient transitions
- **Centered Card Layout**: Clean, modern card-based interface
- **Responsive Design**: Adapts to different screen sizes
- **Loading States**: Visual feedback during file operations
- **Status Messages**: Success and error notifications

### File Handling

- **File Picker Integration**: Uses `file_picker` package for cross-platform file selection
- **File Storage**: Automatically stores selected `.task` files in app documents
- **Error Handling**: Comprehensive error handling with user-friendly messages

### Architecture Benefits

- **Separation of Concerns**: UI, business logic, and data handling are separated
- **Reusability**: Components can be easily reused across the app
- **Maintainability**: Clear folder structure makes code easy to navigate
- **Scalability**: Easy to add new features and screens

## Dependencies

- `file_picker`: Cross-platform file picking
- `path_provider`: Access to app directories
- `path`: Path manipulation utilities

## Getting Started

1. Ensure all dependencies are installed: `flutter pub get`
2. Run the app: `flutter run`
3. The app will display the import screen with the purple gradient background
4. Click "Browse Files" or drag and drop a `.task` file to import it

## Future Enhancements

- Add drag and drop functionality for web platforms
- Implement file validation and preview
- Add file management features (list, delete, rename)
- Create additional screens for workflow management
