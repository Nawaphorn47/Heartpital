// lib/screens/patient_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_model.dart';
import 'add_edit_patient_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('รายละเอียดผู้ป่วย', style: GoogleFonts.kanit()),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D47A1),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditPatientScreen(patient: patient),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
          child: const Icon(
            Icons.person_outline,
            size: 60,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          patient.name,
          style: GoogleFonts.kanit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'HN: ${patient.hn}',
          style: GoogleFonts.kanit(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    String appointmentTimeDisplay = "ยังไม่ได้ตั้งค่า";
    if (patient.medicationTime != null) {
      final dateTime = patient.medicationTime!.toDate();
      appointmentTimeDisplay = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(dateTime));
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.apartment_outlined,
              title: 'ตึก',
              value: patient.building,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.business_center_outlined,
              title: 'แผนก',
              value: patient.department,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.access_time_filled_rounded,
              title: 'เวลานัดหมาย/หัตถการ',
              value: appointmentTimeDisplay,
              valueColor: patient.medicationTime != null ? const Color(0xFF0D47A1) : Colors.grey,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: patient.isNPO ? Icons.no_food_outlined : Icons.food_bank_outlined,
              title: 'สถานะ NPO',
              value: patient.isNPO ? 'งดน้ำและอาหาร' : 'ปกติ',
              valueColor: patient.isNPO ? Colors.orange.shade800 : Colors.green.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}