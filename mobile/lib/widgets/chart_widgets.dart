import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/reading_analytics.dart';

class WeeklyReadingChart extends StatelessWidget {
  final List<DailyReadingStats> weeklyStats;

  const WeeklyReadingChart({
    Key? key,
    required this.weeklyStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spots = _generateSpots();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < weeklyStats.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      weeklyStats[index].dayOfWeek,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}分',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minX: 0,
        maxX: (weeklyStats.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.6),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.3),
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueAccent,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index >= 0 && index < weeklyStats.length) {
                  final stat = weeklyStats[index];
                  return LineTooltipItem(
                    '${stat.formattedDate}\n${touchedSpot.y.toInt()}分',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return weeklyStats.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.totalReadingTimeMinutes.toDouble(),
      );
    }).toList();
  }

  double _getMaxY() {
    if (weeklyStats.isEmpty) return 60;
    final maxMinutes = weeklyStats
        .map((stat) => stat.totalReadingTimeMinutes)
        .reduce((a, b) => a > b ? a : b);
    return (maxMinutes + 30).toDouble();
  }
}

class GenreDistributionChart extends StatelessWidget {
  final List<GenreStats> genreStats;

  const GenreDistributionChart({
    Key? key,
    required this.genreStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (genreStats.isEmpty) {
      return const Center(
        child: Text(
          'ジャンルデータがありません',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final sections = _generateSections();
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildLegend(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections() {
    final totalBooks = genreStats.fold<int>(
      0,
      (sum, genre) => sum + genre.booksReadCount,
    );

    if (totalBooks == 0) return [];

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    return genreStats.take(10).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final genre = entry.value;
      final percentage = (genre.booksReadCount / totalBooks * 100);

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: genre.booksReadCount.toDouble(),
        title: '${percentage.toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];

    return genreStats.take(10).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final genre = entry.value;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                genre.genre,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${genre.booksReadCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class ReadingSpeedChart extends StatelessWidget {
  final List<double> speedData;
  final List<String> labels;

  const ReadingSpeedChart({
    Key? key,
    required this.speedData,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (speedData.isEmpty) {
      return const Center(
        child: Text(
          '読書速度データがありません',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueAccent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${labels[group.x]}:\n${rod.toY.toInt()}語/分',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      labels[index],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        barGroups: _generateBarGroups(context),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(BuildContext context) {
    return speedData.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Theme.of(context).primaryColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY() {
    if (speedData.isEmpty) return 300;
    final maxSpeed = speedData.reduce((a, b) => a > b ? a : b);
    return (maxSpeed * 1.2).roundToDouble();
  }
}

class ProgressRingChart extends StatelessWidget {
  final double progress;
  final String centerText;
  final Color color;
  final double size;

  const ProgressRingChart({
    Key? key,
    required this.progress,
    required this.centerText,
    this.color = Colors.blue,
    this.size = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 8,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${progress.toInt()}%',
                style: TextStyle(
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                centerText,
                style: TextStyle(
                  fontSize: size * 0.08,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyReadingSummary> monthlyData;

  const MonthlyTrendChart({
    Key? key,
    required this.monthlyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const Center(
        child: Text(
          '月次データがありません',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < monthlyData.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      monthlyData[index].monthName,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}冊',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minX: 0,
        maxX: (monthlyData.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _generateSpots(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.6),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.3),
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return monthlyData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.totalBooksRead.toDouble(),
      );
    }).toList();
  }

  double _getMaxY() {
    if (monthlyData.isEmpty) return 5;
    final maxBooks = monthlyData
        .map((data) => data.totalBooksRead)
        .reduce((a, b) => a > b ? a : b);
    return (maxBooks + 2).toDouble();
  }
}