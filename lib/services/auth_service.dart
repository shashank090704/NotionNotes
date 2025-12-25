import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      
      if (_token != null) {
        final userJson = prefs.getString('user');
        if (userJson != null) {
          _currentUser = User.fromJson(jsonDecode(userJson));
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      print('Error loading token: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.signupEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['token'], data['user']);
        return true;
      } else {
        print('Signup failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['token'], data['user']);
        return true;
      } else {
        print('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    _token = token;
    _currentUser = User.fromJson(userData);
    _isAuthenticated = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(userData));

    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    notifyListeners();
  }
}