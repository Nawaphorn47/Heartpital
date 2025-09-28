import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth; // <<< เพิ่ม import
import '../models/history_model.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final currentUser = auth.FirebaseAuth.instance.currentUser; // <<< ดึงข้อมูลผู้ใช้ปัจจุบัน

  @override
  Widget build(BuildContext context) {
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
        // ตรวจสอบว่ามีผู้ใช้ล็อกอินอยู่หรือไม่
        child: currentUser == null
            ? Center(
                child: Text('กรุณาเข้าสู่ระบบเพื่อดูประวัติ',
                    style: GoogleFonts.kanit()),
              )
            : StreamBuilder<List<History>>(
                // <<< ส่ง currentUser.uid เข้าไปใน stream
                stream: _historyService.getHistory(currentUser!.uid),
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
                          Text('ยังไม่มีประวัติผู้ป่วย',
                              style: GoogleFonts.kanit(
                                  fontSize: 18, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  final historyList = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      final historyItem = historyList[index];
                      return _buildHistoryCard(historyItem);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHistoryCard(History history) {
    // ... (โค้ดส่วนนี้เหมือนเดิม)
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
    // ... (โค้ดส่วนนี้เหมือนเดิม)
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