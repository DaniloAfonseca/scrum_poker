import 'package:flutter/material.dart';

class RoomLogin extends StatefulWidget {
  final Function(String userName) login;
  final bool? isModerator;
  const RoomLogin({super.key, required this.login, this.isModerator = false});

  @override
  State<RoomLogin> createState() => _RoomLoginState();
}

class _RoomLoginState extends State<RoomLogin> {
  final TextEditingController _userNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      widget.login(_userNameController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
          constraints: BoxConstraints(maxWidth: isSmallScreen ? screenSize.width * 0.9 : 450.0, maxHeight: 800.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
          ),
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
                  Text(
                    widget.isModerator == true ? 'Choose a name' : 'Sign in',
                    style: TextStyle(fontSize: isSmallScreen ? 24 : 48, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _userNameController,
                    decoration: InputDecoration(
                      labelText: widget.isModerator == true ? 'Name' : 'Username',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please, introduce your username';
                      }
                      return null;
                    },
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
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
