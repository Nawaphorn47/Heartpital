// lib/screens/notification_screen.dart
import 'dart:async';
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final currentUser = auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _combinedStream = Stream.value([]);
      return;
    }
    
    // [FIX] แก้ไข Logic การดึงข้อมูลให้ตรงกับทิศทางใหม่
    _combinedStream = _patientService.getPatients().switchMap((myPatients) {
      
      // 1. ดึง ID ของผู้ป่วยทั้งหมดที่เราสร้าง
      final myPatientIds = myPatients.map((p) => p.id!).toList();

      if (myPatientIds.isEmpty) {
        return Stream.value([]);
      }

      // 2. ดึง Notification ที่มี patientId ตรงกับ ID ของผู้ป่วยที่เราสร้าง
      return _notificationService.getNotifications().map((notifications) {
        final myNotifications = notifications
            .where((n) => myPatientIds.contains(n.patientId))
            .toList();
        
        myNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final Map<String, Patient> patientMap = {
          for (var p in myPatients) p.id!: p
        };

        return myNotifications.map((notification) {
          return {
            'notification': notification,
            'patient': patientMap[notification.patientId],
          };
        }).toList();
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _completeTask(NotificationItem notification, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการเสร็จสิ้น', style: GoogleFonts.kanit()),
        content: Text('คุณต้องการสิ้นสุดเคสของ "${patient.name}" หรือไม่?\nการดำเนินการนี้จะลบข้อมูลผู้ป่วยออกไป', style: GoogleFonts.kanit()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('ยืนยัน', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.deleteNotification(notification.id!);
        await _patientService.deletePatient(patient.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เคสของ ${patient.name} เสร็จสิ้นแล้ว'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  String _formatRemainingTime(Duration remaining) {
    if (remaining.isNegative) return "ถึงเวลาแล้ว";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(remaining.inHours);
    final minutes = twoDigits(remaining.inMinutes.remainder(60));
    final seconds = twoDigits(remaining.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การแจ้งเตือนของฉัน', style: GoogleFonts.kanit()),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('ไม่มีการแจ้งเตือน', style: GoogleFonts.kanit()));

          final notificationsData = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: notificationsData.length,
            itemBuilder: (context, index) {
              final item = notificationsData[index]['notification'] as NotificationItem;
              final patient = notificationsData[index]['patient'] as Patient?;
              if (patient == null) return const SizedBox.shrink();
              return _buildNotificationCard(item, patient);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, Patient patient) {
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
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.details, style: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 20),
            _buildDetailRow(Icons.person_outline, 'ผู้ป่วย:', patient.name),
            _buildDetailRow(Icons.location_on_outlined, 'สถานที่:', '${patient.location}, ${patient.department}'),
            if (item.appointmentTime != null) 
              _buildDetailRow(Icons.timer_outlined, 'เหลือเวลา:', remainingTimeStr, valueColor: remainingTimeColor),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('เสร็จสิ้นเคส', style: GoogleFonts.kanit()),
                onPressed: () => _completeTask(item, patient),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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