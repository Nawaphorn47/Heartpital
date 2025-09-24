// lib/screens/patient_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_model.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  widget.patient.name,
                  style: GoogleFonts.kanit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Hero(
                      tag: 'avatar-${widget.patient.id}',
                      child: Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.person, size: 100, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Text(
                          'HN: ${widget.patient.hn}',
                          style: GoogleFonts.kanit(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.kanit(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.kanit(),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'ข้อมูลส่วนตัว'),
                    Tab(text: 'ตารางยา'),
                    Tab(text: 'ประวัติ'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(widget.patient),
            _buildMedicationTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(Patient patient) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile(Icons.medical_services_outlined, 'แพทย์เจ้าของไข้', 'นพ. ${patient.doctorName}'),
          _buildInfoTile(Icons.location_on_outlined, 'ตึก', patient.location),
          _buildInfoTile(Icons.business_center_outlined, 'แผนก', patient.department),
        ],
      ),
    );
  }

  Widget _buildMedicationTab() {
    return const Center(child: Text('กำลังจะเชื่อมต่อกับหน้าตารางยา...', style: TextStyle(fontFamily: 'Kanit')));
  }

  Widget _buildHistoryTab() {
    return const Center(child: Text('กำลังจะสร้างประวัติการรักษา...', style: TextStyle(fontFamily: 'Kanit')));
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.kanit()),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}