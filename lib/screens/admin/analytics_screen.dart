import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/web_downloader.dart';
import '../../providers/current_station_provider.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _dateRangeProvider = StateProvider<int>((ref) => 7); // 7 / 30 / 90

final _analyticsSnapshotProvider =
    FutureProvider.family<_AnalyticsSnapshot, int>((ref, days) async {
  final stationId = ref.read(currentStationIdProvider) ?? 'lion';
  final now = DateTime.now();
  final cutoffKey = DateFormat('yyyy-MM-dd')
      .format(now.subtract(Duration(days: days)));

  final snap = await FirebaseFirestore.instance
      .collection('analytics')
      .where('stationId', isEqualTo: stationId)
      .where('date', isGreaterThanOrEqualTo: cutoffKey)
      .orderBy('date')
      .get();

  final summarySnap = await FirebaseFirestore.instance
      .collection('analytics')
      .doc('summary')
      .get();

  return _AnalyticsSnapshot.fromFirestore(snap.docs, summarySnap, days, now);
});

// ─── Data models ──────────────────────────────────────────────────────────────

class _DailyMetrics {
  final String date;
  final String label;
  final double listeningHours;
  final int sessionStarts;
  final int peakConcurrent;
  final int uniqueListeners;
  final int premiumPurchases;
  final int eventTickets;
  final int webSessions;
  final int androidSessions;
  final int iosSessions;

  const _DailyMetrics({
    required this.date,
    required this.label,
    required this.listeningHours,
    required this.sessionStarts,
    required this.peakConcurrent,
    required this.uniqueListeners,
    required this.premiumPurchases,
    required this.eventTickets,
    required this.webSessions,
    required this.androidSessions,
    required this.iosSessions,
  });
}

class _AnalyticsSnapshot {
  final List<_DailyMetrics> days;
  final double totalListeningHours;
  final int totalSessions;
  final int cume;
  final int peakConcurrentPeriod;
  final int premiumUsers;
  final int freeUsers;
  final Map<String, int> platforms;
  final int totalPremiumPurchases;
  final int totalEventTickets;

  const _AnalyticsSnapshot({
    required this.days,
    required this.totalListeningHours,
    required this.totalSessions,
    required this.cume,
    required this.peakConcurrentPeriod,
    required this.premiumUsers,
    required this.freeUsers,
    required this.platforms,
    required this.totalPremiumPurchases,
    required this.totalEventTickets,
  });

  bool get hasData => days.any((d) =>
      d.listeningHours > 0 ||
      d.sessionStarts > 0 ||
      d.uniqueListeners > 0 ||
      d.premiumPurchases > 0 ||
      d.eventTickets > 0);

  factory _AnalyticsSnapshot.fromFirestore(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> dailyDocs,
    DocumentSnapshot<Map<String, dynamic>> summaryDoc,
    int numDays,
    DateTime now,
  ) {
    // Build lookup map: dateKey → doc data (skips meta docs like 'summary', 'live')
    final dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    final docMap = <String, Map<String, dynamic>>{};
    for (final doc in dailyDocs) {
      final data = doc.data();
      final key = data['date'] as String? ?? doc.id;
      if (dateRe.hasMatch(key)) docMap[key] = data;
    }

    // Generate zero-filled daily list from oldest → today
    final fmt = DateFormat('yyyy-MM-dd');
    final labelFmt = DateFormat('MM/dd');
    final dailyList = <_DailyMetrics>[];
    for (var i = numDays - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = fmt.format(date);
      final d = docMap[key] ?? {};
      final p = d['platforms'] as Map<String, dynamic>? ?? {};

      dailyList.add(_DailyMetrics(
        date: key,
        label: labelFmt.format(date),
        listeningHours:
            ((d['totalListeningSeconds'] as num?)?.toDouble() ?? 0) / 3600,
        sessionStarts: (d['sessionStarts'] as num?)?.toInt() ?? 0,
        peakConcurrent: (d['peakConcurrent'] as num?)?.toInt() ?? 0,
        uniqueListeners:
            (d['uniqueListenersCount'] as num?)?.toInt() ?? 0,
        premiumPurchases: (d['premiumPurchases'] as num?)?.toInt() ?? 0,
        eventTickets: (d['eventTickets'] as num?)?.toInt() ?? 0,
        webSessions: (p['web'] as num?)?.toInt() ?? 0,
        androidSessions: (p['android'] as num?)?.toInt() ?? 0,
        iosSessions: (p['ios'] as num?)?.toInt() ?? 0,
      ));
    }

    // Aggregate platforms across period
    final platforms = <String, int>{};
    for (final d in dailyList) {
      platforms['web'] = (platforms['web'] ?? 0) + d.webSessions;
      platforms['android'] = (platforms['android'] ?? 0) + d.androidSessions;
      platforms['ios'] = (platforms['ios'] ?? 0) + d.iosSessions;
    }
    // Fall back to summary breakdown if period has no per-day platform data
    if (platforms.values.every((v) => v == 0)) {
      final s = summaryDoc.data() ?? {};
      final raw = s['platformBreakdown'] as Map<String, dynamic>?;
      raw?.forEach((k, v) => platforms[k] = (v as num?)?.toInt() ?? 0);
    }

    final summary = summaryDoc.data() ?? {};
    return _AnalyticsSnapshot(
      days: dailyList,
      totalListeningHours:
          dailyList.fold(0.0, (sum, d) => sum + d.listeningHours),
      totalSessions:
          dailyList.fold(0, (sum, d) => sum + d.sessionStarts),
      cume: dailyList.fold(0, (sum, d) => sum + d.uniqueListeners),
      peakConcurrentPeriod: dailyList.fold(
          0,
          (best, d) =>
              d.peakConcurrent > best ? d.peakConcurrent : best),
      premiumUsers: (summary['premiumUsers'] as num?)?.toInt() ?? 0,
      freeUsers: (summary['freeUsers'] as num?)?.toInt() ?? 0,
      platforms: platforms,
      totalPremiumPurchases:
          dailyList.fold(0, (sum, d) => sum + d.premiumPurchases),
      totalEventTickets:
          dailyList.fold(0, (sum, d) => sum + d.eventTickets),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(_dateRangeProvider);
    final dataAsync = ref.watch(_analyticsSnapshotProvider(days));

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Analytics'),
        automaticallyImplyLeading: false,
        actions: [
          dataAsync.whenOrNull(
                data: (data) => Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 20),
                      tooltip: 'Export CSV',
                      onPressed: () => _exportCsv(data, days),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_rounded,
                          size: 20),
                      tooltip: 'Export PDF',
                      onPressed: () => _exportPdf(context, data, days),
                    ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: dataAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading analytics: $e',
              style: AppTextStyles.body),
        ),
        data: (data) => _AnalyticsBody(data: data, days: days),
      ),
    );
  }

  // ─── CSV export ─────────────────────────────────────────────────────────────

  void _exportCsv(_AnalyticsSnapshot data, int days) {
    final rows = <List<dynamic>>[
      ['Lion FM 91.1 MHz — Analytics Export — Last $days days'],
      [
        'Generated',
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())
      ],
      [],
      ['PERIOD SUMMARY'],
      ['Metric', 'Value'],
      [
        'Total Listening Hours',
        data.totalListeningHours.toStringAsFixed(2)
      ],
      ['Total Sessions', data.totalSessions],
      ['Cume Unique Listeners', data.cume],
      ['Peak Concurrent (period)', data.peakConcurrentPeriod],
      ['Premium Users (all-time)', data.premiumUsers],
      ['Premium Purchases (period)', data.totalPremiumPurchases],
      ['Event Tickets (period)', data.totalEventTickets],
      [],
      ['DAILY BREAKDOWN'],
      [
        'Date',
        'Listening Hours',
        'Sessions',
        'Peak Concurrent',
        'Unique Listeners',
        'Premium Purchases',
        'Event Tickets',
        'Web Sessions',
        'Android Sessions',
        'iOS Sessions',
      ],
      ...data.days.map((d) => [
            d.date,
            d.listeningHours.toStringAsFixed(3),
            d.sessionStarts,
            d.peakConcurrent,
            d.uniqueListeners,
            d.premiumPurchases,
            d.eventTickets,
            d.webSessions,
            d.androidSessions,
            d.iosSessions,
          ]),
      [],
      ['PLATFORM BREAKDOWN (PERIOD)'],
      ['Platform', 'Sessions'],
      ...data.platforms.entries.map((e) => [e.key, e.value]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    downloadTextFile(csv, 'lionfm_analytics_${days}d.csv');
  }

  // ─── PDF export ─────────────────────────────────────────────────────────────

  Future<void> _exportPdf(
      BuildContext context, _AnalyticsSnapshot data, int days) async {
    final pdf = pw.Document();
    final green = PdfColor.fromHex('1E9B43');
    final teal = PdfColor.fromHex('28D7D2');
    final gold = PdfColor.fromHex('C89A29');
    final h = _fmtHours(data.totalListeningHours);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('LION FM 91.1 MHz',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: green)),
                  pw.Text('Analytics Report — Last $days days',
                      style: pw.TextStyle(fontSize: 12, color: teal)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                      'Generated: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('www.lionfm.online',
                      style: pw.TextStyle(fontSize: 10, color: teal)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: green),
          pw.SizedBox(height: 16),

          // Period KPIs
          pw.Text('PERIOD SUMMARY',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: green)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _pdfRow(['Metric', 'Value'], isHeader: true),
              _pdfRow(['Total Listening Hours (TLH)', h]),
              _pdfRow(
                  ['Total Sessions', '${data.totalSessions}']),
              _pdfRow([
                'Cume Unique Listeners',
                '${data.cume}'
              ]),
              _pdfRow([
                'Peak Concurrent (period)',
                '${data.peakConcurrentPeriod}'
              ]),
              _pdfRow([
                'Premium Users (all-time)',
                '${data.premiumUsers}'
              ]),
              _pdfRow([
                'Premium Purchases (period)',
                '${data.totalPremiumPurchases}'
              ]),
              _pdfRow([
                'Event Tickets (period)',
                '${data.totalEventTickets}'
              ]),
            ],
          ),
          pw.SizedBox(height: 16),

          // Platform breakdown
          if (data.platforms.values.any((v) => v > 0)) ...[
            pw.Text('PLATFORM BREAKDOWN',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: teal)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _pdfRow(['Platform', 'Sessions'], isHeader: true),
                ...data.platforms.entries
                    .map((e) => _pdfRow([e.key, '${e.value}'])),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Daily breakdown
          pw.Text('DAILY BREAKDOWN',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: gold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _pdfRow(
                  ['Date', 'TLH', 'Sessions', 'Peak', 'Unique', '₦+'],
                  isHeader: true),
              ...data.days.map((d) => _pdfRow([
                    d.date,
                    _fmtHours(d.listeningHours),
                    '${d.sessionStarts}',
                    '${d.peakConcurrent}',
                    '${d.uniqueListeners}',
                    '${d.premiumPurchases + d.eventTickets}',
                  ])),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text(
            'Lion FM 91.1 MHz · University of Nigeria, Nsukka · Platform by iLLuSys LTD',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'lionfm_analytics_${days}d.pdf',
    );
  }

  pw.TableRow _pdfRow(List<String> cells, {bool isHeader = false}) {
    return pw.TableRow(
      decoration:
          isHeader ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  c,
                  style: isHeader
                      ? pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9)
                      : const pw.TextStyle(fontSize: 8),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _AnalyticsBody extends ConsumerWidget {
  final _AnalyticsSnapshot data;
  final int days;
  const _AnalyticsBody({required this.data, required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.p16),
      children: [
        _DateRangeSelector(selected: days),
        const SizedBox(height: AppDimensions.p16),
        _Card1TLH(data: data),
        _Card2SessionsPeak(data: data),
        _Card3Reach(data: data),
        _Card4Monetization(data: data),
        const SizedBox(height: AppDimensions.p32),
      ],
    );
  }
}

// ─── Date range selector ──────────────────────────────────────────────────────

class _DateRangeSelector extends ConsumerWidget {
  final int selected;
  const _DateRangeSelector({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [7, 30, 90].map((d) {
        final isSelected = d == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () =>
                ref.read(_dateRangeProvider.notifier).state = d,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient:
                    isSelected ? AppColors.greenTealGradient : null,
                color: isSelected ? null : AppColors.bg2,
                borderRadius:
                    BorderRadius.circular(AppDimensions.rFull),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.border1,
                ),
              ),
              child: Text(
                '${d}d',
                style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.bg0
                        : AppColors.textSecondary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Card 1: Total Listening Hours ────────────────────────────────────────────

class _Card1TLH extends StatelessWidget {
  final _AnalyticsSnapshot data;
  const _Card1TLH({required this.data});

  @override
  Widget build(BuildContext context) {
    final hours = data.totalListeningHours;
    final numDays = data.days.length;
    final avgDaily = numDays > 0 ? hours / numDays : 0.0;
    final avgSession = data.totalSessions > 0
        ? hours * 60 / data.totalSessions
        : 0.0;

    final maxH = data.days.fold(
        0.0, (m, d) => d.listeningHours > m ? d.listeningHours : m);
    final allZero = maxH == 0;

    final spots = data.days
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), e.value.listeningHours))
        .toList();

    final interval =
        _xInterval(data.days.length).toDouble();

    return _MetricCard(
      accentColor: AppColors.lionGreen,
      title: 'TOTAL LISTENING HOURS (TLH)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtHours(hours),
                style: AppTextStyles.heroTitle.copyWith(
                    color: AppColors.lionGreen, fontSize: 30),
              ),
              const Spacer(),
              _StatChip(
                  label: 'Avg/day',
                  value: _fmtHours(avgDaily)),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Avg session',
                  value: '${avgSession.toStringAsFixed(0)}m'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    maxY: allZero ? 1.0 : null,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border1, strokeWidth: 0.5),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: interval,
                          getTitlesWidget: (val, _) {
                            final i = val.toInt();
                            if (i < 0 ||
                                i >= data.days.length ||
                                val % interval != 0) {
                              return const SizedBox.shrink();
                            }
                            return Text(data.days[i].label,
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 9));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.lionGreen,
                        barWidth: 2,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.lionGreen.withValues(alpha: 0.25),
                              AppColors.lionGreen.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
                if (allZero) const _NoDataOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card 2: Sessions & Peak Concurrent ───────────────────────────────────────

class _Card2SessionsPeak extends StatelessWidget {
  final _AnalyticsSnapshot data;
  const _Card2SessionsPeak({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxSessions = data.days.fold(
        0, (m, d) => d.sessionStarts > m ? d.sessionStarts : m);
    final allSessionsZero = maxSessions == 0;

    final sessionGroups = data.days.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.sessionStarts.toDouble(),
            color: AppColors.lionGreen,
            width: data.days.length <= 7 ? 18 : (data.days.length <= 30 ? 6 : 3),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    final maxPeak = data.days.fold(
        0, (m, d) => d.peakConcurrent > m ? d.peakConcurrent : m);
    final allPeakZero = maxPeak == 0;
    final peakSpots = data.days
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), e.value.peakConcurrent.toDouble()))
        .toList();

    return _MetricCard(
      accentColor: AppColors.electricTeal,
      title: 'SESSIONS & PEAK CONCURRENT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatChip(
                  label: 'Sessions',
                  value: _fmtN(data.totalSessions),
                  color: AppColors.lionGreen),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Peak',
                  value: '${data.peakConcurrentPeriod}',
                  color: AppColors.lionGold),
            ],
          ),
          const SizedBox(height: 10),

          // Sessions bar chart
          _ChartLabel(text: 'DAILY SESSIONS'),
          const SizedBox(height: 4),
          SizedBox(
            height: 90,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    maxY: math.max(1.0, maxSessions.toDouble()),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: sessionGroups,
                    barTouchData: BarTouchData(enabled: false),
                  ),
                ),
                if (allSessionsZero) const _NoDataOverlay(),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Peak concurrent line chart
          _ChartLabel(text: 'PEAK CONCURRENT TREND'),
          const SizedBox(height: 4),
          SizedBox(
            height: 70,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    maxY: math.max(1.0, maxPeak.toDouble()),
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: peakSpots,
                        isCurved: true,
                        color: AppColors.lionGold,
                        barWidth: 2,
                        dashArray: [6, 4],
                        dotData: FlDotData(
                          show: data.days.length <= 14,
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                                  radius: 3,
                                  color: AppColors.lionGold,
                                  strokeWidth: 0),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              AppColors.lionGold.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
                if (allPeakZero) const _NoDataOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card 3: Audience Reach & Platforms ───────────────────────────────────────

class _Card3Reach extends StatelessWidget {
  final _AnalyticsSnapshot data;
  const _Card3Reach({required this.data});

  @override
  Widget build(BuildContext context) {
    final cume = data.cume;
    final platformTotal =
        data.platforms.values.fold(0, (s, v) => s + v);

    final platformOrder = ['web', 'android', 'ios'];
    final platformColors = {
      'web': AppColors.lionGold,
      'android': AppColors.lionGreen,
      'ios': AppColors.electricTeal,
    };
    final platformIcons = {
      'web': Icons.language_rounded,
      'android': Icons.android_rounded,
      'ios': Icons.phone_iphone_rounded,
    };

    return _MetricCard(
      accentColor: AppColors.electricTeal,
      title: 'AUDIENCE REACH & PLATFORMS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtN(cume),
                    style: AppTextStyles.heroTitle.copyWith(
                        color: AppColors.electricTeal, fontSize: 30),
                  ),
                  Text('cume unique listeners',
                      style: AppTextStyles.caption),
                ],
              ),
              const Spacer(),
              _StatChip(
                  label: 'Sessions',
                  value: _fmtN(data.totalSessions),
                  color: AppColors.electricTeal),
            ],
          ),
          const SizedBox(height: 16),
          _ChartLabel(text: 'PLATFORM BREAKDOWN'),
          const SizedBox(height: 8),
          if (platformTotal == 0)
            const _NoDataOverlay(height: 60)
          else
            ...platformOrder.map((key) {
              final count = data.platforms[key] ?? 0;
              final pct =
                  platformTotal > 0 ? count / platformTotal : 0.0;
              final color =
                  platformColors[key] ?? AppColors.textMuted;
              final icon = platformIcons[key] ?? Icons.devices_rounded;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 58,
                      child: Text(
                          key[0].toUpperCase() + key.substring(1),
                          style: AppTextStyles.caption),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.bg3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${(pct * 100).toStringAsFixed(1)}%',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Card 4: Monetization ─────────────────────────────────────────────────────

class _Card4Monetization extends StatelessWidget {
  final _AnalyticsSnapshot data;
  const _Card4Monetization({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalUsers = data.premiumUsers + data.freeUsers;
    final conversionRate =
        totalUsers > 0 ? data.premiumUsers / totalUsers * 100 : 0.0;

    final maxMonetization = data.days.fold(
        0,
        (m, d) => math.max(m,
            math.max(d.premiumPurchases, d.eventTickets)));
    final allMonZero = maxMonetization == 0;

    final groups = data.days.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        groupVertically: false,
        barsSpace: 2,
        barRods: [
          BarChartRodData(
            toY: e.value.premiumPurchases.toDouble(),
            color: AppColors.lionGreen,
            width: data.days.length <= 7 ? 8 : (data.days.length <= 30 ? 4 : 2),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(2)),
          ),
          BarChartRodData(
            toY: e.value.eventTickets.toDouble(),
            color: AppColors.lionGold,
            width: data.days.length <= 7 ? 8 : (data.days.length <= 30 ? 4 : 2),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    }).toList();

    return _MetricCard(
      accentColor: AppColors.lionGold,
      title: 'MONETIZATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${conversionRate.toStringAsFixed(1)}%',
                        style: AppTextStyles.heroTitle.copyWith(
                            color: AppColors.lionGold, fontSize: 30),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 6, bottom: 4),
                        child: Text('conversion',
                            style: AppTextStyles.caption),
                      ),
                    ],
                  ),
                  Text(
                    '${data.premiumUsers} premium of $totalUsers total users',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatChip(
                      label: '+Premium',
                      value: '+${data.totalPremiumPurchases}',
                      color: AppColors.lionGreen),
                  const SizedBox(height: 6),
                  _StatChip(
                      label: 'Tickets',
                      value: '${data.totalEventTickets}',
                      color: AppColors.lionGold),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ChartLabel(text: 'DAILY REVENUE EVENTS'),
          const SizedBox(height: 4),
          // Legend
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.lionGreen,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('Premium', style: AppTextStyles.caption),
              const SizedBox(width: 12),
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.lionGold,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('Tickets', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    maxY: math.max(
                        1.0, maxMonetization.toDouble()),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: groups,
                    barTouchData: BarTouchData(enabled: false),
                  ),
                ),
                if (allMonZero) const _NoDataOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widget helpers ────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final Color accentColor;
  final String title;
  final Widget child;
  const _MetricCard({
    required this.accentColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.p16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent strip
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.r16),
                topRight: Radius.circular(AppDimensions.r16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                      color: accentColor, letterSpacing: 1.2),
                ),
                const SizedBox(height: AppDimensions.p12),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(AppDimensions.rFull),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label,
              style: AppTextStyles.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  final String text;
  const _ChartLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted, letterSpacing: 1.0),
    );
  }
}

class _NoDataOverlay extends StatelessWidget {
  final double? height;
  const _NoDataOverlay({this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 24,
                color: AppColors.textMuted.withValues(alpha: 0.25)),
            const SizedBox(height: 4),
            Text('No data yet',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared format helpers ────────────────────────────────────────────────────

String _fmtHours(double hours) {
  if (hours <= 0) return '0m';
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String _fmtN(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

double _xInterval(int count) {
  if (count <= 7) return 1;
  if (count <= 30) return 5;
  return 14;
}
