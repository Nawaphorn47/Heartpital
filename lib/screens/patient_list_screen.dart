import 'package:flutter/material.dart';
//import 'package:animated_text_kit/animated_text_kit.dart';
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

  String _selectedBuilding = 'ทุกตึก';
  String _selectedDepartment = 'ทุกแผนก';
  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _buildings = [
    'ทุกตึก', 'ตึก A', 'ตึก B', 'ตึก C', 'ตึก D', 'ตึก E',
  ];

  final List<String> _departments = [
    'ทุกแผนก', 'แผนกผู้ป่วยนอก (OPD)', 'แผนกผู้ป่วยใน (IPD)', 'แผนกฉุกเฉิน (ER)', 'แผนกผ่าตัด (OR)',
    'แผนกห้องปฏิบัติการ', 'แผนกรังสีและภาพวินิจฉัย', 'แผนกกายภาพบำบัด', 'แผนกสูตินรีเวช', 'แผนกกุมารเวช',
    'แผนกอายุรกรรม', 'แผนกศัลยกรรม',
  ];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPatients);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    try {
      final patients = await _patientService.getPatients().first;
      setState(() {
        _allPatients = patients;
        _isLoading = false;
        _filterPatients();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        final matchesSearch = patient.name.toLowerCase().contains(query) || patient.hn.toLowerCase().contains(query);
        final matchesBuilding = _selectedBuilding == 'ทุกตึก' || patient.building == _selectedBuilding;
        final matchesDepartment = _selectedDepartment == 'ทุกแผนก' || patient.department == _selectedDepartment;
        return matchesSearch && matchesBuilding && matchesDepartment;
      }).toList();
    });
  }

  Future<bool?> _showDeleteConfirmation(String patientId, String patientName) {
     return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "ยืนยันการลบ",
                style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            "คุณต้องการลบข้อมูลผู้ป่วย \"$patientName\" ใช่หรือไม่?\n\nการดำเนินการนี้ไม่สามารถยกเลิกได้",
           style: GoogleFonts.kanit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "ยกเลิก",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _patientService.deletePatient(patientId);
                _fetchPatients();
                if (mounted) Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                "ลบ",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const AddEditPatientScreen(),
                ),
              )
              .then((value) {
                if (value == true) {
                  _fetchPatients();
                }
              });
        },
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: _buildFilterSection(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            sliver: _buildPatientList(context),
          ),
        ],
      ),
    );
  }

   Widget _buildSliverAppBar(BuildContext context) {
    const Color accentColor = Color(0xFF0D47A1);

    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFBAE2FF), // สีพื้นหลังสุดท้ายเมื่อหดสุด
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // --- 1. พื้นหลัง Gradient และไอคอนตกแต่ง ---
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFBAE2FF),
                    const Color(0xFF81D4FA).withOpacity(0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -20,
              right: -30,
              child: Icon(
                Icons.medical_information_rounded,
                size: 150,
                color: Colors.white.withOpacity(0.2),
              ),
            ),

            // --- 2. สร้าง Widget ที่จะ Cross-Fade ตามการเลื่อน ---
            Builder(
              builder: (BuildContext context) {
                // ดึงค่าสถานะการยืด-หดของ FlexibleSpaceBar
                final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
                final double t = (settings.currentExtent - settings.minExtent) / (settings.maxExtent - settings.minExtent);
                final double clampedT = t.clamp(0.0, 1.0);

                return Stack(
                  children: [
                    // --- Layout ตอนหด (จะค่อยๆชัดขึ้นเมื่อ t -> 0) ---
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 1.0 - clampedT, // จางลงเมื่อขยาย
                        child: Container(
                          height: settings.minExtent, // ความสูงเท่ากับ App Bar ตอนหด
                          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top), // กัน status bar
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              //const Icon(Icons.groups_2_outlined, color: accentColor, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '',
                                  style: GoogleFonts.kanit(
                                    color: accentColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // IconButton(
                              //   onPressed: () {},
                              //  // icon: const Icon(Icons.swap_vert, color: accentColor),
                              // ),
                              // IconButton(
                              //   onPressed: () {},
                              //   icon: const Icon(Icons.more_vert, color: accentColor),
                              // ),
                              // const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- Layout ตอนขยาย (จะค่อยๆชัดขึ้นเมื่อ t -> 1) ---
                    Positioned(
                      top: settings.minExtent,
                      left: 0,
                      right: 0,
                      bottom: 65, // เว้นที่ให้ Search bar
                      child: Opacity(
                        opacity: clampedT, // จางลงเมื่อหด
                        child: Center(
                          child: Text(
                            'ข้อมูลผู้ป่วย',
                            style: GoogleFonts.kanit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // --- 3. Search Bar อยู่ตำแหน่งเดิม ---
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildSearchBar(context),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.kanit(),
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อหรือ HN...',
          hintStyle: GoogleFonts.kanit(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0D47A1)),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedBuilding,
            items:
                _buildings.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.kanit()),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedBuilding = newValue!;
                _filterPatients();
              });
            },
            decoration: InputDecoration(
              labelText: 'ตึก',
              labelStyle: GoogleFonts.kanit(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDepartment,
            items:
                _departments.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.kanit()),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedDepartment = newValue!;
                _filterPatients();
              });
            },
            decoration: InputDecoration(
              labelText: 'แผนก',
              labelStyle: GoogleFonts.kanit(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientList(BuildContext context) {
    if (_isLoading) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(child: Center(child: Text(_errorMessage!, style: GoogleFonts.kanit(color: Colors.red))));
    }

    if (_filteredPatients.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('ไม่พบข้อมูลผู้ป่วย', style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final patient = _filteredPatients[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ScaleAnimation( // เพิ่ม ScaleAnimation
                  child: _buildPatientCard(context, patient, index),
                ),
              ),
            ),
          );
        }, childCount: _filteredPatients.length),
      ),
    );
  }


  Widget _buildPatientCard(BuildContext context, Patient patient, int index) {
    const accentColor = Color(0xFF0D47A1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // เพิ่ม Gradient ให้การ์ดมีมิติมากขึ้น
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),// เงาอ่อน
            blurRadius: 18,
            offset: const Offset(0, 4),// เงาด้านล่าง
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.2),// เงาสีฟ้าอ่อน
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 15),// เงาด้านล่างเพื่อเพิ่มมิติ
          )
        ],
      ),
      child: Material(
        color: const Color.fromARGB(0, 219, 215, 215),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),// ทำให้ปุ่มมีมุมโค้งเหมือนการ์ด
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddEditPatientScreen(patient: patient),
              ),
            );
            if (result == true) {
              _fetchPatients();
            }
          },
          // ใช้ Stack เพื่อจัดวางปุ่มลบใหม่
          child: Stack(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      decoration: const BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 40, 12), // เพิ่ม padding ขวาให้ปุ่มไม่ทับเนื้อหา
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: accentColor.withOpacity(0.1),
                                  child: Icon(Icons.person_outline_rounded, size: 28, color: accentColor),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'HN: ${patient.hn}',
                                    style: GoogleFonts.kanit(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              patient.name,
                              style: GoogleFonts.kanit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _buildPatientDetail(context, Icons.apartment, patient.building ?? ''),
                            _buildPatientDetail(context, Icons.local_hospital, patient.department),
                            _buildPatientDetail(context, Icons.medical_services, patient.doctor ?? ''),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // วางปุ่มลบไว้มุมบนขวาด้วย Positioned
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    final confirmed = await _showDeleteConfirmation(patient.id!, patient.name);
                    if (confirmed == true) {
                      _fetchPatients();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPatientDetail(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0D47A1).withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: const Color(0xFF0D47A1).withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}