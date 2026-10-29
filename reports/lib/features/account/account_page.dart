import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'help_page.dart';
import 'settings_page.dart';
import 'motion_preference_scope.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.reduceMotion,
    required this.onMotionChanged,
    this.onClearLocalData,
  });
  final bool reduceMotion;
  final ValueChanged<bool> onMotionChanged;
  final Future<void> Function()? onClearLocalData;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late bool motion;
  @override
  void initState() {
    super.initState();
    motion = widget.reduceMotion;
  }

  void _changeMotion(bool value) {
    setState(() => motion = value);
    widget.onMotionChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    final accountRoute = ModalRoute.of(context);
    void returnToAccount() =>
        Navigator.of(context).popUntil((route) => route == accountRoute);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your account',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const Text(
              'Explore account tools without connecting to a City account.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo account',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Sign in, registration and profile changes are simulated locally.',
                    ),
                    FilledButton(
                      onPressed: () => open(
                        _AccountForm(mode: 'signin', onSaved: returnToAccount),
                      ),
                      child: const Text('Sign in to demo'),
                    ),
                    OutlinedButton(
                      onPressed: () => open(
                        _AccountForm(
                          mode: 'register',
                          onSaved: returnToAccount,
                        ),
                      ),
                      child: const Text('Create demo account'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(
                  _AccountForm(mode: 'profile', onSaved: returnToAccount),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Preferences & accessibility'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(
                  SettingsPage(
                    reduceMotion:
                        MotionPreferenceScope.maybeOf(context)?.value ?? motion,
                    showDemoUpdates: true,
                    onMotionChanged: _changeMotion,
                    onClearLocalData: widget.onClearLocalData,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Help'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(const HelpPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoSignInPage extends StatelessWidget {
  const DemoSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    return _AccountForm(
      mode: 'signin',
      backLabel: 'Back to service',
      onSaved: () {
        final navigator = Navigator.of(context);
        navigator.popUntil((item) => item == route);
        navigator.pop();
      },
    );
  }
}

class _AccountForm extends StatefulWidget {
  const _AccountForm({
    required this.mode,
    required this.onSaved,
    this.backLabel = 'Account',
  });
  final String mode;
  final VoidCallback onSaved;
  final String backLabel;
  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String? message;
  @override
  void initState() {
    super.initState();
    if (widget.mode == 'profile') _load();
  }

  bool edited = false;
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('reports_local_profile_v1');
      if (raw == null || !mounted || edited) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      name.text = data['name'] as String? ?? '';
      email.text = data['email'] as String? ?? '';
    } on Object {
      if (mounted) setState(() => message = 'Could not load the demo profile.');
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    if (widget.mode == 'recovery') {
      setState(() => message = 'Demo only: no email was sent.');
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getString('reports_local_profile_v1');
      final data = old == null
          ? <String, dynamic>{}
          : jsonDecode(old) as Map<String, dynamic>;
      if (widget.mode != 'signin') data['name'] = name.text.trim();
      data['email'] = email.text.trim();
      if (!await prefs.setString(
        'reports_local_profile_v1',
        jsonEncode(data),
      )) {
        throw StateError('Could not save profile');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demo profile saved locally. No City account was changed.',
            ),
          ),
        );
        widget.onSaved();
      }
    } on Object {
      if (mounted) {
        setState(
          () => message = 'Could not save the demo profile. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final title = switch (mode) {
      'signin' => 'Sign in',
      'register' => 'Create a demo account',
      'recovery' => 'Recover access',
      _ => 'Profile',
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: mode == 'recovery'
                    ? () => Navigator.pop(context)
                    : widget.onSaved,
                icon: const Icon(Icons.arrow_back),
                label: Text(mode == 'recovery' ? 'Sign in' : widget.backLabel),
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            Text(switch (mode) {
              'signin' => 'Demo only. Do not enter a real password.',
              'register' => 'No real account will be created.',
              'recovery' => 'This preview does not send recovery emails.',
              _ => 'These details are saved only on this device.',
            }),
            const SizedBox(height: 16),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mode == 'register' || mode == 'profile') ...[
                    Text(
                      mode == 'profile' ? 'Display name' : 'Name',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      label: mode == 'profile' ? 'Display name' : 'Name',
                      child: TextFormField(
                        controller: name,
                        onChanged: (_) => edited = true,
                        decoration: const InputDecoration(),
                        validator: (value) =>
                            mode == 'register' &&
                                (value == null || value.trim().isEmpty)
                            ? 'Enter a name'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    label: 'Email',
                    child: TextFormField(
                      controller: email,
                      onChanged: (_) => edited = true,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(),
                      validator: (value) =>
                          mode != 'profile' &&
                              (value == null || value.trim().isEmpty)
                          ? 'Enter an email'
                          : null,
                    ),
                  ),
                  if (mode == 'signin') ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Demo password',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      label: 'Demo password',
                      child: TextFormField(
                        controller: password,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: const InputDecoration(),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter a demo password'
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(switch (mode) {
                      'signin' => 'Continue in demo',
                      'register' => 'Create local profile',
                      'recovery' => 'Preview recovery',
                      _ => 'Save demo profile',
                    }),
                  ),
                ],
              ),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(message!),
              ),
            if (mode == 'signin')
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => _AccountForm(
                          mode: 'recovery',
                          onSaved: widget.onSaved,
                          backLabel: widget.backLabel,
                        ),
                      ),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => _AccountForm(
                          mode: 'register',
                          onSaved: widget.onSaved,
                          backLabel: widget.backLabel,
                        ),
                      ),
                    ),
                    child: const Text('Create account'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
