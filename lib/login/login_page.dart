import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/shared/helpers/credentials_helper.dart' as credentials_helper;
import 'package:scrum_poker/shared/managers/jira_credentials_manager.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/shared/widgets/app_bar.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

class LoginPage extends StatefulWidget {
  final String? authCode;
  const LoginPage({super.key, this.authCode});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _jiraServices = JiraServices();

  bool _isLoading = false;
  late JiraCredentialsManager jiraManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      jiraManager = JiraCredentialsManager();
      signInByJira();
    });
  }

  Future<void> signInByJira() async {
    if (widget.authCode == null) return;
    try {
      setState(() => _isLoading = true);

      //If we don't have an access token we need to get a new one.
      //After that we are check
      await accessToken(widget.authCode!);

      setState(() => _isLoading = false);
    } catch (e) {
      snackbarMessenger(navigatorKey.currentContext!, message: 'Error trying to connect to Jira: $e', type: SnackBarType.error);
      setState(() => _isLoading = false);
    }
  }

  Future<void> accessToken(String authCode) async {
    await _jiraServices
        .accessToken(authCode)
        .then((response) async {
          if (response.success && response.data != null) {
            await credentials_helper.getCredentials(response.data!);
            await AuthServices().signInWithCredentials(jiraManager.currentCredentials!.email!, jiraManager.currentCredentials!.avatarUrl!);
            navigatorKey.currentContext!.go(Routes.home);
          }
        })
        .catchError((error) {
          snackbarMessenger(navigatorKey.currentContext!, message: 'There was an error trying connect by Jira: $error', type: SnackBarType.error);
          return;
        });
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const GiraffeAppBar(loginIn: true),
      body: Center(
        child: AnimatedContainer(
          constraints: BoxConstraints(maxWidth: isSmallScreen ? screenSize.width * 0.9 : 450.0, maxHeight: _isLoading ? 400 : 800.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
          ),
          duration: const Duration(seconds: 2),
          curve: Curves.easeIn,
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_person, size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome Scrum Poker',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.light ? Colors.blueGrey.shade800 : theme.textTheme.bodyLarge!.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 48,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.light ? Colors.blueGrey.shade800 : theme.textTheme.bodyLarge!.color,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (_isLoading) ...[
                      const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                    ] else ...[
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined)
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
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                          prefixIcon:  Icon(Icons.lock_outline)
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
                            await AuthServices().signInWithJira(context);
                          },
                          child: const Text('Login by JIRA'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
