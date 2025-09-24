import 'package:flutter/widgets.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';

Row bottomBar() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('© 2025 Developed by: '),
    Hyperlink(text: 'Danilo Afonseca', url: 'https://www.linkedin.com/in/danilo-afonseca-44b88817/'),
    Text(' and '),
    Hyperlink(text: 'Alberto del Valle Sierra', url: 'https://www.linkedin.com/in/alberto-del-valle-sierra-4b0b623a/'),
  ],
);
