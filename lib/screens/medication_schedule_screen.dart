// // lib/screens/medication_schedule_screen.dart

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';
// import '../models/medication_model.dart';
// import '../services/medication_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class MedicationScheduleScreen extends StatefulWidget {
//   const MedicationScheduleScreen({super.key});

//   @override
//   State<MedicationScheduleScreen> createState() => _MedicationScheduleScreenState();
// }

// class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
//   final MedicationService _medicationService = MedicationService();
//   CalendarFormat _calendarFormat = CalendarFormat.week;
//   DateTime _focusedDay = DateTime.now();
//   DateTime _selectedDay = DateTime.now();
  
//   // Future สำหรับเก็บรายการยาที่โหลดมาแล้ว
//   late Future<List<Medication>> _medicationsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _medicationsFuture = _loadMedicationsForDay(_selectedDay);
//   }

//   Future<List<Medication>> _loadMedicationsForDay(DateTime day) {
//     return _medicationService.getMedicationsByDate(day).first;
//   }
  
//   Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
//     if (!isSameDay(_selectedDay, selectedDay)) {
//       setState(() {
//         _selectedDay = selectedDay;
//         _focusedDay = focusedDay;
//         _medicationsFuture = _loadMedicationsForDay(selectedDay);
//       });
//     }
//   }

//   Future<void> _updateMedicationStatus(Medication medication) async {
//     try {
//       final updatedMedication = Medication(
//         id: medication.id,
//         name: medication.name,
//         patientId: medication.patientId,
//         status: 'completed',
//         scheduledTime: medication.scheduledTime,
//         administeredTime: Timestamp.now(),
//       );
//       await _medicationService.updateMedication(updatedMedication);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('บันทึกการให้ยา "${medication.name}" เรียบร้อย', style: GoogleFonts.kanit()),
//           backgroundColor: Colors.green,
//         ),
//       );
//       // Refresh the list for the selected day
//       setState(() {
//         _medicationsFuture = _loadMedicationsForDay(_selectedDay);
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e', style: GoogleFonts.kanit()),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('ตารางให้ยา', style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
//       ),
//       body: Column(
//         children: [
//           _buildCalendar(),
//           const SizedBox(height: 16),
//           _buildTodoListHeader(),
//           Expanded(
//             child: FutureBuilder<List<Medication>>(
//               future: _medicationsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: GoogleFonts.kanit()));
//                 }
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return Center(
//                     child: Text(
//                       'ไม่มีรายการยาสำหรับวันนี้',
//                       style: GoogleFonts.kanit(color: Colors.grey[600]),
//                     ),
//                   );
//                 }
                
//                 final medications = snapshot.data!;
//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   itemCount: medications.length,
//                   itemBuilder: (context, index) {
//                     final medication = medications[index];
//                     return _buildMedicationTile(medication);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildCalendar() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       margin: const EdgeInsets.all(16.0),
//       child: TableCalendar(
//         locale: 'th_TH', // ใช้ภาษาไทย
//         firstDay: DateTime.utc(2020, 1, 1),
//         lastDay: DateTime.utc(2030, 12, 31),
//         focusedDay: _focusedDay,
//         calendarFormat: _calendarFormat,
//         selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//         onDaySelected: _onDaySelected,
//         onFormatChanged: (format) {
//           if (_calendarFormat != format) {
//             setState(() {
//               _calendarFormat = format;
//             });
//           }
//         },
//         onPageChanged: (focusedDay) {
//           _focusedDay = focusedDay;
//         },
//         headerStyle: HeaderStyle(
//           formatButtonVisible: true,
//           titleCentered: true,
//           formatButtonTextStyle: GoogleFonts.kanit(color: Colors.white),
//           formatButtonDecoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.primary,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           titleTextStyle: GoogleFonts.kanit(fontWeight: FontWeight.bold),
//           leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurface),
//           rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
//         ),
//         calendarStyle: CalendarStyle(
//           todayDecoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
//             shape: BoxShape.circle,
//           ),
//           selectedDecoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.primary,
//             shape: BoxShape.circle,
//           ),
//           defaultTextStyle: GoogleFonts.kanit(),
//           weekendTextStyle: GoogleFonts.kanit(color: Colors.red),
//           holidayTextStyle: GoogleFonts.kanit(color: Colors.red),
//           disabledTextStyle: GoogleFonts.kanit(color: Colors.grey),
//         ),
//       ),
//     );
//   }

//   Widget _buildTodoListHeader() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             'รายการยาสำหรับ ${DateFormat.yMMMd('th_TH').format(_selectedDay)}',
//             style: GoogleFonts.kanit(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               setState(() {
//                 _medicationsFuture = _loadMedicationsForDay(_selectedDay);
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMedicationTile(Medication medication) {
//     Color statusColor;
//     String statusText;
//     switch (medication.status) {
//       case 'completed':
//         statusColor = Colors.green;
//         statusText = 'ให้ยาแล้ว';
//         break;
//       case 'due':
//         statusColor = Colors.orange;
//         statusText = 'ถึงเวลาให้ยา';
//         break;
//       default:
//         statusColor = Colors.blueGrey;
//         statusText = 'ยังไม่ถึงเวลา';
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: statusColor.withOpacity(0.2),
//           child: Icon(Icons.medication, color: statusColor),
//         ),
//         title: Text(medication.name, style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
//         subtitle: Text(
//           'เวลา: ${DateFormat.jm().format(medication.scheduledTime.toDate())}\nสถานะ: $statusText',
//           style: GoogleFonts.kanit(),
//         ),
//         trailing: medication.status == 'completed'
//             ? Text(
//                 'ให้ยาเมื่อ\n${DateFormat.jm().format(medication.administeredTime!.toDate())}',
//                 style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey),
//                 textAlign: TextAlign.right,
//               )
//             : IconButton(
//                 icon: const Icon(Icons.done_all, color: Colors.green),
//                 onPressed: () => _updateMedicationStatus(medication),
//               ),
//         isThreeLine: true,
//       ),
//     );
//   }
// }