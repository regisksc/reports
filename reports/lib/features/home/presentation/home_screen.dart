import 'package:reports/features/report/domain/submission_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reports/features/report/presentation/history_page.dart';
import 'package:reports/features/home/presentation/home_confirmation_card.dart';
import 'package:reports/features/home/presentation/report_delivery_scene.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/design/reports_design.dart';
import 'package:reports/features/report/domain/report.dart';
import 'package:reports/features/report/presentation/recovery_help_page.dart';
import 'package:reports/features/report/application/report_store.dart';

import '../application/home_resume.dart';
import 'accepted_home_hero.dart';
import '../../dev_api/presentation/dev_api_entry_button.dart';
import '../../report/presentation/report_detail_page.dart';
import '../../services/service_catalog_page.dart';
import '../../services/service_preview_store.dart';
import '../../account/settings_page.dart';
import '../../account/help_page.dart';
import '../../nearby/nearby_page.dart';
part 'home_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.client,
    required this.store,
    required this.reduceMotion,
    required this.onMotionChanged,
  });

  final SubmissionClient client;
  final ReportStore store;
  final bool reduceMotion;
  final ValueChanged<bool> onMotionChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeResume?> _homeResume = loadHomeResume(widget.store);
  Report? _confirmationReport;
  bool _confirmationVisible = false;
  final _homeScroll = ScrollController();
  final _heroKey = GlobalKey();
  Rect _heroBounds = Rect.zero;
  bool _delivering = false;

  @override
  void dispose() {
    _homeScroll.dispose();
    super.dispose();
  }

  void _finishDelivery() {
    if (mounted) {
      setState(() => _delivering = false);
    }
  }

  Future<void> _openReport([ReportDraft? draft]) async {
    final hero = _heroKey.currentContext?.findRenderObject();
    final scrollOffset = _homeScroll.hasClients ? _homeScroll.offset : 0.0;
    _heroBounds = hero is RenderBox && hero.hasSize
        ? (hero.localToGlobal(Offset.zero) & hero.size).shift(
            Offset(0, scrollOffset),
          )
        : Rect.zero;

    late final MaterialPageRoute<Report> route;
    route = MaterialPageRoute<Report>(
      builder: (_) => ReportFlowPage(
        store: widget.store,
        client: widget.client,
        draft: draft,
        onAccepted: (report) =>
            Navigator.of(context).removeRoute(route, report),
      ),
    );
    final accepted = await Navigator.push<Report>(context, route);
    final resume = await loadHomeResume(widget.store);
    if (mounted) {
      setState(() {
        _homeResume = SynchronousFuture(resume);
        if (accepted != null) {
          if (_homeScroll.hasClients) {
            _homeScroll.jumpTo(0);
          }
          _confirmationReport = accepted;
          _confirmationVisible = true;
          _delivering =
              !_heroBounds.isEmpty && !MediaQuery.disableAnimationsOf(context);
        }
      });
      if (accepted != null) {
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) {
          final target = _heroKey.currentContext?.findRenderObject();
          if (target is RenderBox && target.hasSize) {
            setState(() {
              _heroBounds = target.localToGlobal(Offset.zero) & target.size;
            });
          }
        }
      }
    }
  }

  Future<void> _openCatalog() async {
    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (catalogContext) => ServiceCatalogPage(
          onIllegalDumping: () => Navigator.pop(catalogContext, true),
        ),
      ),
    );
    if (selected == true && mounted) {
      await _openReport();
    }
  }

  Future<void> _openHistory() async {
    final startReport = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (historyContext) => HistoryPage(
          store: widget.store,
          client: widget.client,
          onStartReport: () => Navigator.pop(historyContext, true),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _homeResume = loadHomeResume(widget.store);
    });
    if (startReport == true) {
      await _openCatalog();
    }
  }

  Future<void> _clearPreviewData() async {
    final previewsCleared = await const ServicePreviewStore().clear();
    await NearbyPage.clearSavedFilters();
    if (!previewsCleared) throw StateError('Could not clear service previews');
  }

  Future<void> _openSettings() => Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SettingsPage(
        reduceMotion: widget.reduceMotion,
        onMotionChanged: widget.onMotionChanged,
        onClearLocalData: _clearPreviewData,
      ),
    ),
  );

  Future<void> _continueResume(HomeResume resume) async {
    final draft = resume.draft;
    if (draft != null) {
      await _openReport(draft);
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RecoveryHelpPage(report: resume.report!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: ReportsContinuationHint(
              child: SingleChildScrollView(
                controller: _homeScroll,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (reportsDevModeEnabled) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: devApiPill(
                                context,
                                store: widget.store,
                                key: const Key('home-dev-api-pill'),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: const _ReportsWordmark(),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: ReportsStyle.border,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: ReportsStyle.border,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                  color: Colors.white,
                                ),
                                child: IconButton(
                                  tooltip: 'Settings',
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    size: 22,
                                  ),
                                  onPressed: _openSettings,
                                ),
                              ),
                            ],
                          ),
                          FutureBuilder<HomeResume?>(
                            future: _homeResume,
                            builder: (context, snapshot) {
                              final resume = snapshot.data;
                              if (resume == null) {
                                return const SizedBox(height: 28);
                              }
                              return Column(
                                children: [
                                  const SizedBox(height: 24),
                                  _HomeResumeCard(
                                    resume: resume,
                                    onContinue: () => _continueResume(resume),
                                  ),
                                  const SizedBox(height: 28),
                                ],
                              );
                            },
                          ),
                          RepaintBoundary(
                            key: _heroKey,
                            child:
                                _confirmationReport != null &&
                                    !_heroBounds.isEmpty
                                ? AcceptedHomeHero(
                                    height: _heroBounds.height,
                                    onStartReport: _openCatalog,
                                  )
                                : Container(
                                    key: const Key('home-hero'),
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      27,
                                      24,
                                      25,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ReportsStyle.orange,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: ReportsStyle.orangeDark,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: ReportsStyle.orangeDark,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          width: 240,
                                          child: Text(
                                            'Report a problem.',
                                            style: TextStyle(
                                              fontSize: 35,
                                              height: 1.05,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          'Find a Los Angeles service and prepare your report.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.55,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.icon(
                                            style:
                                                ReportsStyle.raisedButtonStyle(
                                                  backgroundColor: Colors.white,
                                                  side: const BorderSide(
                                                    color:
                                                        ReportsStyle.orangeDark,
                                                    width: 2,
                                                  ),
                                                ),
                                            onPressed: _openCatalog,
                                            icon: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 20,
                                            ),
                                            iconAlignment: IconAlignment.end,
                                            label: const Text('Start a report'),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Center(
                                          child: Text(
                                            'Choose a service · Your progress stays here',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          if (_confirmationReport != null &&
                              _confirmationVisible) ...[
                            HomeConfirmationCard(
                              key: ValueKey(_confirmationReport!.createdAt),
                              serviceRequestNumber:
                                  _confirmationReport!.serviceRequestNumber!,
                              onViewReceipt: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportDetailPage(
                                    store: widget.store,
                                    report: _confirmationReport!,
                                  ),
                                ),
                              ),
                              onDismissed: () =>
                                  setState(() => _confirmationVisible = false),
                            ),
                            const SizedBox(height: 24),
                          ],
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _HomeAction(
                                    icon: Icons.location_on_outlined,
                                    title: 'Nearby reports',
                                    description: 'Explore your neighborhood',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NearbyPage(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _HomeAction(
                                    icon: Icons.inventory_2_outlined,
                                    title: 'View saved reports',
                                    description: 'Reports & receipts',
                                    onTap: _openHistory,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _HomeAction(
                                    icon: Icons.help_outline_rounded,
                                    title: 'Help and information',
                                    description: 'Guides & privacy',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HelpPage(store: widget.store),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'A few simple steps',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          for (final (index, title, description) in const [
                            (
                              '1',
                              'Choose the location',
                              'Use GPS at the dumping location.',
                            ),
                            (
                              '2',
                              'Describe the items',
                              'Add the quantity, placement, and a photo.',
                            ),
                            (
                              '3',
                              'Review your report',
                              'Check the details, then send to MyLA311.',
                            ),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: ReportsStyle.surface,
                                      border: Border.all(
                                        color: ReportsStyle.border,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      index,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          description,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Divider(height: 28),
                          Text(
                            'Report anonymously. Your saved reports stay on this device. Submitted details are sent to the City of Los Angeles.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_delivering)
            Positioned.fill(
              child: ReportDeliveryScene(
                heroBounds: _heroBounds,
                onComplete: _finishDelivery,
              ),
            ),
        ],
      ),
    );
  }
}
