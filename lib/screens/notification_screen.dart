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
    // --- ไม่มีการเปลี่ยนแปลงฟังก์ชันการทำงาน ---
    _combinedStream = Rx.combineLatest2(
      _notificationService.getNotifications(),
      _patientService.getPatients(),
      (List<NotificationItem> notifications, List<Patient> patients) {
        // Sort notifications by timestamp in descending order (newest first)
        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
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
  // --- สิ้นสุดส่วนที่ไม่เปลี่ยนแปลง ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ทำให้โปร่งใส
      // ⭐️ [IMPROVED] ปรับปรุง AppBar ให้สอดคล้องกับหน้าอื่น
      appBar: AppBar(
        title: Text('การแจ้งเตือน', style: GoogleFonts.kanit(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      // ⭐️ [IMPROVED] เพิ่มพื้นหลัง Gradient ให้เหมือนหน้าอื่น
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
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _combinedStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาดบางอย่าง', style: GoogleFonts.kanit()));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // ⭐️ [IMPROVED] ปรับปรุง UI ตอนไม่มีข้อมูล
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('ยังไม่มีการแจ้งเตือน', style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey.shade600)),
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
                final timeAgo = _timeAgo(item.timestamp.toDate());
                final patientName = patient != null ? patient.name : 'ไม่พบข้อมูลผู้ป่วย';
                // ใช้ Card ที่ออกแบบใหม่
                return _buildNotificationCard(item, timeAgo, patientName);
              },
            );
          },
        ),
      ),
    );
  }

  // ⭐️ [IMPROVED] ออกแบบ Notification Card ใหม่ทั้งหมด
  Widget _buildNotificationCard(NotificationItem item, String timeAgo, String patientName) {
    IconData iconData;
    Color color;

    switch (item.type) {
      case 'medication':
        iconData = Icons.medical_services_rounded;
        color = const Color(0xFF0D47A1); // น้ำเงิน
        break;
      case 'checkup':
        iconData = Icons.health_and_safety_rounded;
        color = Colors.green.shade200; // เขียว
        break;
      case 'alert':
        iconData = Icons.warning_amber_rounded;
        color = Colors.red.shade200; // แดง
        break;
      case 'care':
        iconData = Icons.local_hospital_rounded;
        color = Colors.purple.shade200; // ม่วง
        break;
      case 'NPO':
        iconData = Icons.no_food_rounded;
        color = Colors.orange.shade200; // ส้ม
        break;
      default:
        iconData = Icons.notifications_rounded;
        color = Colors.grey.shade200; // เทา
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // แถบสีด้านข้างเพื่อบ่งบอกประเภท
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(iconData, color: color, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.details,
                            style: GoogleFonts.kanit(
                              fontWeight: FontWeight.w600, // Semi-bold
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ผู้ป่วย: $patientName',
                            style: GoogleFonts.kanit(
                              fontSize: 14,
                              color: Colors.grey.shade800
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}