// lib/screens/patient_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final PatientService _patientService = PatientService();
  late final Stream<List<Patient>> _patientsStream;

  // Change to display all 24 hours
  final List<int> _workingHours = List.generate(24, (index) => index); // 0:00 to 23:00

  @override
  void initState() {
    super.initState();
    _patientsStream = _patientService.getPatients();
  }

  Map<int, List<Patient>> _groupPatientsByHour(List<Patient> patients) {
    final Map<int, List<Patient>> grouped = {};
    for (var patient in patients) {
      if (patient.medicationTime != null) {
        final hour = patient.medicationTime!.toDate().hour;
        if (grouped[hour] == null) {
          grouped[hour] = [];
        }
        grouped[hour]!.add(patient);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'ตารางเวลาวันนี้',
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
              const Color(0xFF81D4FA).withOpacity(0.2)
            ],
          ),
        ),
        child: StreamBuilder<List<Patient>>(
          stream: _patientsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                      style: GoogleFonts.kanit()));
            }

            // Always build the timeline, even if there are no patients.
            // If data is null, use an empty list.
            final patients = snapshot.data ?? [];
            final groupedPatients = _groupPatientsByHour(patients);

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _workingHours.length,
              itemBuilder: (context, index) {
                final hour = _workingHours[index];
                final patientsForThisHour = groupedPatients[hour] ?? [];
                return _buildTimeSlotRow(hour, patientsForThisHour);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeSlotRow(int hour, List<Patient> patients) {
    final timeFormat = DateFormat('HH:mm');
    final startTime = timeFormat.format(DateTime(0, 0, 0, hour));
    final endTime = timeFormat.format(DateTime(0, 0, 0, hour, 59));
    final bool isBusy = patients.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$startTime\n-\n$endTime',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isBusy ? Colors.red.shade50 : Colors.teal.shade50,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(12),
                   border: Border(
                     left: BorderSide(
                       color: isBusy ? Colors.red.shade400 : Colors.teal.shade400,
                       width: 5,
                     )
                   )
                ),
                child: isBusy
                    ? _buildBusySlot(patients)
                    : _buildFreeSlot(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeSlot() {
    return Row(
      children: [
        Icon(Icons.check_circle_outline, color: Colors.teal.shade700),
        const SizedBox(width: 8),
        Text(
          'ว่าง',
          style: GoogleFonts.kanit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildBusySlot(List<Patient> patients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          'ไม่ว่าง (${patients.length} เคส)',
          style: GoogleFonts.kanit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: patients.map((patient) => Chip(
            avatar: const Icon(Icons.person, size: 16, color: Colors.white),
            label: Text(patient.name, style: GoogleFonts.kanit(color: Colors.white)),
            backgroundColor: Colors.red.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )).toList(),
        )
      ],
    );
  }
}