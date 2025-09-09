import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

class CreateNewPassword extends StatefulWidget {
  const CreateNewPassword({super.key});

  @override
  State<CreateNewPassword> createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  Timer? _debounce;

  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _createNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final newPassword = _passwordController.text;

    if (user != null) {
      try {
        await user.updatePassword(newPassword);

        if (mounted) {
          snackbarMessenger(message: 'Password update successfully', type: SnackBarType.success);
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'requires-recent-login') {
          errorMessage = 'Password not changed: should login again to update the password.';
        } else {
          errorMessage = 'Error trying update the password: ${e.message}';
        }
        // Show error message.
        if (mounted) {
          snackbarMessenger(message: errorMessage, type: SnackBarType.error);
        }
      } catch (e) {
        if (mounted) {
          snackbarMessenger(message: 'Unexpected error: ${e.toString()}', type: SnackBarType.error);
        }
      }
    } else {
      if (mounted) {
        snackbarMessenger(message: 'Not exist authenticated user.', type: SnackBarType.error);
      }
    }

    setState(() {
      _isLoading = false;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Text('${!user!.providerData.any((pd) => pd.providerId == 'password') ? 'Create new' : 'Update'} password'),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                onFieldSubmitted: !_isLoading ? (value) => _createNewPassword() : null,
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
                onFieldSubmitted: !_isLoading ? (value) => _createNewPassword() : null,
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
                onChanged: (value) {
                  if (_debounce?.isActive == true) {
                    _debounce?.cancel();
                  }
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _createNewPassword();
                    _debounce!.cancel();
                  });
                },
              ),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.grey.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
