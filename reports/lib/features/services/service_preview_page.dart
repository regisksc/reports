import 'package:flutter/material.dart';
import '../../design/reports_design.dart';
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

  Widget input(
    String label,
    String initial,
    ValueChanged<String> update, {
    int maxLines = 1,
  }) => TextFormField(
    initialValue: initial,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
    onChanged: (value) {
      update(value);
      save();
    },
  );

  void backStep() {
    setState(() {
      step--;
      error = '';
    });
    save();
  }

  Widget heading(String text) =>
      Text(text, style: Theme.of(context).textTheme.headlineMedium);

  Widget contactChoice({required bool anonymous}) {
    final selected = (contactRequired && !anonymous) || named == !anonymous;
    final border = selected ? ReportsStyle.orangeDark : ReportsStyle.border;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xfffff1d9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() => named = !anonymous);
            save();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xfffff1d9) : Colors.white,
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: border, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      anonymous ? Icons.shield_outlined : Icons.mail_outline,
                    ),
                    const Spacer(),
                    Icon(selected ? Icons.check_circle : Icons.circle_outlined),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  anonymous ? 'Anonymous' : 'Provide contact details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  anonymous
                      ? 'Keep your name and email out of this preview.'
                      : 'Add contact details to this local preview.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget contactChoices() => LayoutBuilder(
    builder: (context, constraints) {
      if (contactRequired) return contactChoice(anonymous: false);
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          children: [
            contactChoice(anonymous: true),
            const SizedBox(height: 12),
            contactChoice(anonymous: false),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: contactChoice(anonymous: true)),
          const SizedBox(width: 12),
          Expanded(child: contactChoice(anonymous: false)),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final title = widget.service['name'] as String;
    final content = <Widget>[
      if (step == -1) ...[
        const Text('Service information'),
        heading(title),
        Text(widget.service['group'] as String),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you start',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
        heading(title),
        Text(
          'Example questions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'These example questions illustrate the design. The live service may ask for more details.',
        ),
        input(
          'What needs attention?',
          description,
          (value) => description = value,
          maxLines: 4,
        ),
      ],
      if (step == 1) ...[
        heading('Place it on the map.'),
        const Text(
          'Use an address or intersection. This sample pin stays in the preview.',
        ),
        Card(
          color: ReportsStyle.surface,
          child: Semantics(
            label: 'Illustrative location pin, not a live map',
            child: const SizedBox(
              height: 150,
              child: Center(child: Icon(Icons.location_on_outlined, size: 48)),
            ),
          ),
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
        heading('A little more context.'),
        Card(
          color: ReportsStyle.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.camera_alt_outlined, size: 40),
                const SizedBox(height: 16),
                Text(
                  noPhotos
                      ? 'No photos are needed for this service.'
                      : evidence.contains('required attachments')
                      ? 'Photos are required for this service.'
                      : evidence.contains('optional attachments')
                      ? 'Photos are optional for this service.'
                      : 'Photo requirements are not confirmed.',
                  textAlign: TextAlign.center,
                ),
                if (!noPhotos)
                  const Text(
                    'Sample evidence previews the design only. No photo is uploaded.',
                    textAlign: TextAlign.center,
                  ),
                if (!noPhotos) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: photoLimit != null && photos >= photoLimit!
                        ? null
                        : () {
                            setState(() => photos++);
                            save();
                          },
                    child: const Text('Add sample evidence'),
                  ),
                ],
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
            ),
          ),
        ),
      ],
      if (step == 3) ...[
        heading('Contact'),
        const Text(
          'Choose how to provide contact information for this local preview.',
        ),
        contactChoices(),
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
        heading('Review'),
        const Text('This preview is local and will not be sent to the City.'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: Theme.of(context).textTheme.titleMedium),
                Text(description),
                const SizedBox(height: 16),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(address),
                const SizedBox(height: 16),
                Text('Photos', style: Theme.of(context).textTheme.titleMedium),
                Text('$photos sample evidence'),
                const SizedBox(height: 16),
                Text('Contact', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  named == true || contactRequired
                      ? '$firstName $lastName · $email${phone.isEmpty ? '' : ' · $phone'}'
                      : 'Anonymous',
                ),
              ],
            ),
          ),
        ),
      ],
      if (step == 5) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 44,
                  color: Color(0xff18703a),
                ),
                const SizedBox(height: 16),
                heading('Local receipt'),
                const SizedBox(height: 12),
                const Text('Local lookup ID'),
                Text(id, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text('This preview was not sent to the City.'),
                Text(title),
              ],
            ),
          ),
        ),
      ],
      if (error.isNotEmpty) Text(error),
      if (!stored)
        const Text(
          'Local saving is unavailable. Your preview remains in this session.',
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: step > 0 && step < 5 ? BackButton(onPressed: backStep) : null,
        title: Text(step < 0 ? 'Services' : 'New report'),
        actions: [
          if (step >= 0)
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final saved = await save();
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  Text(
                    [
                      'DETAILS',
                      'LOCATION',
                      'PHOTOS',
                      'CONTACT',
                      'REVIEW',
                      'RECEIPT',
                    ][step],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: ReportsStyle.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                KeyedSubtree(
                  key: Key('preview-section-$step'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final child in content)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: child,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: step >= 0 && step < 5
          ? SafeArea(
              top: false,
              child: Container(
                key: const Key('preview-action-footer'),
                padding: EdgeInsets.fromLTRB(
                  20,
                  13,
                  20,
                  12 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: ReportsStyle.border, width: 2),
                  ),
                ),
                child: FilledButton(
                  onPressed: advance,
                  child: Text(step == 4 ? 'Create local receipt' : 'Continue'),
                ),
              ),
            )
          : null,
    );
  }
}
