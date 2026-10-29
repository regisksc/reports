import 'package:flutter/material.dart';
import '../account/account_page.dart';
import '../report/data/remembered_contact_store.dart';
import '../report/domain/report.dart';
import 'service_preview_store.dart';

class ServicePreviewPage extends StatefulWidget {
  const ServicePreviewPage({
    super.key,
    required this.service,
    this.draft,
    this.onIllegalDumping,
  });

  final Map<String, dynamic> service;
  final Map<String, dynamic>? draft;
  final VoidCallback? onIllegalDumping;

  @override
  State<ServicePreviewPage> createState() => _ServicePreviewPageState();
}

class _ServicePreviewPageState extends State<ServicePreviewPage> {
  int step = -1;
  String description = '';
  String address = '';
  String firstName = '';
  String lastName = '';
  String phone = '';
  bool remember = false;
  bool contactLoaded = false;
  String email = '';
  bool confirmed = false;
  bool? named;
  int photos = 0;
  String error = '';
  bool stored = true;
  late final String id;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    id =
        draft?['id'] as String? ??
        DateTime.now().microsecondsSinceEpoch.toString();
    if (draft != null) {
      step = draft['step'] as int;
      description = draft['description'] as String? ?? '';
      address = draft['address'] as String? ?? '';
      firstName = draft['firstName'] as String? ?? '';
      lastName = draft['lastName'] as String? ?? '';
      phone = draft['phone'] as String? ?? '';
      email = draft['email'] as String? ?? '';
      confirmed = draft['confirmed'] as bool? ?? false;
      named = draft['named'] as bool?;
      photos = draft['photos'] as int? ?? 0;
    }
    loadContact();
  }

  Future<void> loadContact() async {
    try {
      final contact = await const RememberedContactStore().load();
      if (contact != null &&
          firstName.isEmpty &&
          lastName.isEmpty &&
          email.isEmpty) {
        firstName = contact.firstName;
        lastName = contact.lastName;
        email = contact.email;
        phone = contact.phone;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => contactLoaded = true);
    }
  }

  String get evidence => widget.service['evidence'] as String;
  bool get contactRequired => evidence.contains('contact required');
  bool get accountRequired => evidence.contains('account required');
  bool get noPhotos => evidence.contains('no upload control');
  int? get photoLimit => int.tryParse(
    RegExp(r'advertised limit (\d+)').firstMatch(evidence)?.group(1) ?? '',
  );

  Future<bool> save() async {
    final data = <String, Object?>{
      'id': id,
      'service': widget.service['name'] as String,
      'group': widget.service['group'] as String,
      'evidence': evidence,
      'step': step,
      'description': description,
      'address': address,
      if (named == true || contactRequired) ...{
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
      },
      'confirmed': confirmed,
      'named': named,
      'photos': photos,
    };
    stored = await const ServicePreviewStore().save(data);
    if (mounted) setState(() {});
    return stored;
  }

  Future<void> advance() async {
    String problem = '';
    if (step == 0 && description.trim().isEmpty) {
      problem = 'Describe what needs attention.';
    }
    if (step == 1 && (!confirmed || address.trim().isEmpty)) {
      problem = 'Confirm the sample location.';
    }
    if (step == 2 && evidence.contains('required attachments') && photos == 0) {
      problem = 'Add sample evidence.';
    }
    if (step == 3 && (named == true || contactRequired) && !contactLoaded) {
      problem = 'Contact information is still loading.';
    }
    if (step == 3 && !contactRequired && named == null) {
      problem = 'Choose how to provide contact information.';
    }
    if (step == 3 &&
        (contactRequired || named == true) &&
        (firstName.trim().isEmpty ||
            lastName.trim().isEmpty ||
            !email.contains('@'))) {
      problem = 'Enter a name and valid email.';
    }
    if (problem.isEmpty &&
        step == 3 &&
        (named == true || contactRequired) &&
        remember) {
      try {
        await const RememberedContactStore().save(
          ReportContact(
            anonymous: false,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
          ),
        );
      } catch (_) {
        problem = 'Contact could not be saved on this device.';
      }
    }
    if (!mounted) return;
    setState(() {
      error = problem;
      if (problem.isEmpty) step++;
    });
    if (problem.isEmpty) save();
  }

  Widget input(String label, String initial, ValueChanged<String> update) =>
      TextFormField(
        initialValue: initial,
        decoration: InputDecoration(labelText: label),
        onChanged: (value) {
          update(value);
          save();
        },
      );

  @override
  Widget build(BuildContext context) {
    final title = widget.service['name'] as String;
    final content = <Widget>[
      if (step == -1) ...[
        const Text('Service information'),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        Text(widget.service['group'] as String),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Before you start'),
                Text(
                  accountRequired
                      ? 'A City account is required to request this service.'
                      : contactRequired
                      ? 'Your contact details are required for this service.'
                      : 'No account is needed to explore this report.',
                ),
                Text(
                  noPhotos
                      ? 'No photo is needed for this service.'
                      : evidence.contains('required attachments')
                      ? 'A photo is required for this service.'
                      : evidence.contains('optional attachments')
                      ? 'Photos are optional for this service.'
                      : 'Photo requirements are not confirmed.',
                ),
              ],
            ),
          ),
        ),
        Text(
          accountRequired
              ? 'No City account will be accessed. This is a local preview.'
              : widget.onIllegalDumping == null
              ? 'This is a local preview. No report is sent to the City.'
              : 'Continue to report illegal dumping to the City.',
        ),
        FilledButton(
          onPressed: () {
            if (accountRequired) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DemoSignInPage()),
              );
            } else if (widget.onIllegalDumping case final callback?) {
              Navigator.of(context).pop();
              callback();
            } else {
              setState(() => step = 0);
            }
          },
          child: Text(
            accountRequired
                ? 'Explore demo sign in'
                : widget.onIllegalDumping == null
                ? 'Start preview'
                : 'Start report',
          ),
        ),
      ],
      if (step == 0) ...[
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const Text('Example questions'),
        const Text(
          'These example questions illustrate the design. The live service may ask for more details.',
        ),
        input(
          'What needs attention?',
          description,
          (value) => description = value,
        ),
      ],
      if (step == 1) ...[
        const Text('Place it on the map.'),
        const Text(
          'Use an address or intersection. This sample pin stays in the preview.',
        ),
        input('Address or intersection', address, (value) {
          address = value;
          confirmed = false;
        }),
        OutlinedButton(
          onPressed: () {
            setState(() => confirmed = address.trim().isNotEmpty);
            save();
          },
          child: Text(confirmed ? 'Location confirmed' : 'Confirm sample pin'),
        ),
      ],
      if (step == 2) ...[
        const Text('A little more context.'),
        Text(
          noPhotos
              ? 'No photos are needed for this service.'
              : 'Sample evidence previews the design only. No photo is uploaded.',
        ),
        if (!noPhotos)
          OutlinedButton(
            onPressed: photoLimit != null && photos >= photoLimit!
                ? null
                : () {
                    setState(() => photos++);
                    save();
                  },
            child: const Text('Add sample evidence'),
          ),
        if (photos > 0) ...[
          Text('$photos sample evidence'),
          TextButton(
            onPressed: () {
              setState(() => photos--);
              save();
            },
            child: const Text('Remove sample evidence'),
          ),
        ],
      ],
      if (step == 3) ...[
        const Text('Contact'),
        if (!contactRequired)
          OutlinedButton(
            onPressed: () {
              setState(() => named = false);
              save();
            },
            child: const Text('Anonymous'),
          ),
        OutlinedButton(
          onPressed: () {
            setState(() => named = true);
            save();
          },
          child: const Text('Provide contact details'),
        ),
        if ((named == true || contactRequired) && !contactLoaded)
          const CircularProgressIndicator()
        else if (named == true || contactRequired) ...[
          input('First name', firstName, (value) => firstName = value),
          input('Last name', lastName, (value) => lastName = value),
          input('Email', email, (value) => email = value),
          input('Phone (optional)', phone, (value) => phone = value),
          CheckboxListTile(
            value: remember,
            onChanged: (value) => setState(() => remember = value ?? false),
            title: const Text('Remember contact on this device'),
          ),
        ],
      ],
      if (step == 4) ...[
        const Text('Review'),
        Text(description),
        Text(address),
        const Text('This preview is local and will not be sent to the City.'),
      ],
      if (step == 5) ...[
        const Text('Local receipt'),
        const Text('This preview was not sent to the City.'),
        Text(title),
      ],
      if (error.isNotEmpty) Text(error),
      if (!stored)
        const Text(
          'Local saving is unavailable. Your preview remains in this session.',
        ),
      if (step > 0 && step < 5)
        TextButton(
          onPressed: () {
            setState(() {
              step--;
              error = '';
            });
            save();
          },
          child: const Text('Back step'),
        ),
      if (step >= 0 && step < 5)
        FilledButton(
          onPressed: advance,
          child: Text(step == 4 ? 'Create local receipt' : 'Continue'),
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('New report'),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final saved = step < 0 || await save();
              if (!context.mounted) return;
              Navigator.pop(context);
              if (!saved) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Preview could not be saved. It remains in this session.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save and close'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (step >= 0) ...[
            Text(
              'Step ${step + 1} of 6 · ${['Details', 'Location', 'Photos', 'Contact', 'Review', 'Receipt'][step]}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (step + 1) / 6,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
              semanticsLabel: 'Report progress',
            ),
            const SizedBox(height: 28),
          ],
          for (final child in content)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
        ],
      ),
    );
  }
}
