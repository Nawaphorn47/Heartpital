// ... (โค้ดส่วนบนของ patient_list_screen.dart เหมือนเดิม)

// แก้ไขเฉพาะ Widget _buildPatientCard
Widget _buildPatientCard(Patient patient) {
    final bool isCompleted = patient.status == 'เสร็จสิ้น';

    // [MODIFIED] เปลี่ยนสีตามสถานะ "เสร็จสิ้น"
    final Color accentColor = isCompleted ? Colors.grey.shade600 : Color(0xFF0D47A1);
    final IconData statusIcon = isCompleted ? Icons.check_circle : Icons.pending_actions;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PatientDetailScreen(patient: patient),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accentColor,
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
                              style: GoogleFonts.kanit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                                // ขีดฆ่าถ้าเสร็จแล้ว
                                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none, 
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('HN: ${patient.hn}', style: GoogleFonts.kanit(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.5),
                      _buildPatientDetail(Icons.apartment_rounded, patient.building),
                      const SizedBox(height: 8),
                      _buildPatientDetail(Icons.local_hospital_rounded, patient.department),
                      const SizedBox(height: 8),
                      _buildPatientDetail(statusIcon, patient.status, color: accentColor),
                    ],
                  ),
                ),
              ),
              // [MODIFIED] เปลี่ยนปุ่ม "รับเคส" เป็น "เสร็จสิ้น"
              if (!isCompleted)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  tooltip: 'ทำเครื่องหมายว่าเสร็จสิ้น',
                  onPressed: () async {
                    await _patientService.updatePatientStatus(patient.id!, 'เสร็จสิ้น');
                  },
                )
              else 
                 IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: 'ลบผู้ป่วย',
                  onPressed: () => _deletePatient(patient.id!, patient.name),
                ),
            ],
          ),
        ),
      ),
    );
}

// [MODIFIED] แก้ไข _buildPatientDetail ให้รับสีได้
Widget _buildPatientDetail(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.kanit(fontSize: 14, color: color ?? Colors.grey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
}