import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:ui';
import '../services/patient_service.dart';
import '../models/patient_model.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final PatientService _patientService = PatientService();
  String _groupBy = 'แผนก';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ทำให้โปร่งใสเพื่อรับสีจาก Scaffold หลัก
      body: StreamBuilder<List<Patient>>(
        stream: _patientService.getPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: GoogleFonts.kanit()));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('ไม่มีข้อมูลผู้ป่วย', style: GoogleFonts.kanit()));
          }

          final patients = snapshot.data!;
          final departmentCounts = _getCounts(patients, 'department');
          final npoCount = patients.where((p) => p.isNPO).length;
          final totalCount = patients.length;

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
                          _buildStatCards(totalCount, npoCount),
                          const SizedBox(height: 24),
                          _buildSectionTitle('จำนวนผู้ป่วยตาม$_groupBy'),
                          const SizedBox(height: 16),
                          _buildChart(departmentCounts),
                          const SizedBox(height: 24),
                          _buildSectionTitle('รายละเอียดตาม$_groupBy'),
                          const SizedBox(height: 16),
                          _buildDetailList(departmentCounts, totalCount),
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
      expandedHeight: 180.0,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFBAE2FF),
      // เราจะใช้ title ของ FlexibleSpaceBar เพื่อให้มัน animate ได้
      flexibleSpace: FlexibleSpaceBar(
        // title จะลดขนาดและเคลื่อนที่ไปอยู่บน App Bar อัตโนมัติ
        title: Text(
          'Dashboard',
          style: GoogleFonts.kanit(
            color: accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // จัดให้อยู่ตรงกลางเมื่อหด
        titlePadding: const EdgeInsets.only(bottom: 16), // ระยะห่างของ title
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFBAE2FF),
                    const Color(0xFF81D4FA).withOpacity(0.5),
                  ],
                ),
              ),
            ),
            // ไอคอนตกแต่งพื้นหลัง
            // const Center(
            //   child: Icon(
            //     Icons.bar_chart_rounded,
            //     size: 100,
            //     color: Color(0xFF0D47A1),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getCounts(List<Patient> patients, String type) {
    final Map<String, int> counts = {};
    for (var patient in patients) {
      final key = type == 'department' ? patient.department : patient.location;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildStatCards(int total, int npoCount) {
    return Row(
      children: [
        Expanded(
          child: _buildSoftUICard(
            'ผู้ป่วยทั้งหมด',
            total.toString(),
            Icons.groups_2_outlined,
            const Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSoftUICard(
            'งดน้ำ-อาหาร (NPO)',
            npoCount.toString(),
            Icons.no_food_outlined,
            Colors.orange.shade800,
            totalCount: total,
            currentCount: npoCount,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSoftUICard(String title, String count, IconData icon, Color color,
      {int? totalCount, int? currentCount}) {
    double percentage = 0;
    if (totalCount != null && currentCount != null && totalCount > 0) {
      percentage = currentCount / totalCount;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA).withOpacity(0.7), // สีพื้นหลังของการ์ด
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (totalCount != null)
                CircularPercentIndicator(
                  radius: 20.0,
                  lineWidth: 6.0,
                  percent: percentage,
                  center: Text("${(percentage * 100).toInt()}%", style: GoogleFonts.kanit(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  progressColor: color,
                  backgroundColor: color.withOpacity(0.2),
                )
            ],
          ),
          const SizedBox(height: 12),
          Text(count, style: GoogleFonts.kanit(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: GoogleFonts.kanit(fontSize: 14, color: color.withOpacity(0.8))),
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
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.9), offset: const Offset(-5, -5), blurRadius: 10),
          BoxShadow(color: Colors.blue.shade100.withOpacity(0.5), offset: const Offset(5, 5), blurRadius: 10),
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
                  GoogleFonts.kanit(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [TextSpan(text: '${rod.toY.toInt()} คน', style: GoogleFonts.kanit(color: Colors.cyanAccent, fontWeight: FontWeight.bold))],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailList(Map<String, int> data, int totalCount) {
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: List.generate(sortedEntries.length, (index) {
        final entry = sortedEntries[index];
        final color = _getChartColor(index);
        final percentage = totalCount > 0 ? entry.value / totalCount : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      const Color(0xFF0D47A1),
      Colors.green.shade600,
      Colors.orange.shade800,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
    ];
    return colors[index % colors.length];
  }
}