import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';
import 'patient_detail_screen.dart';

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
    initializeDateFormatting('th_TH');
    _patientStream = _patientService.getPatients();
    _selectedDay = _focusedDay;
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('ไม่มีตารางงาน', style: GoogleFonts.kanit()));
          }

          final allPatients = snapshot.data!;
          final events = _getEventsForPatients(allPatients);

          List<Patient> getEventsForDay(DateTime day) {
            final dayOnly = DateTime(day.year, day.month, day.day);
            return events[dayOnly] ?? [];
          }

          final selectedDayEvents = getEventsForDay(_selectedDay!);
          selectedDayEvents.sort((a,b) => a.medicationTime!.compareTo(b.medicationTime!));

          return Column(
            children: [
              TableCalendar<Patient>(
                locale: 'th_TH',
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.kanit(fontSize: 18),
                  formatButtonVisible: false,
                ),
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
                  todayDecoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Color(0xFF0D47A1), shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        right: 1, bottom: 1,
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red[400]),
                          width: 16, height: 16,
                          child: Center(child: Text('${events.length}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedDayEvents.length,
                  itemBuilder: (context, index) {
                    final patient = selectedDayEvents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(patient.name, style: GoogleFonts.kanit()),
                        subtitle: Text(patient.department, style: GoogleFonts.kanit()),
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              TimeOfDay.fromDateTime(patient.medicationTime!.toDate()).format(context),
                              style: GoogleFonts.kanit(fontSize: 16, color: const Color(0xFF0D47A1)),
                            ),
                          ],
                        ),
                        onTap: () {
                           Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => PatientDetailScreen(patient: patient),
                           ));
                        },
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
}