// lib/screens/patient_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import '../services/patient_service.dart';
import '../models/patient_model.dart';
import 'dart:async';

// [NEW] สร้าง Model เพื่อจัดเก็บข้อมูลสถิติให้เป็นระเบียบ
class DashboardStats {
  final int totalCount;
  final int npoCount;
  final Map<String, int> departmentCounts;

  DashboardStats({
    required this.totalCount,
    required this.npoCount,
    required this.departmentCounts,
  });
}

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final PatientService _patientService = PatientService();
  // [OPTIMIZED] สร้าง Stream ที่แปลงข้อมูลดิบให้เป็นข้อมูลสถิติเลย
  late final Stream<DashboardStats> _statsStream;

  @override
  void initState() {
    super.initState();
    // [OPTIMIZED] ใช้ .map เพื่อแปลง List<Patient> เป็น DashboardStats
    // การคำนวณจะเกิดขึ้นใน Stream pipeline ทำให้โค้ดใน-ส่วน UI สะอาดขึ้น
    _statsStream = _patientService.getPatients().map((patients) {
      final departmentCounts = _getCounts(patients, 'department');
      final npoCount = patients.where((p) => p.isNPO).length;
      return DashboardStats(
        totalCount: patients.length,
        npoCount: npoCount,
        departmentCounts: departmentCounts,
      );
    });
  }

  Map<String, int> _getCounts(List<Patient> patients, String type) {
    final Map<String, int> counts = {};
    for (var patient in patients) {
      final key = type == 'department' ? patient.department : patient.location;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DashboardStats>(
        // [OPTIMIZED] ฟังจาก Stream ที่แปลงข้อมูลแล้ว
        stream: _statsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: GoogleFonts.kanit()));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('ไม่มีข้อมูลผู้ป่วย', style: GoogleFonts.kanit()));
          }

          final stats = snapshot.data!;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          _buildStatCards(stats.totalCount, stats.npoCount),
                          const SizedBox(height: 24),
                          _buildSectionTitle('จำนวนผู้ป่วยตามแผนก'),
                          const SizedBox(height: 16),
                          _buildChart(stats.departmentCounts),
                          const SizedBox(height: 24),
                          _buildSectionTitle('รายละเอียดตามแผนก'),
                          const SizedBox(height: 16),
                          _buildDetailList(stats.departmentCounts, stats.totalCount),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    const Color accentColor = Color(0xFF0D47A1);

    return SliverAppBar(
      expandedHeight: 130.0,
      pinned: true,
      elevation: 2,
      backgroundColor: Colors.white,
      foregroundColor: accentColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          'ภาพรวมข้อมูล',
          style: GoogleFonts.kanit(
            color: accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFBAE2FF).withOpacity(0.8),
                    const Color(0xFF81D4FA).withOpacity(0.5),
                  ],
                ),
              ),
            ),
             Positioned(
              bottom: -20,
              right: -20,
              child: Icon(
                Icons.bar_chart_rounded,
                size: 150,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildStatCards(int total, int npoCount) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildInfoCard(
              'ผู้ป่วยทั้งหมด',
              total.toString(),
              Icons.groups_2_outlined,
              const Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInfoCard(
              'งดน้ำ-อาหาร (NPO)',
              npoCount.toString(),
              Icons.no_food_outlined,
              Colors.orange.shade800,
              totalCount: total,
              currentCount: npoCount,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String count, IconData icon, Color color,
      {int? totalCount, int? currentCount}) {
    double percentage = 0;
    if (totalCount != null && currentCount != null && totalCount > 0) {
      percentage = currentCount / totalCount;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              if (totalCount != null)
                CircularPercentIndicator(
                  radius: 22.0,
                  lineWidth: 5.0,
                  percent: percentage,
                  center: Text("${(percentage * 100).toInt()}%", style: GoogleFonts.kanit(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.2),
                )
            ],
          ),
          const SizedBox(height: 12),
          Column(
             crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: GoogleFonts.kanit(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: GoogleFonts.kanit(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
      ),
    );
  }

  Widget _buildChart(Map<String, int> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: List.generate(sortedEntries.length, (index) {
            final entry = sortedEntries[index];
            final color = _getChartColor(index);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedEntries.length) return const SizedBox.shrink();
                  final title = sortedEntries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(title.length > 5 ? '${title.substring(0, 5)}...' : title, style: GoogleFonts.kanit(fontSize: 10, color: const Color(0xFF0D47A1).withOpacity(0.8))),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color(0xFF0D47A1),
               getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final title = sortedEntries[groupIndex].key;
                return BarTooltipItem(
                  '$title\n',
                  GoogleFonts.kanit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  children: [TextSpan(text: '${rod.toY.toInt()} คน', style: GoogleFonts.kanit(color: Colors.cyanAccent, fontWeight: FontWeight.normal, fontSize: 12))],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailList(Map<String, int> data, int totalCount) {
    if (data.isEmpty) return const SizedBox.shrink();
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(sortedEntries.length, (index) {
          final entry = sortedEntries[index];
          final color = _getChartColor(index);
          final percentage = totalCount > 0 ? entry.value / totalCount : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: GoogleFonts.kanit(fontWeight: FontWeight.w500, color: const Color(0xFF0D47A1))),
                    Text('${entry.value} คน', style: GoogleFonts.kanit(fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearPercentIndicator(
                  percent: percentage,
                  lineHeight: 8,
                  barRadius: const Radius.circular(4),
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.2),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      const Color(0xFF0D47A1),
      Colors.green.shade200,
      Colors.orange.shade200,
      Colors.purple.shade200,
      Colors.red.shade200,
      Colors.teal.shade200,
      Colors.pink.shade200,
    ];
    return colors[index % colors.length];
  }
}