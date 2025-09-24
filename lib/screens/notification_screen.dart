/*lib/screens/notification_screen.dart*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
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

  @override
  void initState() {
    super.initState();
    // Combine notifications and patients stream
    _combinedStream = Rx.combineLatest2(
      _notificationService.getNotifications(),
      _patientService.getPatients(),
      (List<NotificationItem> notifications, List<Patient> patients) {
        final Map<String, Patient> patientMap = {
          for (var p in patients) p.id!: p
        };
        return notifications.map((notification) {
          final patient = patientMap[notification.patientId];
          return {
            'notification': notification,
            'patient': patient,
          };
        }).toList();
      },
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    }
    return 'เมื่อสักครู่';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ทำให้โปร่งใส
      appBar: AppBar(
        title: Text('การแจ้งเตือน', style: GoogleFonts.kanit(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFBAE2FF), // สีเดียวกับพื้นหลังหลัก
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong', style: GoogleFonts.kanit()));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('ไม่มีการแจ้งเตือน', style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final notificationsData = snapshot.data!;

          return ListView.builder(
            itemCount: notificationsData.length,
            itemBuilder: (context, index) {
              final item = notificationsData[index]['notification'] as NotificationItem;
              final patient = notificationsData[index]['patient'] as Patient?;
              final timeAgo = _timeAgo(item.timestamp.toDate());
              final patientName = patient != null ? patient.name : 'ไม่พบผู้ป่วย';
              return _buildNotificationCard(item, timeAgo, patientName);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, String timeAgo, String patientName) {
    IconData iconData;
    Color iconAndTextColor;
    switch (item.type) {
      case 'medication':
        iconData = Icons.medical_services_outlined;
        iconAndTextColor = const Color(0xFF0D47A1); // สีหลัก
        break;
      case 'checkup':
        iconData = Icons.health_and_safety_outlined;
        iconAndTextColor = Colors.green;
        break;
      case 'alert':
        iconData = Icons.warning_amber_rounded;
        iconAndTextColor = Colors.red;
        break;
       case 'care':
      iconData = Icons.local_hospital_outlined;
      iconAndTextColor = Colors.purple;
      break;
       case 'NPO':
      iconData = Icons.restaurant_menu_outlined;
      iconAndTextColor = Colors.orange;
      break;
      default:
        iconData = Icons.notifications_outlined;
        iconAndTextColor = Colors.grey;
        break;
    }


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // พื้นหลังการ์ดเป็นสีขาว
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData, color: iconAndTextColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.details,
                      style: GoogleFonts.kanit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: iconAndTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ผู้ป่วย: $patientName',
                      style: GoogleFonts.kanit(fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}