// lib/screens/patient_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';
import 'add_edit_patient_screen.dart';
import 'dart:async';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final PatientService _patientService = PatientService();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  String _selectedBuilding = 'ทุกตึก';
  String _selectedDepartment = 'ทุกแผนก';
  String _searchQuery = '';

  final List<String> _buildings = [ 'ทุกตึก', 'ตึก A', 'ตึก B', 'ตึก C', 'ตึก D', 'ตึก E' ];
  final List<String> _departments = [ 'ทุกแผนก', 'แผนกผู้ป่วยนอก (OPD)', 'แผนกผู้ป่วยใน (IPD)', 'แผนกฉุกเฉิน (ER)', 'แผนกผ่าตัด (OR)', 'แผนกห้องปฏิบัติการ', 'แผนกรังสีและภาพวินิจฉัย', 'แผนกกายภาพบำบัด', 'แผนกสูตินรีเวช', 'แผนกกุมารเวช', 'แผนกอายุรกรรม', 'แผนกศัลยกรรม' ];
  
  late Stream<List<Patient>> _patientsStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _debouncer.run(() {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text;
            _updateStream();
          });
        }
      });
    });
    _updateStream();
  }
  
  void _updateStream() {
    setState(() {
      _patientsStream = _patientService.getPatients(
        building: _selectedBuilding,
        department: _selectedDepartment,
        searchQuery: _searchQuery,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _deletePatient(String patientId, String patientName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Text("ยืนยันการลบ", style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("คุณต้องการลบข้อมูลผู้ป่วย \"$patientName\" ใช่หรือไม่?\nการดำเนินการนี้ไม่สามารถยกเลิกได้", style: GoogleFonts.kanit()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("ยกเลิก", style: GoogleFonts.kanit(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("ลบ", style: GoogleFonts.kanit()),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _patientService.deletePatient(patientId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบผู้ป่วย "$patientName" สำเร็จ', style: GoogleFonts.kanit()),
            backgroundColor: Colors.green,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditPatientScreen(),
            ),
          );
          if (result == true && mounted) {
            // The stream will automatically update, no need to call _fetchPatients
          }
        },
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Patient>>(
        stream: _patientsStream,
        builder: (context, snapshot) {
          final patients = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(patients.length),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildFilterSection(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: _buildPatientList(snapshot),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(int patientCount) {
    const Color accentColor = Color(0xFF0D47A1);

    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 2,
      backgroundColor: Colors.white,
      foregroundColor: accentColor,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final top = constraints.biggest.height;
          final isCollapsed = top <= MediaQuery.of(context).padding.top + kToolbarHeight;

          return FlexibleSpaceBar(
            centerTitle: true,
            title: isCollapsed
                ? Text('รายชื่อผู้ป่วย', style: GoogleFonts.kanit(color: accentColor, fontWeight: FontWeight.bold))
                : null,
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                   decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFBAE2FF).withOpacity(0.8),
                        const Color(0xFF81D4FA).withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -20,
                  right: -30,
                  child: Icon(Icons.medical_information_rounded, size: 150, color: Colors.white.withOpacity(0.3)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายชื่อผู้ป่วย',
                        style: GoogleFonts.kanit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                       Text(
                        'ทั้งหมด $patientCount คน',
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          color: accentColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildSearchBar(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.kanit(),
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อ หรือ HN...',
          hintStyle: GoogleFonts.kanit(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(_selectedBuilding, _buildings, (val) {
            setState(() {
              _selectedBuilding = val!;
              _updateStream();
            });
          }, 'ตึก'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(_selectedDepartment, _departments, (val) {
            setState(() {
              _selectedDepartment = val!;
              _updateStream();
            });
          }, 'แผนก'),
        ),
      ],
    );
  }
  
  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged, String label) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String val) {
        return DropdownMenuItem<String>(
          value: val,
          child: Text(val, style: GoogleFonts.kanit(), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.kanit(),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0D47A1)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildPatientList(AsyncSnapshot<List<Patient>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }
    if (snapshot.hasError) {
      return SliverFillRemaining(child: Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: GoogleFonts.kanit(color: Colors.red))));
    }
    final patients = snapshot.data ?? [];
    if (patients.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('ไม่พบข้อมูลผู้ป่วย', style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }
    return AnimationLimiter(
      child: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final patient = patients[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ScaleAnimation(child: _buildPatientCard(patient)),
              ),
            ),
          );
        }, childCount: patients.length),
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    const accentColor = Color(0xFF0D47A1);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddEditPatientScreen(patient: patient)),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Expanded(
                            child: Text(
                              patient.name,
                              style: GoogleFonts.kanit(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'HN: ${patient.hn}',
                            style: GoogleFonts.kanit(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _buildPatientDetail(Icons.apartment_rounded, patient.building),
                      const SizedBox(height: 8),
                      _buildPatientDetail(Icons.local_hospital_rounded, patient.department),
                       if(patient.doctor.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildPatientDetail(Icons.medical_services_rounded, patient.doctor),
                      ]
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _deletePatient(patient.id!, patient.name),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.grey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}