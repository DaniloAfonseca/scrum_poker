import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Box? _box;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    signInByJira();
  }

  Future<void> signInByJira() async {
    _box = await Hive.openBox('ScrumPoker');
    if (_box != null) {
      final token = _box!.get('jiraToken');

      if (token != null) {
        setState(() => _isLoading = true);

        final response = await JiraServices().getJiraUser(token);
        final user = response.data;

        await AuthServices().signInWithCredentials(user!);

        final firebaseUser = FirebaseAuth.instance.currentUser!;

        FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set(user.toJson());

        navigatorKey.currentContext!.go(Routes.home);
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
    }

    AuthServices()
        .signInWithEmailAndPassword(_emailController.text, _passwordController.text)
        .then((user) {
          if (user != null) {
            navigatorKey.currentContext!.go(Routes.home);
          } else {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(const SnackBar(content: Text('Invalid email or password')));
          }
        })
        .catchError((error) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(SnackBar(content: Text('Error: $error')));
        })
        .whenComplete(() {
          setState(() => _isLoading = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isSmallScreen ? screenSize.width * 0.9 : 450.0, maxHeight: 800.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_person, size: 80, color: Colors.blueAccent),
                        const SizedBox(height: 20),
                        Text('Welcome Scrum Poker', style: TextStyle(fontSize: isSmallScreen ? 24 : 28, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                        const SizedBox(height: 10),
                        Text('Sign in', style: TextStyle(fontSize: isSmallScreen ? 24 : 48, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please, introduce your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Please, introduce a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please, introduce your password';
                            }
                            if (value.length < 6) {
                              return 'The password must be at least 6 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Method: "Forgot Password?" not implemented yet')));
                            },
                            child: const Text('Forgot Password?', style: TextStyle(color: Colors.blueAccent)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                              elevation: 5,
                            ),
                            child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('OR', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))),
                            Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          child: ElevatedButton(
                            onPressed: () {
                              AuthServices().signInWithJira();
                            },
                            child: Text('Login by JIRA'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
                      ),
                      child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
