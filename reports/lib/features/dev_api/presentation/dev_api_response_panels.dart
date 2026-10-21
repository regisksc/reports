import 'package:flutter/material.dart';

import 'package:reports/design/reports_design.dart';

class DevApiResponsePanels extends StatelessWidget {
  const DevApiResponsePanels({
    super.key,
    required this.statusLabel,
    required this.bodyText,
    required this.historyEntries,
  });

  final String statusLabel;
  final String bodyText;
  final List<String> historyEntries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: ReportsStyle.ink,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.6,
    );
    final headingStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(
          color: ReportsStyle.ink,
          fontWeight: FontWeight.w800,
          height: 1.3,
        );
    final codeStyle = bodyStyle.copyWith(
      fontFamily: 'monospace',
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.65,
    );
    final responseMaxHeight = (MediaQuery.sizeOf(context).height * .32)
        .clamp(110.0, 300.0)
        .toDouble();
    final panelBorder = Border.all(color: ReportsStyle.border, width: 2);
    final panelRadius = BorderRadius.circular(14);

    Widget heading(String title, double size) => Semantics(
      header: true,
      child: Text(title, style: headingStyle.copyWith(fontSize: size)),
    );

    Widget chip(String label) => Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ReportsStyle.surface,
        border: panelBorder,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        softWrap: true,
        style: codeStyle.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            heading('Actual response', 15),
            if (statusLabel.isNotEmpty)
              Semantics(liveRegion: true, child: chip(statusLabel)),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          label: 'Actual MyLA311 response',
          child: Container(
            constraints: BoxConstraints(
              minHeight: 110,
              maxHeight: responseMaxHeight,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ReportsStyle.surface,
              border: panelBorder,
              borderRadius: panelRadius,
            ),
            child: SingleChildScrollView(
              primary: false,
              child: SelectionArea(
                child: Text(
                  bodyText.isEmpty ? 'No response body to display.' : bodyText,
                  style: codeStyle,
                  softWrap: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'HTTP, Aura, and Portal errors are shown from the received response. '
          'Network failures may produce no HTTP response. '
          'HTTP 200 alone does not prove City acceptance.',
          style: bodyStyle,
        ),
        const SizedBox(height: 22),
        const Divider(height: 2, thickness: 2, color: ReportsStyle.border),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [heading('Request history', 17), chip('Memory only')],
        ),
        const SizedBox(height: 12),
        SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (historyEntries.isEmpty)
                Text('No request history yet.', style: bodyStyle),
              for (var index = 0; index < historyEntries.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: panelBorder,
                    borderRadius: panelRadius,
                  ),
                  child: Text(
                    historyEntries[index],
                    style: bodyStyle,
                    softWrap: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
