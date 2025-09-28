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
  String _filterStatus = 'all'; // 'all', 'busy', 'free'

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
    grouped.forEach((key, value) {
      value.sort((a, b) => a.medicationTime!.toDate().compareTo(b.medicationTime!.toDate()));
    });
    return grouped;
  }

  List<int> _getFilteredHours(Map<int, List<Patient>> groupedPatients) {
    final allHours = List<int>.generate(24, (i) => i);
    switch (_filterStatus) {
      case 'busy':
        return groupedPatients.keys.toList()..sort();
      case 'free':
        final busyHours = groupedPatients.keys.toSet();
        return allHours.where((hour) => !busyHours.contains(hour)).toList();
      case 'all':
      default:
        return allHours;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'ตารางงานวันนี้',
          style: GoogleFonts.kanit(
            color: const Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Column(
        children: [
          _buildFilterButtons(),
          Expanded(
            child: Container(
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

                  final patients = snapshot.data ?? [];
                  final groupedPatients = _groupPatientsByHour(patients);
                  final filteredHours = _getFilteredHours(groupedPatients);

                  if (filteredHours.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                              _filterStatus == 'busy'
                                  ? 'วันนี้ไม่มีนัดหมายผู้ป่วย'
                                  : 'ไม่มีช่วงเวลาว่าง',
                              style: GoogleFonts.kanit(
                                  fontSize: 18, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredHours.length,
                    itemBuilder: (context, index) {
                      final hour = filteredHours[index];
                      final patientsForThisHour = groupedPatients[hour] ?? [];
                      return _buildTimeSlotSection(hour, patientsForThisHour);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton('ทั้งหมด', 'all'),
          _buildFilterButton('ไม่ว่าง', 'busy'),
          _buildFilterButton('ว่าง', 'free'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, String status) {
    final isSelected = _filterStatus == status;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _filterStatus = status;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isSelected ? 4 : 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            text,
            style: GoogleFonts.kanit(fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotSection(int hour, List<Patient> patients) {
    final bool isBusy = patients.isNotEmpty;
    final timeFormat = DateFormat('HH:mm น.');
    final hourDisplay = timeFormat.format(DateTime(0, 0, 0, hour));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text(
            '$hourDisplay',
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isBusy ? const Color(0xFFD32F2F) : Colors.grey.shade700,
            ),
          ),
        ),
        if (isBusy)
          ...patients.map((patient) => _buildPatientCard(patient)).toList()
        else
          _buildFreeSlotCard(),
        const Divider(height: 24, thickness: 1.0, color: Color(0xFFE3F2FD)),
      ],
    );
  }

  Widget _buildPatientCard(Patient patient) {
    final timeFormat = DateFormat('HH:mm น.');
    final patientTimeDisplay = patient.medicationTime != null
        ? timeFormat.format(patient.medicationTime!.toDate())
        : 'เวลาไม่ระบุ';

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: const Color(0xFFD32F2F).withOpacity(0.4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.red.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.person_rounded, color: const Color(0xFFD32F2F), size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade900,
                      ),
                    ),
                    Text(
                      'HN: ${patient.hn}',
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                patientTimeDisplay,
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeSlotCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.grey.shade400.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.check_circle_outline, color: Colors.grey.shade600, size: 30),
              ),
              const SizedBox(width: 16),
              Text(
                'ว่าง',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}