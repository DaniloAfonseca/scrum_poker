import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Changes loading flag
  /// 
  /// [isLoading] value to update
  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    setState(() => _isLoading = isLoading);
  }

  /// Send password reset e-mail
  Future<void> _sendEmail() async {
    _setLoading(true);
    final message = await AuthServices().resetPassword(_emailController.text);
    bool isSuccess = false;
    if (message != null && message.isNotEmpty) {
      isSuccess = message.contains('We\'ve sent');
      snackbarMessenger(message: message, type: isSuccess ? SnackBarType.success : SnackBarType.error);
    }
    _setLoading(false);
    if (mounted && isSuccess) {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Forgot password',
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
          onFieldSubmitted: (value) async {
            await _sendEmail();
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              elevation: 5,
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Text('Login', style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          child: const Text('Back to login', style: TextStyle(color: Colors.blueAccent)),
          onPressed: () {
            context.go(Routes.login);
          },
        ),
      ],
    );
  }
}
