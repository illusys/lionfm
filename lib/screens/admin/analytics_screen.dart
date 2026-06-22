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

// ─── Providers ───────────────────────────────────────────────────────────────

final _dateRangeProvider = StateProvider<int>((ref) => 7); // 7 / 30 / 90

final _analyticsDataProvider =
    FutureProvider.family<_AnalyticsData, int>((ref, days) async {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  final snap = await FirebaseFirestore.instance
      .collection('analytics')
      .where('date',
          isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(cutoff))
      .orderBy('date')
      .get();

  final summarySnap = await FirebaseFirestore.instance
      .collection('analytics')
      .doc('summary')
      .get();

  return _AnalyticsData.fromFirestore(snap.docs, summarySnap);
});

// ─── Data model ──────────────────────────────────────────────────────────────

class _DailyPoint {
  final String date;
  final int listeners;
  final int requests;

  const _DailyPoint(this.date, this.listeners, this.requests);
}

class _AnalyticsData {
  final List<_DailyPoint> daily;
  final int totalListeners;
  final int peakConcurrent;
  final int newUsers;
  final Map<String, double> platformBreakdown;
  final Map<String, int> topShows;
  final int premiumUsers;
  final int freeUsers;

  const _AnalyticsData({
    required this.daily,
    required this.totalListeners,
    required this.peakConcurrent,
    required this.newUsers,
    required this.platformBreakdown,
    required this.topShows,
    required this.premiumUsers,
    required this.freeUsers,
  });

  bool get isEmpty => daily.isEmpty && totalListeners == 0;

  factory _AnalyticsData.fromFirestore(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> dailyDocs,
    DocumentSnapshot<Map<String, dynamic>> summaryDoc,
  ) {
    final daily = dailyDocs.map((d) {
      final data = d.data();
      return _DailyPoint(
        data['date'] as String? ?? d.id,
        data['listeners'] as int? ?? 0,
        data['requests'] as int? ?? 0,
      );
    }).toList();

    final s = summaryDoc.data() ?? {};
    final platform = <String, double>{};
    final platformRaw = s['platformBreakdown'] as Map<String, dynamic>?;
    if (platformRaw != null) {
      platformRaw.forEach((k, v) => platform[k] = (v as num).toDouble());
    }

    final shows = <String, int>{};
    final showsRaw = s['topShows'] as Map<String, dynamic>?;
    if (showsRaw != null) {
      showsRaw.forEach((k, v) => shows[k] = (v as num).toInt());
    }

    return _AnalyticsData(
      daily: daily,
      totalListeners: s['totalListeners'] as int? ?? 0,
      peakConcurrent: s['peakConcurrent'] as int? ?? 0,
      newUsers: s['newUsers'] as int? ?? 0,
      platformBreakdown: platform,
      topShows: shows,
      premiumUsers: s['premiumUsers'] as int? ?? 0,
      freeUsers: s['freeUsers'] as int? ?? 0,
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(_dateRangeProvider);
    final dataAsync = ref.watch(_analyticsDataProvider(days));

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
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
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

  void _exportCsv(_AnalyticsData data, int days) {
    final rows = <List<dynamic>>[
      ['Lion FM Analytics Export — Last $days days'],
      ['Generated', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
      [],
      ['DAILY LISTENERS'],
      ['Date', 'Listeners', 'Requests'],
      ...data.daily.map((p) => [p.date, p.listeners, p.requests]),
      [],
      ['SUMMARY'],
      ['Metric', 'Value'],
      ['Total Listeners', data.totalListeners],
      ['Peak Concurrent', data.peakConcurrent],
      ['New Users', data.newUsers],
      ['Premium Users', data.premiumUsers],
      ['Free Users', data.freeUsers],
      [],
      ['PLATFORM BREAKDOWN'],
      ['Platform', 'Percentage'],
      ...data.platformBreakdown.entries
          .map((e) => [e.key, '${e.value.toStringAsFixed(1)}%']),
      [],
      ['TOP SHOWS'],
      ['Show', 'Listens'],
      ...data.topShows.entries.map((e) => [e.key, e.value]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    downloadTextFile(csv, 'lionfm_analytics_${days}d.csv');
  }

  Future<void> _exportPdf(
      BuildContext context, _AnalyticsData data, int days) async {
    final pdf = pw.Document();
    final greenColor = PdfColor.fromHex('1E9B43');
    final tealColor = PdfColor.fromHex('28D7D2');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
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
                          color: greenColor)),
                  pw.Text('Analytics Report — Last $days days',
                      style: pw.TextStyle(fontSize: 12, color: tealColor)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                      'Generated: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('www.lionfm.online',
                      style: pw.TextStyle(fontSize: 10, color: tealColor)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: greenColor),
          pw.SizedBox(height: 16),

          // Summary stats
          pw.Text('SUMMARY',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: greenColor)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _pdfTableRow(['Metric', 'Value'], isHeader: true),
              _pdfTableRow(['Total Listeners', '${data.totalListeners}']),
              _pdfTableRow(['Peak Concurrent', '${data.peakConcurrent}']),
              _pdfTableRow(['New Users', '${data.newUsers}']),
              _pdfTableRow(['Premium Users', '${data.premiumUsers}']),
              _pdfTableRow(['Free Users', '${data.freeUsers}']),
            ],
          ),
          pw.SizedBox(height: 16),

          // Daily data
          if (data.daily.isNotEmpty) ...[
            pw.Text('DAILY BREAKDOWN',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: greenColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _pdfTableRow(['Date', 'Listeners', 'Requests'], isHeader: true),
                ...data.daily.map((p) => _pdfTableRow([
                      p.date,
                      '${p.listeners}',
                      '${p.requests}',
                    ])),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Platform breakdown
          if (data.platformBreakdown.isNotEmpty) ...[
            pw.Text('PLATFORM BREAKDOWN',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: greenColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _pdfTableRow(['Platform', 'Share'], isHeader: true),
                ...data.platformBreakdown.entries.map((e) => _pdfTableRow([
                      e.key,
                      '${e.value.toStringAsFixed(1)}%',
                    ])),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Top shows
          if (data.topShows.isNotEmpty) ...[
            pw.Text('TOP SHOWS',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: greenColor)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _pdfTableRow(['Show', 'Listens'], isHeader: true),
                ...data.topShows.entries.map((e) =>
                    _pdfTableRow([e.key, '${e.value}'])),
              ],
            ),
          ],

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

  pw.TableRow _pdfTableRow(List<String> cells, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader
          ? const pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  c,
                  style: isHeader
                      ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)
                      : const pw.TextStyle(fontSize: 9),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Body widget ─────────────────────────────────────────────────────────────

class _AnalyticsBody extends ConsumerWidget {
  final _AnalyticsData data;
  final int days;
  const _AnalyticsBody({required this.data, required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.p16),
      children: [
        // Date range selector
        _DateRangeSelector(selected: days),
        const SizedBox(height: AppDimensions.p16),

        if (data.isEmpty) ...[
          const _EmptyState(),
        ] else ...[
          // Stat cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _StatCard(
                  label: 'Total Listeners',
                  value: _fmt(data.totalListeners),
                  color: AppColors.lionGreen),
              _StatCard(
                  label: 'Peak Concurrent',
                  value: _fmt(data.peakConcurrent),
                  color: AppColors.electricTeal),
              _StatCard(
                  label: 'New Users',
                  value: _fmt(data.newUsers),
                  color: AppColors.lionGold),
              _StatCard(
                  label: 'Premium',
                  value: _fmt(data.premiumUsers),
                  color: AppColors.burntAmber),
            ],
          ),
          const SizedBox(height: AppDimensions.p24),

          // Listeners over time line chart
          if (data.daily.isNotEmpty) ...[
            Text('LISTENERS OVER TIME', style: AppTextStyles.label),
            const SizedBox(height: AppDimensions.p12),
            _LineChartCard(data: data, days: days),
            const SizedBox(height: AppDimensions.p24),
          ],

          // Top shows bar chart
          if (data.topShows.isNotEmpty) ...[
            Text('TOP SHOWS BY LISTENS', style: AppTextStyles.label),
            const SizedBox(height: AppDimensions.p12),
            _TopShowsBarChart(shows: data.topShows),
            const SizedBox(height: AppDimensions.p24),
          ],

          // Platform breakdown
          if (data.platformBreakdown.isNotEmpty) ...[
            Text('PLATFORM BREAKDOWN', style: AppTextStyles.label),
            const SizedBox(height: AppDimensions.p12),
            _PlatformBreakdown(data: data.platformBreakdown),
            const SizedBox(height: AppDimensions.p24),
          ],

          // Premium vs free donut
          if (data.premiumUsers + data.freeUsers > 0) ...[
            Text('PREMIUM VS FREE', style: AppTextStyles.label),
            const SizedBox(height: AppDimensions.p12),
            _PremiumDonut(premium: data.premiumUsers, free: data.freeUsers),
            const SizedBox(height: AppDimensions.p24),
          ],

          // Song requests bar chart
          if (data.daily.any((d) => d.requests > 0)) ...[
            Text('SONG REQUESTS VOLUME', style: AppTextStyles.label),
            const SizedBox(height: AppDimensions.p12),
            _RequestsBarChart(data: data.daily),
            const SizedBox(height: AppDimensions.p24),
          ],
        ],
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ─── Date range selector ─────────────────────────────────────────────────────

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.greenTealGradient : null,
                color: isSelected ? null : AppColors.bg2,
                borderRadius: BorderRadius.circular(AppDimensions.rFull),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.border1,
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

// ─── Charts & Cards ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final _AnalyticsData data;
  final int days;
  const _LineChartCard({required this.data, required this.days});

  @override
  Widget build(BuildContext context) {
    final spots = data.daily.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.listeners.toDouble());
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border1, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (val, _) =>
                    Text('${val.toInt()}', style: AppTextStyles.caption),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (data.daily.length / 6).ceilToDouble(),
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= data.daily.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    data.daily[i].date.substring(5), // MM-dd
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                color: AppColors.lionGreen.withValues(alpha: 0.1),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopShowsBarChart extends StatelessWidget {
  final Map<String, int> shows;
  const _TopShowsBarChart({required this.shows});

  @override
  Widget build(BuildContext context) {
    final sorted = shows.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final maxVal = top.isEmpty ? 1.0 : top.first.value.toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        children: top.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = maxVal > 0 ? e.value / maxVal : 0.0;
          final colors = [
            AppColors.lionGreen,
            AppColors.electricTeal,
            AppColors.lionGold,
            AppColors.burntAmber,
            AppColors.liveRed,
          ];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    e.key,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.bg3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          colors[i % colors.length]),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value}', style: AppTextStyles.caption),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PlatformBreakdown extends StatelessWidget {
  final Map<String, double> data;
  const _PlatformBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'android': AppColors.lionGreen,
      'ios': AppColors.electricTeal,
      'web': AppColors.lionGold,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        children: data.entries.map((e) {
          final color = colors[e.key.toLowerCase()] ?? AppColors.burntAmber;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                    width: 70,
                    child: Text(e.key, style: AppTextStyles.caption)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: e.value / 100,
                      backgroundColor: AppColors.bg3,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PremiumDonut extends StatelessWidget {
  final int premium;
  final int free;
  const _PremiumDonut({required this.premium, required this.free});

  @override
  Widget build(BuildContext context) {
    final total = premium + free;
    final premiumPct = total > 0 ? premium / total * 100 : 0.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: premium.toDouble(),
                    color: AppColors.lionGreen,
                    title: 'P',
                    radius: 30,
                    titleStyle: AppTextStyles.caption
                        .copyWith(color: AppColors.bg0),
                  ),
                  PieChartSectionData(
                    value: free.toDouble(),
                    color: AppColors.bg3,
                    title: 'F',
                    radius: 30,
                    titleStyle: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    color: AppColors.lionGreen),
                const SizedBox(width: 6),
                Text('Premium: $premium (${premiumPct.toStringAsFixed(1)}%)',
                    style: AppTextStyles.caption),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                    width: 10, height: 10, color: AppColors.bg3),
                const SizedBox(width: 6),
                Text(
                    'Free: $free (${(100 - premiumPct).toStringAsFixed(1)}%)',
                    style: AppTextStyles.caption),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestsBarChart extends StatelessWidget {
  final List<_DailyPoint> data;
  const _RequestsBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final groups = data.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.requests.toDouble(),
            color: AppColors.electricTeal,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border1, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (val, _) =>
                    Text('${val.toInt()}', style: AppTextStyles.caption),
              ),
            ),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: groups,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Awaiting live data',
                style: AppTextStyles.h3
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text(
              'Analytics will appear here once your app\nbegins collecting listener data.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
