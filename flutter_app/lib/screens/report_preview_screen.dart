import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Report Preview — screen 05 kebab: "Download Report" / "Download Critical
/// Report". Mirrors #page-report-preview / openReportPreview() in
/// prototype.html: farm name, report-type label, generated-on date, a Summary
/// stat grid (full report adds Critical Alerts + Pending Approvals; critical
/// report shows only Critical Alerts + an italic note), and a sticky Download
/// button that toasts "Report downloaded".
///
/// Every value below is measured off the live prototype via getComputedStyle,
/// never read off the inline markup (later CSS overrides the inline styles —
/// e.g. `#flow-root.dark .m-hero` forces #1C1C1C over `background:var(--bgwarm)`).
class ReportPreviewScreen extends StatelessWidget {
  final AppState appState;
  final FarmModel farm;
  final bool critical;
  const ReportPreviewScreen({super.key, required this.appState, required this.farm, required this.critical});

  @override
  Widget build(BuildContext context) {
    final lang = appState.languageCode;
    final isDark = appState.isDark;
    // #flow-root.dark .m-hero h2 => #F5F5F5 (not pure white); light => --text1.
    final heroTextColor = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
    final levelKey = farmTempLevelKey(farm.temp);
    final levelColor = switch (levelKey) {
      'tempVeryHigh' => VanixColors.danger,
      'tempHigh' => VanixColors.warningInk,
      'tempNormal' => VanixColors.greenInk,
      _ => VanixColors.textHint,
    };
    // new Date('2026-07-22T09:41:00').toDateString() => "Wed Jul 22 2026".
    final now = DateTime(2026, 7, 22, 9, 41);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final generatedOn =
        '${weekdays[now.weekday - 1]} ${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')} ${now.year}';

    final stats = <Widget>[
      _stat(FS.t(lang, 'statTotalCattle'), '${farm.cattle}', const Color(0xFF111111)),
      _stat(FS.t(lang, levelKey), appState.fmtTemp(farm.temp), levelColor),
      if (critical)
        _stat(FS.t(lang, 'rowCriticalAlerts'), '3', VanixColors.danger)
      else ...[
        _stat(FS.t(lang, 'rowCriticalAlerts'), '14', VanixColors.danger),
        _stat(FS.t(lang, 'rowPendingApprovals'), '2', const Color(0xFF111111)),
      ],
    ];

    return Scaffold(
      // #page-report-preview background:var(--bgwarm) — light #F2EDE4.
      backgroundColor: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            // ── .m-hero: padding 14px 16px, radius 0 0 14 14 ──
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: isDark ? VanixColors.darkSecond : VanixColors.bgWarm,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      FS.t(lang, 'reportPreviewTitle'),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: heroTextColor),
                    ),
                  ),
                  // hero row gap: 10px
                  const SizedBox(width: 10),
                  // #report-preview-back: 36x36 circle, background var(--bgcard);
                  // dark adds box-shadow 0 2px 6px rgba(0,0,0,0.4).
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
                      shape: BoxShape.circle,
                      boxShadow: isDark
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, size: 18, color: heroTextColor),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                // Doc wrapper padding 16; the scroller adds padding-bottom 96
                // behind a 76px-tall absolute footer => 16 + (96 - 76) = 36.
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── #report-preview-doc: a printed sheet — stays #FFFFFF
                    // with #111/#666/#999/#888 ink in dark mode too. ──
                    Container(
                      padding: const EdgeInsetsDirectional.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
                        borderRadius: BorderRadius.circular(16),
                        // 0 4px 16px rgba(0,0,0,0.06), 0 1px 3px rgba(0,0,0,0.04)
                        // — measured identical in dark mode, so the dark card
                        // shadow token must not be substituted here.
                        boxShadow: VanixShadow.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(farm.nm(lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                          const SizedBox(height: 4),
                          Text(
                            FS.t(lang, critical ? 'criticalReport' : 'fullReport'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.danger),
                          ),
                          // "Generated on <date>" — 11px #666. Neither span
                          // carries class="en", so both keep the Devanagari face.
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: 4, bottom: 14),
                            child: Text(
                              '${FS.t(lang, 'reportGeneratedOn')} $generatedOn',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                            ),
                          ),
                          Container(height: 1, color: isDark ? VanixColors.darkDivider : VanixColors.divider),
                          const SizedBox(height: 14),
                          // SUMMARY — 11px/700, letter-spacing .05em = 0.55px.
                          Text(
                            FS.t(lang, 'reportSummaryWord').toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.55, color: Color(0xFF999999)),
                          ),
                          const SizedBox(height: 8),
                          // #report-preview-stats — flex-wrap with flex:1 /
                          // min-width:100px children: at 301px of inner width
                          // that packs exactly 2 per row at (301-10)/2 = 145.5
                          // each, and an odd final tile grows to the full 301.
                          _statGrid(stats),
                          if (critical)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 14),
                              child: Text(
                                FS.t(lang, 'reportCriticalOnlyNote'),
                                style: const TextStyle(fontSize: 12, color: VanixColors.danger, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Sticky footer: padding 12/16/16, box-shadow 0 -8px 20px
            // rgba(0,0,0,0.08) (unchanged in dark). ──
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -8))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VanixColors.greenInk,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => _toast(context, FS.t(lang, 'reportDownloaded')),
                  child: Text(FS.t(lang, 'downloadWord'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// #vanix-toast — #111111 pill, 13px/600 white, padding 10px 18px,
  /// radius 20, shadow 0 8px 20px rgba(0,0,0,0.3), visible 2200ms.
  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: VanixColors.darkPrimary,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  Widget _statGrid(List<Widget> stats) {
    return LayoutBuilder(
      builder: (context, c) {
        final full = c.maxWidth;
        final half = (full - 10) / 2;
        final rows = <Widget>[];
        for (var i = 0; i < stats.length; i += 2) {
          final lone = i + 1 >= stats.length;
          rows.add(Padding(
            // wrap row-gap: 10px
            padding: EdgeInsetsDirectional.only(bottom: i + 2 < stats.length ? 10 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: lone ? full : half, child: stats[i]),
                  if (!lone) ...[
                    const SizedBox(width: 10),
                    SizedBox(width: half, child: stats[i + 1]),
                  ],
                ],
              ),
            ),
          ));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
      },
    );
  }

  /// One Summary tile: #F7F5F0 / radius 12 / padding 10px 12px, an 18px/700
  /// value and a 10px/600 uppercase #888 label with letter-spacing .04em.
  Widget _stat(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF7F5F0), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF888888), letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}
