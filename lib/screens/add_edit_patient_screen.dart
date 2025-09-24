// lib/screens/add_edit_patient_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_model.dart';
import '../models/notification_model.dart';
import '../services/patient_service.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart'; // เพิ่ม import นี้
import '../models/user_model.dart'; // เพิ่ม import นี้

class AddEditPatientScreen extends StatefulWidget {
  final Patient? patient;

  const AddEditPatientScreen({super.key, this.patient});

  @override
  State<AddEditPatientScreen> createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final PatientService _patientService = PatientService();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService(); // สร้าง instance ของ UserService

  late TextEditingController _nameController;
  late TextEditingController _notificationDetailController;
  
  String? _selectedBuilding;
  String? _selectedDepartment;
  String? _selectedNotificationType;
  TimeOfDay? _selectedNotificationTime;
  bool _isNPO = false;
  bool _isLoading = false;
  
  // เพิ่มตัวแปรสำหรับรายชื่อแพทย์
  List<User> _doctors = [];
  String? _selectedDoctorName;
  
  // รายการตึก
  final List<String> _buildings = ['A', 'B', 'C', 'D', 'E'];
  
  // รายการแผนก
  final List<String> _departments = [
    'แผนกผู้ป่วยนอก (OPD)',
    'แผนกผู้ป่วยใน (IPD)', 
    'แผนกฉุกเฉิน (ER)',
    'แผนกผ่าตัด (OR)',
    'แผนกห้องปฏิบัติการ',
    'แผนกรังสีและภาพวินิจฉัย',
    'แผนกกายภาพบำบัด',
    'แผนกเภสัชกรรม',
    'แผนกโภชนาการ',
    'แผนกบริหาร/ธุรการ'
  ];
  
  // รายการประเภทการแจ้งเตือน
  final List<String> _notificationTypes = [
    'การให้ยาและหัตถการ',
    'การตรวจร่างกายและประเมินอาการ', 
    'การดูแลช่วยเหลือผู้ป่วยในชีวิตประจำวัน',
    'การประสานงานกับทีมแพทย์และบุคลากรอื่น',
    'การเฝ้าระวังและป้องกันโรค/การติดเชื้อ'
  ];
  
  bool get isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.name);
    _notificationDetailController = TextEditingController();
    
    if (widget.patient != null) {
      final location = widget.patient!.location;
      for (String building in _buildings) {
        if (location.contains(building)) {
          _selectedBuilding = building;
          break;
        }
      }
      _selectedBuilding ??= _buildings.first;
    } else {
      _selectedBuilding = _buildings.first;
    }
    
    _selectedDepartment = widget.patient?.department ?? _departments.first;
    _isNPO = widget.patient?.isNPO ?? false;
    _selectedDoctorName = widget.patient?.doctorName;
    
    _fetchDoctors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notificationDetailController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    final doctorsStream = _userService.getUsers();
    final doctorsList = await doctorsStream.first;
    setState(() {
      _doctors = doctorsList;
      if (!isEditing && _doctors.isNotEmpty) {
        _selectedDoctorName = _doctors.first.name;
      }
    });
  }

  Future<String> _generateHN() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .orderBy('hn', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return '001001';
      }
      
      final lastHN = snapshot.docs.first.data()['hn'] as String;
      final nextNumber = int.parse(lastHN) + 1;
      return nextNumber.toString().padLeft(6, '0');
    } catch (e) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return (timestamp % 1000000).toString().padLeft(6, '0');
    }
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String hn;
        if (isEditing) {
          hn = widget.patient!.hn;
        } else {
          hn = await _generateHN();
        }

        final patient = Patient(
          id: widget.patient?.id,
          name: _nameController.text.trim(),
          hn: hn,
          location: 'ตึก $_selectedBuilding',
          doctorName: _selectedDoctorName!,
          department: _selectedDepartment!,
          isNPO: _isNPO,
        );

        String patientId;
        if (isEditing) {
          await _patientService.updatePatient(patient);
          patientId = patient.id!;
        } else {
          final docRef = await FirebaseFirestore.instance
              .collection('patients')
              .add(patient.toJson());
          patientId = docRef.id;
        }

        if (_selectedNotificationType != null && 
            _selectedNotificationTime != null &&
            _notificationDetailController.text.trim().isNotEmpty &&
            !isEditing) {
          await _createNotification(patientId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing ? 'แก้ไขข้อมูลผู้ป่วยสำเร็จ' : 'เพิ่มผู้ป่วยใหม่สำเร็จ',
                style: GoogleFonts.kanit(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e',
                style: GoogleFonts.kanit(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _createNotification(String patientId) async {
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedNotificationTime!.hour,
      _selectedNotificationTime!.minute,
    );

    final notification = NotificationItem(
      patientId: patientId,
      details: '${_selectedNotificationType!}: ${_notificationDetailController.text.trim()}',
      type: 'care',
      timestamp: Timestamp.fromDate(scheduledDateTime),
      isUrgent: false,
    );
    
    await _notificationService.addNotification(notification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'แก้ไขข้อมูลผู้ป่วย' : 'เพิ่มผู้ป่วยใหม่',
          style: GoogleFonts.kanit(),
        ),
        backgroundColor: const Color.fromARGB(255, 163, 200, 242),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextField('ชื่อ-นามสกุล', Icons.person_outline, _nameController),
              
              if (isEditing) 
                _buildReadOnlyField('เลข HN', Icons.medical_services_outlined, widget.patient!.hn)
              else
                _buildInfoCard('เลข HN จะถูกสร้างอัตโนมัติหลังจากบันทึกข้อมูล', Icons.info_outline),
              
              _buildBuildingDropdown(),
              _buildDepartmentDropdown(),
              _buildDoctorDropdown(), // ใช้ Dropdown แทน TextField
              _buildNPOCheckbox(),
              
              // ส่วนการแจ้งเตือน (สำหรับผู้ป่วยใหม่เท่านั้น)
              if (!isEditing) ...[
                const SizedBox(height: 16),
                Text(
                  'การตั้งแจ้งเตือน (ไม่บังคับ)',
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 32, 124, 191),
                  ),
                ),
                const SizedBox(height: 16),
                _buildNotificationTypeDropdown(),
                if (_selectedNotificationType != null) ...[
                  _buildTimePicker(),
                  _buildTextField(
                    'รายละเอียดการแจ้งเตือน',
                    Icons.description_outlined,
                    _notificationDetailController,
                    maxLines: 3,
                  ),
                ],
              ],
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 32, 124, 191),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'บันทึกการแก้ไข' : 'บันทึกผู้ป่วย',
                        style: GoogleFonts.kanit(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    IconData icon, 
    TextEditingController controller, {
    int maxLines = 1
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.kanit(),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'กรุณากรอกข้อมูล' : null,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.kanit(),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.kanit(color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedBuilding,
        decoration: InputDecoration(
          labelText: 'ตึก',
          prefixIcon: const Icon(Icons.domain_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _buildings.map((building) => 
          DropdownMenuItem(
            value: building,
            child: Text('ตึก $building', style: GoogleFonts.kanit()),
          )
        ).toList(),
        onChanged: (val) => setState(() => _selectedBuilding = val),
        validator: (v) => v == null ? 'กรุณาเลือกตึก' : null,
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedDepartment,
        decoration: InputDecoration(
          labelText: 'แผนก',
          prefixIcon: const Icon(Icons.business_center_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _departments.map((dept) => 
          DropdownMenuItem(
            value: dept,
            child: Text(dept, style: GoogleFonts.kanit()),
          )
        ).toList(),
        onChanged: (val) => setState(() => _selectedDepartment = val),
        validator: (v) => v == null ? 'กรุณาเลือกแผนก' : null,
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedDoctorName,
        decoration: InputDecoration(
          labelText: 'แพทย์เจ้าของไข้',
          prefixIcon: const Icon(Icons.local_hospital_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _doctors.map((doctor) => 
          DropdownMenuItem(
            value: doctor.name,
            child: Text('${doctor.name} (${doctor.position})', style: GoogleFonts.kanit()),
          )
        ).toList(),
        onChanged: (val) => setState(() => _selectedDoctorName = val),
        validator: (v) => v == null ? 'กรุณาเลือกแพทย์' : null,
      ),
    );
  }

  Widget _buildNotificationTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedNotificationType,
        decoration: InputDecoration(
          labelText: 'ประเภทการแจ้งเตือน',
          prefixIcon: const Icon(Icons.notifications_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('เลือกประเภทการแจ้งเตือน', style: TextStyle(color: Colors.grey)),
          ),
          ..._notificationTypes.map((type) => 
            DropdownMenuItem(
              value: type,
              child: Text(type, style: GoogleFonts.kanit()),
            )
          ).toList(),
        ],
        onChanged: (val) => setState(() {
          _selectedNotificationType = val;
          if (val == null) {
            _selectedNotificationTime = null;
            _notificationDetailController.clear();
          }
        }),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(
          _selectedNotificationTime == null
              ? 'เลือกเวลาแจ้งเตือน'
              : 'เวลา: ${_selectedNotificationTime!.format(context)}',
          style: GoogleFonts.kanit(),
        ),
        leading: const Icon(Icons.access_time_outlined),
        trailing: const Icon(Icons.keyboard_arrow_down),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: Colors.white,
        onTap: () async {
          final TimeOfDay? newTime = await showTimePicker(
            context: context,
            initialTime: _selectedNotificationTime ?? TimeOfDay.now(),
          );
          if (newTime != null) {
            setState(() {
              _selectedNotificationTime = newTime;
            });
          }
        },
      ),
    );
  }
  
  Widget _buildNPOCheckbox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: CheckboxListTile(
        title: Text('งดน้ำ-อาหาร (NPO)', style: GoogleFonts.kanit()),
        secondary: const Icon(Icons.no_food_outlined),
        value: _isNPO,
        onChanged: (val) => setState(() => _isNPO = val!),
      ),
    );
  }
}