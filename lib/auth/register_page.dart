import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      _setLoading(true);
    }

    AuthServices().auth
        .createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text)
        .then((credential) {
          if (credential.user != null) {
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

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    setState(() => _isLoading = isLoading);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Register',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 48,
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.light ? Colors.blueGrey.shade800 : theme.textTheme.bodyLarge!.color,
          ),
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
              )
            : Form(
                key: _formKey,
                child: Column(
                  spacing: 20,
                  children: [
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
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      onFieldSubmitted: !_isLoading ? (value) => _register() : null,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter new password',
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      onFieldSubmitted: !_isLoading ? (value) => _register() : null,
                      decoration: InputDecoration(
                        labelText: 'Verify password',
                        hintText: 'Confirm your new password',
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          elevation: 5,
                        ),
                        child: Text('Register', style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white)),
                      ),
                    ),
                    TextButton(
                      child: const Text('Do you have an account?', style: TextStyle(color: Colors.blueAccent)),
                      onPressed: () {
                        context.go(Routes.login);
                      },
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}
