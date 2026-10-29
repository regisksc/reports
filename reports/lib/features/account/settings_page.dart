import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reports/features/report/data/remembered_contact_store.dart';
import 'package:reports/features/report/domain/report.dart';

import 'account_page.dart';
import 'help_page.dart';
import 'motion_preference_scope.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.reduceMotion,
    required this.onMotionChanged,
    this.onClearLocalData,
    this.showDemoUpdates = false,
  });
  final bool showDemoUpdates;
  final bool reduceMotion;
  final ValueChanged<bool> onMotionChanged;
  final Future<void> Function()? onClearLocalData;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ReportContact? contact;
  late bool motion;
  bool updates = false;
  bool updatesEdited = false;
  int loadGeneration = 0;
  Future<void>? pendingUpdates;
  bool savingUpdates = false;
  bool clearing = false;
  @override
  void initState() {
    super.initState();
    motion = widget.reduceMotion;
    _load();
  }

  ValueListenable<bool>? _motionSource;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final source = MotionPreferenceScope.maybeOf(context);
    if (source != _motionSource) {
      _motionSource?.removeListener(_syncMotion);
      _motionSource = source;
      _motionSource?.addListener(_syncMotion);
      if (source != null) motion = source.value;
    }
  }

  void _syncMotion() {
    if (mounted) setState(() => motion = _motionSource!.value);
  }

  @override
  void dispose() {
    _motionSource?.removeListener(_syncMotion);
    super.dispose();
  }

  void _changeMotion(bool value) {
    setState(() => motion = value);
    widget.onMotionChanged(value);
  }

  Future<void> _load() async {
    final generation = ++loadGeneration;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await const RememberedContactStore().load();
      if (mounted && generation == loadGeneration) {
        setState(() {
          contact = saved;
          if (!updatesEdited) {
            updates = prefs.getBool('reports_demo_updates_v1') ?? false;
          }
        });
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load settings.')),
        );
      }
    }
  }

  Future<void> _changeUpdates(bool value) async {
    final previous = updates;
    updatesEdited = true;
    setState(() {
      updates = value;
      savingUpdates = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool('reports_demo_updates_v1', value)) {
        throw StateError('Could not save preference');
      }
    } on Object {
      if (mounted) {
        setState(() => updates = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the preference. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => savingUpdates = false);
    }
  }

  Future<void> _forget() async {
    try {
      await const RememberedContactStore().clear();
      await _load();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not forget contact. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local preview data?'),
        content: const Text(
          'This removes local preview data and saved contact details. Real submissions, receipts and unconfirmed sends are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear preview data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    loadGeneration++;
    setState(() => clearing = true);
    try {
      await pendingUpdates;
      final prefs = await SharedPreferences.getInstance();
      await const RememberedContactStore().clear();
      if (!await prefs.remove('reports_local_profile_v1') ||
          !await prefs.remove('reports_demo_updates_v1')) {
        throw StateError('Could not clear preferences');
      }
      await widget.onClearLocalData?.call();
      if (mounted) {
        _changeMotion(false);
        setState(() => updates = false);
        updatesEdited = false;
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local preview data cleared.')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not clear all preview data. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => clearing = false);
    }
  }

  void _open(Widget page) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: page is AccountPage ? 'account' : null),
      builder: (_) => page,
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.showDemoUpdates ? 'Preferences' : 'Settings'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!widget.showDemoUpdates)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your account',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Sign in, manage your profile, or keep using Reports without an account.',
                    ),
                    OutlinedButton(
                      onPressed: () => _open(
                        AccountPage(
                          reduceMotion: motion,
                          onMotionChanged: _changeMotion,
                          onClearLocalData: widget.onClearLocalData,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Account'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            'Make yourself comfortable',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            widget.showDemoUpdates ? 'Preferences' : 'Settings',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Text('A few choices for this device.'),
          const SizedBox(height: 20),
          if (widget.showDemoUpdates)
            Card(
              child: ListTile(
                title: const Text('Accessibility'),
                subtitle: const Text(
                  'Use your device’s text size, keyboard navigation and reduced-motion settings.',
                ),
              ),
            ),
          if (widget.showDemoUpdates)
            Card(
              child: SwitchListTile(
                title: const Text('Updates for demo reports'),
                subtitle: const Text(
                  'Notifications are not sent in this preview.',
                ),
                value: updates,
                onChanged: savingUpdates || clearing
                    ? null
                    : (value) => pendingUpdates = _changeUpdates(value),
              ),
            ),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'Motion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Reduce motion'),
                  subtitle: const Text(
                    'Use fewer animations. Your device preference also applies.',
                  ),
                  value: motion,
                  onChanged: _changeMotion,
                ),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved contact details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    contact == null
                        ? 'Nothing remembered for future reports.'
                        : '${contact!.firstName} ${contact!.lastName} · ${contact!.email}',
                  ),
                  if (contact != null)
                    OutlinedButton(
                      onPressed: _forget,
                      child: const Text('Forget saved contact'),
                    ),
                  const Text(
                    'Forgetting these details does not change existing reports.',
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy & permissions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'Location is requested only when you choose to use it. Photos are optional. Your device manages permissions.',
                  ),
                  TextButton(
                    onPressed: () =>
                        _open(const HelpPage(initialArticle: 'permissions')),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text('About permissions')),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _open(const HelpPage(initialArticle: 'privacy')),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text('How local information is kept')),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data on this device',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'Clear local preview data and remembered contact. Real submissions and unconfirmed sends are kept.',
                  ),
                  OutlinedButton(
                    onPressed: _clear,
                    child: const Text('Clear local preview data'),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => _open(const HelpPage()),
            child: const Text('Help'),
          ),
        ],
      ),
    ),
  );
}
