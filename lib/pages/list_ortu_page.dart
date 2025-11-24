import 'package:flutter/material.dart';
import 'package:e_spirit_care/models/user_model.dart';
import 'package:e_spirit_care/services/user_services.dart';
import 'package:e_spirit_care/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:e_spirit_care/pages/list_child_page.dart';
import 'package:e_spirit_care/pages/add_nurse_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

class ListOrtuPage extends StatefulWidget {
  final String? currentUserRole; // Tambahkan parameter untuk role

  const ListOrtuPage({super.key, this.currentUserRole});

  @override
  State<ListOrtuPage> createState() => _ListOrtuPageState();
}

class _ListOrtuPageState extends State<ListOrtuPage> with SingleTickerProviderStateMixin {
  late Future<List<UserModel>> _ortuFuture;
  late Future<List<UserModel>> _perawatFuture;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredOrtuList = [];
  List<UserModel> _originalOrtuList = [];
  List<UserModel> _filteredPerawatList = [];
  List<UserModel> _originalPerawatList = [];

  late TabController _tabController;
  int _currentTabIndex = 0;

  // Getter untuk cek apakah user adalah admin
  bool get _isAdmin => widget.currentUserRole?.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    debugPrint('[ListOrtuPage] initState → load ortu (role: ortu)');
    debugPrint('[ListOrtuPage] Current user role: ${widget.currentUserRole}');

    // Jika admin, buat 2 tab. Jika bukan, hanya 1 tab
    final tabCount = _isAdmin ? 2 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _loadData();
  }

  void _loadData() {
    _ortuFuture = UserServices().getUsersByRole('ortu').then((ortuList) {
      _originalOrtuList = ortuList;
      _filteredOrtuList = ortuList;
      return ortuList;
    });

    // Hanya load data perawat jika admin
    if (_isAdmin) {
      _perawatFuture = UserServices().getUsersByRole('perawat').then((perawatList) {
        _originalPerawatList = perawatList;
        _filteredPerawatList = perawatList;
        return perawatList;
      });
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  void _filterOrtu(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredOrtuList = _originalOrtuList;
      });
    } else {
      setState(() {
        _filteredOrtuList = _originalOrtuList.where((ortu) {
          final name = ortu.name.toLowerCase();
          final username = ortu.username.toLowerCase();
          final email = ortu.email.toLowerCase();
          final hp = ortu.hp.toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              username.contains(searchLower) ||
              email.contains(searchLower) ||
              hp.contains(searchLower);
        }).toList();
      });
    }
  }

  void _filterPerawat(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPerawatList = _originalPerawatList;
      });
    } else {
      setState(() {
        _filteredPerawatList = _originalPerawatList.where((perawat) {
          final name = perawat.name.toLowerCase();
          final username = perawat.username.toLowerCase();
          final email = perawat.email.toLowerCase();
          final hp = perawat.hp.toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              username.contains(searchLower) ||
              email.contains(searchLower) ||
              hp.contains(searchLower);
        }).toList();
      });
    }
  }

  void _navigateToAddNurse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNursePage(),
      ),
    ).then((_) {
      // Refresh data setelah kembali dari tambah perawat
      _loadData();
      setState(() {});
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    context.read<AuthCubit>().signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isAdmin ? 'Manajemen Pengguna' : 'Daftar Orang Tua',
          style: const TextStyle(
            color: kWhiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kWhiteColor),
        // Tambahkan actions untuk logout
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kWhiteColor),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
        // Hanya tampilkan TabBar jika admin
        bottom: _isAdmin
            ? TabBar(
          controller: _tabController,
          indicatorColor: kWhiteColor,
          labelColor: kWhiteColor,
          unselectedLabelColor: kWhiteColor.withValues(alpha:0.7),
          tabs: const [
            Tab(text: 'Orang Tua'),
            Tab(text: 'Perawat'),
          ],
        )
            : null,
      ),
      // Hanya tampilkan FAB jika admin dan di tab perawat
      floatingActionButton: _isAdmin && _currentTabIndex == 1
          ? FloatingActionButton(
        onPressed: _navigateToAddNurse,
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: kWhiteColor),
      )
          : null,
      body: _isAdmin
          ? TabBarView(
        controller: _tabController,
        children: [
          // Tab Orang Tua untuk admin
          _buildOrtuTab(),
          // Tab Perawat untuk admin
          _buildPerawatTab(),
        ],
      )
          : _buildOrtuTab(), // Untuk non-admin, langsung tampilkan tab orang tua
    );
  }

  // ... (method _buildOrtuTab, _buildPerawatTab, _buildLoadingState, dll. tetap sama)

  Widget _buildOrtuTab() {
    return Column(
      children: [
        // Search Bar untuk Orang Tua
        Container(
          padding: const EdgeInsets.all(16),
          color: kBackgroundColor,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterOrtu,
              decoration: InputDecoration(
                hintText: 'Cari orang tua...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.search,
                  color: kPrimaryColor,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterOrtu('');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),

        // Results Count untuk Orang Tua
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredOrtuList.length} Orang Tua Ditemukan',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List Content untuk Orang Tua
        Expanded(
          child: FutureBuilder<List<UserModel>>(
            future: _ortuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString(), true);
              }

              final ortuList = _filteredOrtuList;

              if (ortuList.isEmpty) {
                return _buildEmptyState(true);
              }

              return _buildOrtuList(ortuList);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPerawatTab() {
    return Column(
      children: [
        // Search Bar untuk Perawat
        Container(
          padding: const EdgeInsets.all(16),
          color: kBackgroundColor,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: _filterPerawat,
              decoration: InputDecoration(
                hintText: 'Cari perawat...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.search,
                  color: kPrimaryColor,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),

        // Results Count untuk Perawat
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredPerawatList.length} Perawat Ditemukan',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List Content untuk Perawat
        Expanded(
          child: FutureBuilder<List<UserModel>>(
            future: _perawatFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString(), false);
              }

              final perawatList = _filteredPerawatList;

              if (perawatList.isEmpty) {
                return _buildEmptyState(false);
              }

              return _buildPerawatList(perawatList);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            title: Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, bool isOrtu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.orange.shade400,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isOrtu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOrtu ? Icons.people_outline : Icons.medical_services_outlined,
              color: Colors.grey.shade400,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              isOrtu
                  ? 'Belum ada data orang tua'
                  : 'Belum ada data perawat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOrtu
                  ? 'Data orang tua akan muncul di sini'
                  : 'Tekan tombol + untuk menambah perawat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrtuList(List<UserModel> ortuList) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ortuList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = ortuList[index];
        return _buildUserCard(user, true);
      },
    );
  }

  Widget _buildPerawatList(List<UserModel> perawatList) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: perawatList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = perawatList[index];
        return _buildUserCard(user, false);
      },
    );
  }

  Widget _buildUserCard(UserModel user, bool isOrtu) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isOrtu ? () {
            debugPrint('[ListOrtuPage] Tap ortu: ${user.id} - ${user.name}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListChildPage(parent: user),
              ),
            );
          } : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kPrimaryColor.withValues(alpha:0.8),
                        kPrimaryColor.withValues(alpha:0.4),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOrtu ? Icons.person : Icons.medical_services,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.username,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (_isAdmin) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isOrtu
                                    ? Colors.blue.withValues(alpha:0.1)
                                    : Colors.green.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOrtu ? 'Orang Tua' : 'Perawat',
                                style: TextStyle(
                                  color: isOrtu ? Colors.blue : Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (user.email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (user.hp.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.hp,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron Icon (hanya untuk orang tua)
                if (isOrtu)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: kPrimaryColor,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}