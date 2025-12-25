class AppConstants {
  // Change this to your backend URL
  // For local development: 'http://10.0.2.2:5000' for Android emulator
  // or 'http://localhost:5000' for web/iOS simulator
  static const String baseUrl = 'https://notion-notes-backend-owkg.vercel.app/api';
  
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String signupEndpoint = '$baseUrl/auth/signup';
  static const String notesEndpoint = '$baseUrl/notes';
}