import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scrum_poker/shared/widgets/app_bar.dart';

class AuthPage extends StatelessWidget {
  final Widget child;
  const AuthPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const GiraffeAppBar(loginIn: true),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSize(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isSmallScreen ? screenSize.width * 0.9 : 450.0),
                    child: Column(
                      spacing: 10,
                      children: [
                        SvgPicture.asset('images/logo_dark_mode.svg', fit: BoxFit.contain, width: 140),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome Scrum Poker',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.light ? Colors.blueGrey.shade800 : theme.textTheme.bodyLarge!.color,
                          ),
                        ),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
