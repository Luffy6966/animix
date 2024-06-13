import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: _tryAutoLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == true) {
              return AnotherScreen();
            } else {
              return LoginScreen();
            }
          } else {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Future<bool> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('key');
    print('Loaded key: $key'); // Debug info
    if (key != null) {
      return true;
    } else {
      return false;
    }
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final String nickname = _usernameController.text;
    final String password = _passwordController.text;

    final String url = 'https://api.animix.lol/auth/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nickname': nickname, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('type') &&
            responseData['type'] == 'success') {
          final key = responseData['data']['key'];
          await _saveKeyLocally(key);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AnotherScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Ошибка аутентификации: ${responseData['message']}'),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
          Text('Ошибка сервера: ${response.statusCode} ${response.body}'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Произошла ошибка при выполнении запроса: $e'),
      ));
    }
  }

  Future<void> _saveKeyLocally(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('key', key);
    print('Saved key: $key'); // Debug info
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF232323),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 32.0),
                child: SvgPicture.asset(
                  'assets/logo.svg',
                  height: 100.0,
                ),
              ),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  hintText: 'Логин',
                  hintStyle:
                  TextStyle(color: Colors.grey, fontFamily: 'MyFonts'),
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontFamily: 'MyFonts'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  hintText: 'Пароль',
                  hintStyle:
                  TextStyle(color: Colors.grey, fontFamily: 'MyFonts'),
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                ),
                obscureText: true,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontFamily: 'MyFonts'),
              ),
              SizedBox(height: 32.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Color(0xFF7544b2),
                      ),
                      child: Text('Войти',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'MyFonts')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnotherScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Другой экран'),
      ),
      body: Center(
        child: Text('Вы успешно вошли!'),
      ),
    );
  }
}