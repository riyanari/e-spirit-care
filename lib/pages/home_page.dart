import 'package:e_spirit_care/pages/video_recomendation_page.dart';
import 'package:e_spirit_care/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/child_cubit.dart';
import '../models/child_model.dart';
import 'add_child_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? parentId;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _checkAuthState();
      _initParentAndChildren();
    });
  }

  Future<void> _initParentAndChildren() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      // Kalau entah kenapa user hilang, balikin ke login
      debugPrint('[HomePage] currentUser null → ke /login');
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    debugPrint('[HomePage] currentUser: ${firebaseUser.uid}');
    _loadChildren(firebaseUser.uid);
  }

  void _loadChildren(String userId) {
    debugPrint('[HomePage] _loadChildren dipanggil dengan parentId = $userId');

    if (parentId == userId) {
      debugPrint('[HomePage] parentId sama, tidak perlu reload');
      return;
    }

    setState(() {
      parentId = userId;
      _isInitialLoad = false;
    });

    context.read<ChildCubit>().loadChildren(parentId!);
  }


  void _goToAddChild() {
    if (parentId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ChildCubit>(), // Gunakan cubit yang sama
          child: AddChildPage(parentId: parentId!),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  int _countBalita(List<ChildModel> children) {
    return children.where((child) {
      final age = int.tryParse(child.umur) ?? 0;
      return age < 5;
    }).length;
  }

  // Tambahkan di class _HomePageState
  void _goToVideoRecommendations(ChildModel child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoRecommendationsPage(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          // Kalau tiba-tiba balik ke initial (misal setelah logout), arahkan ke login
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                // HEADER YANG DIPERBAIKI
                _buildEnhancedHeader(),
                const SizedBox(height: 20),

                if (_isInitialLoad || parentId == null)
                  _buildInitialLoading()
                else
                  BlocBuilder<ChildCubit, ChildState>(
                    builder: (context, state) {
                      if (state is ChildLoading) {
                        return _buildChildLoading();
                      }

                      if (state is ChildFailed) {
                        return _buildChildError(state.error);
                      }

                      if (state is ChildLoaded) {
                        final children = state.children;
                        if (children.isEmpty) return _emptyChildCard();

                        return Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats Card yang diperbarui
                              _buildStatsCard(children),
                              const SizedBox(height: 24),

                              // List Anak
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Daftar Anak Saya',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    '${children.length} Anak',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Expanded(
                                child: ListView(
                                  children: [
                                    ...children.map((child) => _buildChildCard(child)),
                                    const SizedBox(height: 16),
                                    _buildAddChildButton(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return _buildChildLoading();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo dan Nama App
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withValues(alpha:0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // child: Icon(
                //   Icons.family_restroom,
                //   color: Colors.white,
                //   size: 24,
                // ),
                child: Image.asset("assets/lg-spirit.png"),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "E-Spirit Care",
                    style: primaryTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: bold,
                    ),
                  ),
                  Text(
                    "Pendidikan Anak Islami",
                    style: greyTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: medium,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // User Info dan Logout
          GestureDetector(
            onTap: _showLogoutDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                Icons.logout,
                  color: kPrimaryColor,
                  size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(List<ChildModel> children) {
    final totalChildren = children.length;
    final balitaCount = _countBalita(children);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor.withValues(alpha:0.9),
            kPrimaryColor.withValues(alpha:0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha:0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEnhancedStatItem(
            totalChildren,
            'Total Anak',
            Icons.child_care,
            Colors.white.withValues(alpha:0.9),
          ),
          _buildDivider(),
          _buildEnhancedStatItem(
            balitaCount,
            'Usia Balita',
            Icons.favorite_border,
            Colors.white.withValues(alpha:0.9),
          ),
          _buildDivider(),
          _buildEnhancedStatItem(
            totalChildren - balitaCount,
            'Anak Besar',
            Icons.school,
            Colors.white.withValues(alpha:0.9),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem(int count, String label, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha:0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildInitialLoading() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menyiapkan data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildChildLoading() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data anak...'),
          ],
        ),
      ),
    );
  }

  Widget _buildChildError(String error) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: parentId == null ? null : () => context.read<ChildCubit>().loadChildren(parentId!),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF7F9FB)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha:0.1),
              shape: BoxShape.circle,
              border: Border.all(color: kPrimaryColor.withValues(alpha:0.3)),
            ),
            child: Icon(Icons.child_care, color: kPrimaryColor, size: 30),
          ),
          title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Usia: ${child.umur} tahun', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text('Username: ${child.username}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right, color: kPrimaryColor),
          ),
          onTap: () => _goToVideoRecommendations(child),
        ),
      ),
    );
  }

  Widget _buildAddChildButton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kPrimaryColor.withValues(alpha:0.2)),
      ),
      child: InkWell(
        onTap: _goToAddChild,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: kPrimaryColor.withValues(alpha:0.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: kPrimaryColor),
              const SizedBox(width: 8),
              Text('Tambah Anak Lainnya',
                  style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyChildCard() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.child_care, size: 80, color: kPrimaryColor),
            ),
            const SizedBox(height: 24),
            Text('Belum Ada Anak Terdaftar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            Text(
              'Tambahkan data anak Anda untuk memulai pemantauan perkembangan dan pendidikan agama',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToAddChild,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Tambahkan Anak Pertama',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}