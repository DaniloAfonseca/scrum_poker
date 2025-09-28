import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

class LoginPage extends StatefulWidget {
  final String? authCode;
  const LoginPage({super.key, this.authCode});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  /// Changes loading flag
  ///
  /// [isLoading] value to update
  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    setState(() => _isLoading = isLoading);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Perform login
  void _login() {
    if (_formKey.currentState!.validate()) {
      _setLoading(true);
    }

    AuthServices()
        .signInWithEmailAndPassword(_emailController.text, _passwordController.text)
        .then((user) {
          // user goes to home page after successful login
          if (user != null) {
            navigatorKey.currentContext!.go(Routes.home);
          } else {
            snackbarMessenger(message: 'Invalid email or password', type: SnackBarType.error);
          }
        })
        .catchError((error) {
          snackbarMessenger(message: 'Error: $error', type: SnackBarType.error);
        })
        .whenComplete(() {
          _setLoading(false);
        });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final theme = Theme.of(context);
    return Column(
      spacing: 10,
      mainAxisSize: MainAxisSize.min,
      children: [
        _isLoading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
              )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 48,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.light ? Colors.blueGrey.shade800 : theme.textTheme.bodyLarge!.color,
                      ),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
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
                      decoration: const InputDecoration(labelText: 'Password', hintText: '••••••••', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please, introduce your password';
                        }
                        if (value.length < 6) {
                          return 'The password must be at least 6 characters long';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _isLoading ? null : _login(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          child: const Text('Don\'t have an account?', style: TextStyle(color: Colors.blueAccent)),
                          onPressed: () {
                            context.go(Routes.register);
                          },
                        ),

                        TextButton(
                          onPressed: () {
                            context.go(Routes.forgotPassword);
                          },
                          child: const Text('Forgot Password?', style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
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
                        child: Text('Login', style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.brightness == Brightness.light ? Colors.grey : null, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: const TextStyle(fontWeight: FontWeight.bold).copyWith(color: theme.brightness == Brightness.light ? Colors.grey : null),
                          ),
                        ),
                        Expanded(child: Divider(color: theme.brightness == Brightness.light ? Colors.grey : null, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: () async {
                          await AuthServices().signInWithJira();
                        },
                        child: Row(mainAxisSize: MainAxisSize.min, spacing: 10, children: [Image.asset('images/jira.png'), const Text('Login by JIRA')]),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}
