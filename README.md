# mom_text

mom_text is a cross-platform image editor built with Flutter. It allows users to edit images with various tools and effects, supporting Android, iOS, web, macOS, Windows, and Linux platforms.

## Features
- Open and edit images from device storage
- Add, move, and style text overlays
- Draw and annotate with brushes
- Apply filters and effects
- Export edited images
- Responsive UI for mobile and desktop

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart (comes with Flutter)
- Platform-specific requirements (Android Studio, Xcode, etc.)

### Installation
1. Clone the repository:
   ```sh
   git clone <your-repo-url>
   cd image-editor
   ```
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app:
   ```sh
   flutter run
   ```
   To run on a specific platform, use `-d` (e.g., `flutter run -d chrome` for web).

## Project Structure
- `lib/` – Main Dart source files
- `android/`, `ios/`, `macos/`, `linux/`, `windows/` – Platform-specific code
- `web/` – Web support
- `test/` – Unit and widget tests

## Contributing
Contributions are welcome! Please open issues or submit pull requests for new features, bug fixes, or improvements.

## License
This project is licensed under the MIT License.

## Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language](https://dart.dev/)
