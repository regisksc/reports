part of 'home_screen.dart';

class _ReportsWordmark extends StatelessWidget {
  const _ReportsWordmark();

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('reports-brand-logo'),
    label: 'Reports',
    image: true,
    excludeSemantics: true,
    child: SizedBox(
      width: 150,
      height: 42,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 34,
              decoration: BoxDecoration(
                color: ReportsStyle.orange,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: ReportsStyle.orangeDark,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: ReportsStyle.ink,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'reports.',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'Mona Sans',
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
    final step = draft != null && draft.flowVersion < 2 && draft.step >= 4
        ? 5
        : draft?.step ?? 0;
    final detail = draft == null
        ? '$summary · Do not resend'
        : '$summary · Step ${step.clamp(0, 5) + 1} of 6';
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ReportsStyle.surface,
                    border: Border.all(color: ReportsStyle.border, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 28, color: ReportsStyle.ink),
                ),
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
