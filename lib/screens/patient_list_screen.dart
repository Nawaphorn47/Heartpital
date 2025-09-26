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

  String _selectedBuilding = 'ทุกตึก';
  String _selectedDepartment = 'ทุกแผนก';
  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _buildings = [ 'ทุกตึก', 'ตึก A', 'ตึก B', 'ตึก C', 'ตึก D', 'ตึก E' ];
  final List<String> _departments = [ 'ทุกแผนก', 'แผนกผู้ป่วยนอก (OPD)', 'แผนกผู้ป่วยใน (IPD)', 'แผนกฉุกเฉิน (ER)', 'แผนกผ่าตัด (OR)', 'แผนกห้องปฏิบัติการ', 'แผนกรังสีและภาพวินิจฉัย', 'แผนกกายภาพบำบัด', 'แผนกสูตินรีเวช', 'แผนกกุมารเวช', 'แผนกอายุรกรรม', 'แผนกศัลยกรรม' ];

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
              onPressed: () async {
                await _patientService.deletePatient(patientId);
                // _fetchPatients(); // Removed to prevent double call
                if (mounted) Navigator.of(context).pop(true);
              },
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
          _buildSliverAppBar(), // ใช้ AppBar ที่ปรับปรุงแล้ว
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildFilterSection(), // ใช้ Filter ที่ปรับปรุงแล้ว
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: _buildPatientList(),
          ),
        ],
      ),
    );
  }

  // ⭐️ [IMPROVED] ปรับปรุง SliverAppBar ใหม่ทั้งหมด
  Widget _buildSliverAppBar() {
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
                        'ทั้งหมด ${_filteredPatients.length} คน',
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

  // ⭐️ [IMPROVED] ปรับปรุงดีไซน์ Search Bar
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
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  // ⭐️ [IMPROVED] ปรับปรุงดีไซน์ Filter
  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(_selectedBuilding, _buildings, (val) {
            setState(() {
              _selectedBuilding = val!;
              _filterPatients();
            });
          }, 'ตึก'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(_selectedDepartment, _departments, (val) {
            setState(() {
              _selectedDepartment = val!;
              _filterPatients();
            });
          }, 'แผนก'),
        ),
      ],
    );
  }
  
  // ⭐️ [NEW] Helper widget for Dropdown to reduce code duplication
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

  Widget _buildPatientList() {
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
              Text('ไม่พบข้อมูลผู้ป่วยที่ตรงกัน', style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey.shade600)),
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
                child: ScaleAnimation(child: _buildPatientCard(patient)),
              ),
            ),
          );
        }, childCount: _filteredPatients.length),
      ),
    );
  }

  // ⭐️ [IMPROVED] ปรับปรุง Patient Card ใหม่ทั้งหมด
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
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddEditPatientScreen(patient: patient)),
          );
          if (result == true) {
            _fetchPatients();
          }
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
                      _buildPatientDetail(Icons.apartment_rounded, patient.building ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildPatientDetail(Icons.local_hospital_rounded, patient.department),
                       if(patient.doctor != null && patient.doctor!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildPatientDetail(Icons.medical_services_rounded, patient.doctor!),
                      ]
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () async {
                  final confirmed = await _showDeleteConfirmation(patient.id!, patient.name);
                  if (confirmed == true) {
                    _fetchPatients();
                  }
                },
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