import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/auth/presentation/providers/auth_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _moodReminders = true;
  bool _biofeedbackAlerts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive wellness reminders'),
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    _showNotificationUpdate(value ? 'enabled' : 'disabled');
                  },
                ),
                SwitchListTile(
                  title: const Text('Daily Mood Reminders'),
                  subtitle: const Text('Get reminded to track your mood'),
                  value: _moodReminders,
                  onChanged: (value) {
                    setState(() {
                      _moodReminders = value;
                    });
                    _showNotificationUpdate(value ? 'enabled' : 'disabled');
                  },
                ),
                SwitchListTile(
                  title: const Text('Biofeedback Alerts'),
                  subtitle: const Text('Heart rate and stress notifications'),
                  value: _biofeedbackAlerts,
                  onChanged: (value) {
                    setState(() {
                      _biofeedbackAlerts = value;
                    });
                    _showNotificationUpdate(value ? 'enabled' : 'disabled');
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Privacy Section
          const Text(
            'Privacy & Security',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showPrivacyPolicy();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Data Security'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showDataSecurity();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Account Section
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.support_outlined),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showHelpSupport();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    _showDeleteAccountDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationUpdate(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifications $status')),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This mental wellness app collects data only to improve your experience.\n\nWe do not share your personal information with third parties without your consent.\n\nData collected includes:\n• Mood tracking data\n• Usage analytics\n• Profile information\n\nYour data is encrypted and stored securely.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDataSecurity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Security'),
        content: const Text(
          'Your data is encrypted and stored securely. We use industry-standard security measures to protect your information.\n\n• End-to-end encryption\n• Secure cloud storage\n• Regular security audits\n• GDPR compliance',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@mentalwellness.com'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email client...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting live chat...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening FAQ...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Mental Wellness',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.psychology, size: 48, color: Colors.blue),
      children: const [
        Text('A comprehensive mental wellness app designed to help you track your mood, manage stress, and improve your overall mental health.'),
        SizedBox(height: 16),
        Text('Features include:'),
        Text('• Mood tracking and analysis'),
        Text('• Guided meditation'),
        Text('• Sleep tracking'),
        Text('• Stress management tools'),
        Text('• Progress monitoring'),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account?\n\nThis action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text('This will permanently delete your account and all associated data. Are you absolutely sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) => ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await authProvider.deleteAccount();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirm Delete'),
            ),
          ),
        ],
      ),
    );
  }
}
