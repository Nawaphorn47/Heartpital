// lib/screens/notification_screen.dart

import 'dart:async'; // [ADD]
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/notification_model.dart';
import '../models/patient_model.dart';
import '../services/notification_service.dart';
import '../services/patient_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final PatientService _patientService = PatientService();
  late Stream<List<Map<String, dynamic>>> _combinedStream;
  Timer? _timer; // [ADD] Timer สำหรับ countdown

  @override
  void initState() {
    super.initState();
    final currentUser = auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _combinedStream = Stream.value([]);
      return;
    }
    
    _combinedStream = _patientService.getPatients().switchMap((allPatients) {
      final myPatientIds = allPatients
          .where((p) => p.assignedNurseId == currentUser.uid)
          .map((p) => p.id!)
          .toList();

      if (myPatientIds.isEmpty) return Stream.value([]);

      return _notificationService.getNotifications().map((notifications) {
        final myNotifications = notifications
            .where((n) => myPatientIds.contains(n.patientId))
            .toList();
        
        myNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final Map<String, Patient> patientMap = {for (var p in allPatients) p.id!: p};
        return myNotifications.map((notification) {
          return {'notification': notification, 'patient': patientMap[notification.patientId]};
        }).toList();
      });
    });

    // [ADD] เริ่มการทำงานของ Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel(); // [ADD] อย่าลืมปิด Timer
    super.dispose();
  }

  // ... (โค้ด _timeAgo และ _completeTask เหมือนเดิม)
    String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) return '${difference.inDays} วันที่แล้ว';
    if (difference.inHours > 0) return '${difference.inHours} ชั่วโมงที่แล้ว';
    if (difference.inMinutes > 0) return '${difference.inMinutes} นาทีที่แล้ว';
    return 'เมื่อสักครู่';
  }
    Future<void> _completeTask(NotificationItem notification, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการเสร็จสิ้น', style: GoogleFonts.kanit()),
        content: Text('คุณต้องการสิ้นสุดเคสของ "${patient.name}" หรือไม่?\nการดำเนินการนี้จะลบข้อมูลผู้ป่วยออกไป', style: GoogleFonts.kanit()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('ยกเลิก', style: GoogleFonts.kanit())),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ยืนยัน', style: GoogleFonts.kanit(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.deleteNotification(notification.id!);
        await _patientService.deletePatient(patient.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เคสของ ${patient.name} เสร็จสิ้นแล้ว', style: GoogleFonts.kanit()), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.kanit()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // [NEW] ฟังก์ชันสำหรับจัดรูปแบบเวลาที่เหลือ
  String _formatRemainingTime(Duration remaining) {
    if (remaining.isNegative) return "ถึงเวลาแล้ว";
    
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(remaining.inHours);
    final minutes = twoDigits(remaining.inMinutes.remainder(60));
    final seconds = twoDigits(remaining.inSeconds.remainder(60));

    return "$hours:$minutes:$seconds";
  }

  // ... (build method เหมือนเดิม)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('การแจ้งเตือน', style: GoogleFonts.kanit(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [const Color(0xFFBAE2FF).withOpacity(0.5), const Color(0xFF81D4FA).withOpacity(0.2)],
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _combinedStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('เกิดข้อผิดพลาดบางอย่าง', style: GoogleFonts.kanit()));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('ยังไม่มีการแจ้งเตือนสำหรับเคสของคุณ', style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            final notificationsData = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notificationsData.length,
              itemBuilder: (context, index) {
                final item = notificationsData[index]['notification'] as NotificationItem;
                final patient = notificationsData[index]['patient'] as Patient?;
                
                if (patient == null) {
                  return const SizedBox.shrink(); 
                }

                return _buildNotificationCard(item, patient);
              },
            );
          },
        ),
      ),
    );
  }


  Widget _buildNotificationCard(NotificationItem item, Patient patient) {
    // ... (ส่วน icon, color เหมือนเดิม)
    IconData iconData; Color color;
    switch (item.type) {
      case 'medication': iconData = Icons.medical_services_rounded; color = const Color(0xFF0D47A1); break;
      case 'checkup': iconData = Icons.health_and_safety_rounded; color = Colors.green.shade200; break;
      case 'alert': iconData = Icons.warning_amber_rounded; color = Colors.red.shade200; break;
      case 'care': iconData = Icons.local_hospital_rounded; color = Colors.purple.shade200; break;
      case 'NPO': iconData = Icons.no_food_rounded; color = Colors.orange.shade200; break;
      default: iconData = Icons.notifications_rounded; color = Colors.grey.shade200; break;
    }

    // [MODIFIED] คำนวณเวลาที่เหลือ
    String remainingTimeStr = '';
    Color remainingTimeColor = Colors.grey;
    if (item.appointmentTime != null) {
      final remaining = item.appointmentTime!.toDate().difference(DateTime.now());
      remainingTimeStr = _formatRemainingTime(remaining);
      if (!remaining.isNegative) {
        remainingTimeColor = remaining.inMinutes < 15 ? Colors.red.shade700 : Colors.orange.shade800;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2, shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(item.details, style: GoogleFonts.kanit(fontWeight: FontWeight.w600, fontSize: 16, color: color))),
                // [MODIFIED] แสดงเวลาที่เด้งแจ้งเตือน (ไม่ใช่เวลาที่เหลือ)
                Text(_timeAgo(item.timestamp.toDate()), style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.person_outline, 'ผู้ป่วย:', patient.name),
            _buildDetailRow(Icons.location_on_outlined, 'สถานที่:', '${patient.location}, ${patient.department}'),
            
            // [NEW] แสดงแถบเวลาที่เหลือ
            if (item.appointmentTime != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(Icons.timer_outlined, 'เหลือเวลา:', remainingTimeStr, valueColor: remainingTimeColor),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('เสร็จสิ้น', style: GoogleFonts.kanit()),
                onPressed: () => _completeTask(item, patient),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.kanit(color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.kanit(fontWeight: FontWeight.w500, color: valueColor))),
        ],
      ),
    );
  }
}