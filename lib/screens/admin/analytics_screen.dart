import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('Analytics'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // Stat cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: const [
              _StatCard(label: 'Total Listeners', value: '18,450', color: AppColors.lionGreen),
              _StatCard(label: 'Avg Session', value: '24 min', color: AppColors.electricTeal),
              _StatCard(label: 'New Users', value: '1,230', color: AppColors.lionGold),
              _StatCard(label: 'Retention', value: '68%', color: AppColors.burntAmber),
            ],
          ),
          const SizedBox(height: AppDimensions.p24),

          // Line chart — weekly listeners
          Text('WEEKLY LISTENERS', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(AppDimensions.p12),
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
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border1, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, _) => Text('${val.toInt()}k', style: AppTextStyles.caption),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (val.toInt() >= 0 && val.toInt() < days.length) {
                          return Text(days[val.toInt()], style: AppTextStyles.caption);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1.8), FlSpot(1, 2.4), FlSpot(2, 2.1),
                      FlSpot(3, 3.2), FlSpot(4, 2.8), FlSpot(5, 3.9), FlSpot(6, 2.6),
                    ],
                    isCurved: true,
                    color: AppColors.lionGreen,
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.lionGreen.withOpacity(0.1),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.p24),

          // Bar chart — shows popularity
          Text('SHOWS BY LISTENERS', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(AppDimensions.p12),
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
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border1, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        const shows = ['Morn', 'Mid', 'Tech', 'Eve', 'Night'];
                        if (val.toInt() >= 0 && val.toInt() < shows.length) {
                          return Text(shows[val.toInt()], style: AppTextStyles.caption);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3.9, color: AppColors.lionGreen, width: 20, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 2.8, color: AppColors.electricTeal, width: 20, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2.1, color: AppColors.lionGold, width: 20, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 3.2, color: AppColors.burntAmber, width: 20, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 1.8, color: AppColors.lionGreen, width: 20, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),

          // Platform breakdown
          const SizedBox(height: AppDimensions.p24),
          Text('PLATFORM BREAKDOWN', style: AppTextStyles.label),
          const SizedBox(height: AppDimensions.p12),
          ...[
            ('Mobile App', '68%', AppColors.lionGreen),
            ('Web Browser', '24%', AppColors.electricTeal),
            ('API / Other', '8%', AppColors.lionGold),
          ].map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(p.$1, style: AppTextStyles.caption)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: double.parse(p.$2.replaceAll('%', '')) / 100,
                      backgroundColor: AppColors.bg3,
                      valueColor: AlwaysStoppedAnimation<Color>(p.$3),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(p.$2, style: AppTextStyles.caption),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

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
