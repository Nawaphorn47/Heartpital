// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final PatientService _patientService = PatientService();
  late final Stream<List<Patient>> _patientStream;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _patientStream = _patientService.getPatients();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตารางเวลา', style: GoogleFonts.kanit()),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Patient>>(
        stream: _patientStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allPatients = snapshot.data!;
          final events = _getEventsForPatients(allPatients);

          List<Patient> getEventsForDay(DateTime day) {
            return events[DateTime(day.year, day.month, day.day)] ?? [];
          }

          return Column(
            children: [
              TableCalendar<Patient>(
                locale: 'th_TH',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: getEventsForDay,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ListView.builder(
                  itemCount: getEventsForDay(_selectedDay!).length,
                  itemBuilder: (context, index) {
                    final patient = getEventsForDay(_selectedDay!)[index];
                    return ListTile(
                      title: Text(patient.name),
                      subtitle: Text(patient.department),
                      leading: Text(
                        TimeOfDay.fromDateTime(patient.medicationTime!.toDate()).format(context),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, List<Patient>> _getEventsForPatients(List<Patient> patients) {
    Map<DateTime, List<Patient>> events = {};
    for (var patient in patients) {
      if (patient.medicationTime != null) {
        final date = patient.medicationTime!.toDate();
        final dayOnly = DateTime(date.year, date.month, date.day);
        if (events[dayOnly] == null) {
          events[dayOnly] = [];
        }
        events[dayOnly]!.add(patient);
      }
    }
    return events;
  }
}