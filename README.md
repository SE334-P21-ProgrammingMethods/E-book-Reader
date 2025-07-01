# 📚 E-book Reader

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Material Design](https://img.shields.io/badge/Material%20Design-757575?style=for-the-badge&logo=material-design&logoColor=white)](https://material.io)

A modern, feature-rich e-book reader application built with Flutter for **SE334.P21 - Programming Methods** course. Experience seamless reading across all your devices with cloud synchronization, customizable themes, and support for multiple e-book formats.

![Platform Support](https://img.shields.io/badge/Platform-Android-blue)

## ✨ Features

### 📖 **Reading Experience**

- **Multi-format Support**: Native PDF and EPUB readers
- **Advanced PDF Viewer**: Powered by Syncfusion with smooth navigation
- **EPUB Reader**: Full-featured with chapter navigation and text flow
- **Search Functionality**: Find text within books with highlighting
- **Reading Progress**: Automatic bookmark saving and resume reading
- **Customizable Display**: Adjustable font sizes and reading themes

### 🔐 **Authentication & Security**

- **Firebase Authentication**: Secure user management
- **Email/Password Sign-in**: Traditional authentication method
- **Google Sign-in**: One-tap authentication with Google accounts
- **Password Recovery**: Email-based password reset functionality
- **Account Verification**: Email verification for enhanced security

### ☁️ **Cloud Integration**

- **Firebase Storage**: Secure cloud storage for e-books
- **Real-time Sync**: Books and bookmarks sync across all devices
- **Firestore Database**: Fast, scalable NoSQL database
- **Offline Support**: Read downloaded books without internet
- **Cross-device Continuity**: Resume reading on any device

### 🎨 **User Interface & Customization**

- **Material Design 3**: Modern, beautiful interface
- **Dark/Light Themes**: Automatic or manual theme switching
- **Font Size Control**: Three adjustable font sizes (Small, Medium, Large)
- **Google Fonts**: Beautiful Lobster typography
- **Responsive Design**: Optimized for all screen sizes
- **Intuitive Navigation**: Bottom navigation with clear visual feedback

### 📑 **Library Management**

- **Smart Library**: Grid and list view modes
- **File Upload**: Easy book import from device storage
- **Book Organization**: Search and filter your collection
- **Metadata Management**: Edit book titles and information
- **Format Detection**: Automatic PDF/EPUB format recognition
- **Progress Tracking**: Visual reading progress indicators

### 🔖 **Bookmarks & Navigation**

- **Smart Bookmarks**: Save any page or location
- **Bookmark Management**: Organized by book with search
- **Quick Navigation**: Jump to bookmarked locations instantly
- **Location Sync**: Bookmarks available across all devices
- **Reading History**: Track your reading journey

### 📱 **Platform Support**

- **Android**: Native Android app experience with Material Design 3
- **Optimized Performance**: Smooth scrolling and fast page rendering
- **Android Permissions**: Proper file access and storage handling
- **Native Integration**: Follows Android platform conventions
- **Responsive Design**: Adapts to various Android screen sizes

## 🛠️ Technology Stack

### **Frontend**

- **Flutter SDK**: Cross-platform UI framework
- **Dart Language**: Modern, efficient programming language
- **Material Design 3**: Latest design system implementation
- **Bloc Pattern**: Predictable state management
- **Google Fonts**: Typography enhancement

### **Backend & Services**

- **Firebase Core**: Backend-as-a-Service platform
- **Firebase Auth**: User authentication and management
- **Cloud Firestore**: NoSQL document database
- **Firebase Storage**: Cloud file storage and hosting
- **Google Sign-In**: OAuth authentication integration

### **Reading Engines**

- **Syncfusion PDF Viewer**: Professional PDF rendering
- **Flutter EPUB Viewer**: EPUB book reading capabilities
- **HTTP Client**: File download and caching
- **Path Provider**: Local file system management

### **Additional Libraries**

- **SharedPreferences**: Local data persistence
- **File Picker**: System file selection
- **Image Picker**: Profile picture and image handling

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.2.3 or higher
- **Dart SDK**: Version 3.2.3 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account**: For backend services

### Installation

### **For Normal Users (APK Installation)**

If you're not a developer and just want to use the app:

1. **Download the APK**
   - Go to the [Releases](https://github.com/your-username/ebook-reader/releases) page
   - Download the latest APK file

2. **Enable Unknown Sources**
   - Go to **Settings** > **Security** (or **Privacy**)
   - Enable **"Install unknown apps"** or **"Unknown sources"**
   - This allows installation of apps outside Google Play Store

3. **Install the APK**
   - Open the downloaded APK file
   - Tap **"Install"** when prompted
   - Wait for installation to complete
   - Tap **"Open"** to launch the app

4. **First Time Setup**
   - Create an account or sign in with Google
   - Grant necessary permissions when prompted
   - Start adding and reading your e-books!

**Note**: The app requires internet connection for authentication and cloud sync features.

### **For Developers**

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/ebook-reader.git
   cd ebook-reader
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup**

   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password and Google Sign-in)
   - Create a Firestore database
   - Set up Firebase Storage
   - Download and place configuration files:
     - `google-services.json` in `android/app/`
     - `GoogleService-Info.plist` in `ios/Runner/`

4. **Run the application**
   ```bash
   flutter run
   ```

### Firebase Configuration

The app requires the following Firebase services:

- **Authentication**: Email/Password and Google Sign-in providers
- **Firestore Database**: Collections for users, books, and bookmarks
- **Storage**: Bucket for e-book file storage

## 📝 Usage

### Getting Started

1. **Sign Up**: Create a new account or sign in with Google
2. **Add Books**: Upload PDF or EPUB files from your device
3. **Start Reading**: Tap any book to begin reading
4. **Customize**: Adjust themes and font sizes in Settings
5. **Bookmark**: Save your favorite passages and reading positions
6. **Sync**: Access your library from any device

### Supported Formats

- **PDF**: Full support with search, bookmarks, and navigation
- **EPUB**: Reflowable text with customizable display

## 🏗️ Architecture

The application follows **Clean Architecture** principles with **BLoC pattern**:

```
lib/
├── models/          # Data models (Book, User, Bookmark)
├── screens/         # UI screens organized by feature
│   ├── auth/        # Authentication screens
│   ├── library/     # Book library management
│   ├── reader/      # PDF and EPUB readers
│   ├── bookmark/    # Bookmark management
│   ├── setting/     # App settings
│   └── theme/       # Theme management
├── widgets/         # Reusable UI components
│   ├── book/        # Book-related widgets
│   ├── bookmark/    # Bookmark widgets
│   ├── components/  # Common UI components
│   ├── library/     # Library view widgets
│   ├── navigation/  # Navigation components
│   └── settings/    # Settings widgets
├── enums/           # Application enumerations
└── assets/          # Static assets and placeholders
```

## 🔧 Configuration

### Theme Customization

The app supports extensive theming through the `ThemeCubit`:

- Light and dark color schemes
- Font size scaling (1x, 1.2x, 1.5x)
- Google Fonts integration
- Material Design 3 components

### Reading Settings

- Scroll direction (vertical/horizontal for PDF)
- Font size preferences
- Theme preferences for reading
- Bookmark sync preferences

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Guidelines

1. Follow Flutter/Dart style guidelines
2. Use BLoC pattern for state management
3. Write comprehensive tests
4. Update documentation for new features
5. Ensure cross-platform compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **SE334.P21 - Programming Methods** course instructors and peers
- **Flutter Team** for the amazing framework
- **Firebase Team** for robust backend services
- **Syncfusion** for the excellent PDF viewer component
- **Open Source Community** for various Flutter packages

---

<div align="center">

**Built with ❤️ using Flutter**

_For educational purposes - SE334.P21 Programming Methods_

[Report Bug](https://github.com/your-username/ebook-reader/issues) · [Request Feature](https://github.com/your-username/ebook-reader/issues) · [Documentation](https://github.com/your-username/ebook-reader/wiki)

</div>
