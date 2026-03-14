import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text('Contact Us'),
            subtitle: Text('support@foodbridge.com'),
          ),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('FAQs'),
            subtitle: Text('Browse common questions'),
          ),
          ListTile(
            leading: Icon(Icons.bug_report_outlined),
            title: Text('Report an Issue'),
            subtitle: Text('Let us know if something went wrong'),
          ),
        ],
      ),
    );
  }
}
