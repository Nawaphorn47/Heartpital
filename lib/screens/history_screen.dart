// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/history_model.dart';
import '../services/history_service.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final currentUser = auth.FirebaseAuth.instance.currentUser;
  
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    // ตั้งค่าเริ่มต้นเป็นเดือนปัจจุบัน
    final now = DateTime.now();
    _selectedStartDate = DateTime(now.year, now.month, 1);
    _selectedEndDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF0D47A1),
            colorScheme: const ColorScheme.light(primary: Color(0xFF0D47A1)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeText = 'เลือกช่วงเวลา';
    if (_selectedStartDate != null && _selectedEndDate != null) {
      dateRangeText =
          '${DateFormat('d MMM yyyy').format(_selectedStartDate!)} - ${DateFormat('d MMM yyyy').format(_selectedEndDate!)}';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'ประวัติผู้ป่วย',
          style: GoogleFonts.kanit(
            color: const Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFBAE2FF).withOpacity(0.5),
              const Color(0xFF81D4FA).withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(dateRangeText, style: GoogleFonts.kanit()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF0D47A1)),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: currentUser == null
                  ? Center(
                      child: Text('กรุณาเข้าสู่ระบบเพื่อดูประวัติ',
                          style: GoogleFonts.kanit()),
                    )
                  : StreamBuilder<List<History>>(
                      stream: _historyService.getHistory(
                        currentUser!.uid,
                        startDate: _selectedStartDate,
                        endDate: _selectedEndDate,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('เกิดข้อผิดพลาด : ${snapshot.error}',
                                style: GoogleFonts.kanit()),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off,
                                    size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('ไม่พบประวัติในช่วงที่เลือก',
                                    style: GoogleFonts.kanit(
                                        fontSize: 18, color: Colors.grey.shade600)),
                              ],
                            ),
                          );
                        }

                        final historyList = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: historyList.length,
                          itemBuilder: (context, index) {
                            final historyItem = historyList[index];
                            return _buildHistoryCard(historyItem);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(History history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              history.details,
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D47A1),
              ),
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.person_outline, 'ผู้ป่วย :',
                '${history.patientName} (HN: ${history.patientHn})'),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'วันที่เสร็จสิ้น :',
              DateFormat('d MMM yyyy, HH:mm')
                  .format(history.completedDate.toDate()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.kanit(color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.kanit(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}