import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text(
              'Your privacy is important to us. It is FoodBridge\'s policy to respect your '
              'privacy regarding any information we may collect from you across our application.\n\n'
              'We only ask for personal information when we truly need it to provide a service '
              'to you. We collect it by fair and lawful means, with your knowledge and consent.\n\n'
              'We don\'t share any personally identifying information publicly or with third-parties, '
              'except when required to by law.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
