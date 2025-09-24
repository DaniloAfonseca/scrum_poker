import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/shared/helpers/credentials_helper.dart' as credentials_helper;
import 'package:scrum_poker/shared/managers/jira_credentials_manager.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/shared/widgets/bottom_bar.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

class RedirectPage extends StatefulWidget {
  final String? code;
  const RedirectPage({super.key, required this.code});

  @override
  State<RedirectPage> createState() => _RedirectPageState();
}

class _RedirectPageState extends State<RedirectPage> {
  final _jiraServices = JiraServices();
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
    if (widget.code == null) {
      navigatorKey.currentContext!.go(Routes.login);
      return;
    }
    try {
      //If we don't have an access token we need to get a new one.
      //After that we are check
      await accessToken(widget.code!);
    } catch (e) {
      snackbarMessenger(message: 'Error trying to connect to Jira: $e', type: SnackBarType.error);
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
          snackbarMessenger(message: 'There was an error trying connect by Jira: $error', type: SnackBarType.error);
          return;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            SvgPicture.asset('images/logo_dark_mode.svg', fit: BoxFit.contain, width: 140),
            const Text('Redirecting...'),
            const SmoothOrbitLoader(size: 60),
          ],
        ),
      ),
      bottomSheet: bottomBar(),
    );
  }
}

class SmoothOrbitLoader extends StatefulWidget {
  final double size;
  final int segments;
  final Duration duration;
  final Color color1;
  final Color color2;

  const SmoothOrbitLoader({
    super.key,
    this.size = 80,
    this.segments = 8,
    this.duration = const Duration(seconds: 1),
    this.color1 = Colors.blueAccent,
    this.color2 = Colors.blueGrey,
  });

  @override
  State<SmoothOrbitLoader> createState() => _SmoothOrbitLoaderState();
}

class _SmoothOrbitLoaderState extends State<SmoothOrbitLoader> with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(vsync: this, duration: widget.duration)..repeat();
    _controller2 = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  Widget _buildOrbit(Animation<double> animation, Color color, {bool clockwise = true, double tiltX = 0, double tiltY = 0, double delay = 0}) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = (animation.value + delay) % 1.0;
        final angle = progress * 2 * pi * (clockwise ? 1 : -1);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.005)
            ..rotateX(tiltX)
            ..rotateY(tiltY)
            ..rotateZ(angle),
          child: CustomPaint(size: Size(widget.size, widget.size), painter: _SegmentArcPainter(widget.segments, color)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildOrbit(_controller1, widget.color1, clockwise: true, tiltX: pi / 3),
          _buildOrbit(_controller2, widget.color2, clockwise: false, tiltY: pi / 3, delay: 0.4),
        ],
      ),
    );
  }
}

class _SegmentArcPainter extends CustomPainter {
  final int segments;
  final Color color;

  _SegmentArcPainter(this.segments, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius * 0.5);

    for (int i = 0; i < segments; i++) {
      final double startAngle = i * 2 * pi / segments;
      final double sweep = pi / 6;
      final double opacity = (i + 1) / segments;
      paint.color = color.withValues(alpha: opacity.clamp(0.3, 1.0));

      canvas.drawArc(rect, startAngle, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentArcPainter oldDelegate) => true;
}
