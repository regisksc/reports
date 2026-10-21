part of 'home_screen.dart';

class _InformationPage extends StatelessWidget {
  const _InformationPage({required this.store});
  final ReportStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(144),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'REPORTS · MYLA311',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    devApiPill(context, store: store),
                  ],
                ),
              ),
              AppBar(primary: false, title: const Text('Help')),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Good to know',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text('A little care makes a cleaner neighborhood.'),
              const SizedBox(height: 24),
              for (final (icon, title, description) in const [
                (
                  Icons.send_outlined,
                  'Reports go to MyLA311',
                  'Review every detail before you submit. This app sends real illegal dumping reports to the City of Los Angeles.',
                ),
                (
                  Icons.person_outline_rounded,
                  'No account needed',
                  'Reports are anonymous. Your location, description, item details, and any photo you add are sent to MyLA311.',
                ),
                (
                  Icons.photo_camera_outlined,
                  'Photos are optional',
                  'If it is safe, take a clear photo of the dumped items. Never put yourself at risk to make a report.',
                ),
                (
                  Icons.confirmation_number_outlined,
                  'Keep your Service Request number',
                  'Saved reports stay on this device. A submitted receipt confirms acceptance, not cleanup progress. If a submission is unconfirmed, check with 311 before sending again.',
                ),
              ])
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: ReportsStyle.orangeDark, size: 28),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(description),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeResumeCard extends StatelessWidget {
  const _HomeResumeCard({required this.resume, required this.onContinue});

  final HomeResume resume;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final draft = resume.draft;
    final report = resume.report;
    final location = draft == null
        ? _savedLocationSummary(report!.latitude, report.longitude)
        : _savedLocationSummary(draft.latitude, draft.longitude);
    final description = (draft?.description ?? report!.description).trim();
    final summary = description.isEmpty ? location : description;
    final detail = draft == null
        ? '$summary · Do not resend'
        : '$summary · Step ${draft.step.clamp(0, 4) + 1} of 5';
    final stateColor = draft == null
        ? ReportsStyle.orangeDark
        : ReportsStyle.ink;

    return Card(
      key: const Key('home-resume-card'),
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: stateColor.withAlpha(20),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ReportsStyle.border, width: 2),
              ),
              child: Text(
                draft == null ? 'UNCONFIRMED' : 'DRAFT',
                style: TextStyle(
                  color: stateColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue your report',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: ReportsStyle.muted),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onContinue,
              style: ReportsStyle.raisedButtonStyle(
                backgroundColor: Colors.white,
                side: const BorderSide(color: ReportsStyle.border, width: 2),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              iconAlignment: IconAlignment.end,
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

String _savedLocationSummary(double? latitude, double? longitude) =>
    latitude == null || longitude == null
    ? 'Location not added yet'
    : 'Location selected';

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0xffd7d7d7), offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ReportsStyle.border, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: ReportsStyle.ink),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
