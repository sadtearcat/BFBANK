# BarriorFreeBank (BFBANK)

BF Bank - AI-powered object detection application built with Flutter.
*This project is migrated from ReactNative Project*

## Features

- Real-time object detection using YOLO models
- Camera-based detection with live preview
- Object cropping and gallery management
- Clean architecture with separation of concerns

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / Xcode for platform-specific development
- AI models (not included in repository for security reasons)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd bfbank
```

2. Install dependencies:
```bash
flutter pub get
```

3. Add your AI models:
   - Place `.tflite` model files in `assets/` directory
   - Place additional models in `android/app/src/main/assets/` if needed
   - Update model paths in the code accordingly

4. Run the application:
```bash
flutter run
```

## Project Structure

```
lib/
├── features/
│   └── object_detection/
│       └── presentation/
│           └── pages/
└── services/
    ├── coordinate_transformer.dart
    ├── image_processing_service.dart
    ├── object_crop_service.dart
    └── gallery_service.dart
```

## Architecture

The project follows clean architecture principles with:

- **Presentation Layer**: UI components and pages
- **Service Layer**: Business logic and data processing
- **Utility Layer**: Helper functions and transformations

## Security Notes

- AI models and training data are excluded from version control
- Configuration files containing sensitive information are ignored
- Models should be added locally for development and testing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is proprietary and confidential.
