import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../components/loading_button.dart';
import '../theme/theme.dart';

class AddNursePage extends StatefulWidget {
  const AddNursePage({super.key});

  @override
  State<AddNursePage> createState() => _AddNursePageState();
}

class _AddNursePageState extends State<AddNursePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController umurController = TextEditingController();
  final TextEditingController hpController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool kunciPassword = true;
  bool isNameError = false;
  bool isUsernameError = false;
  bool isPasswordError = false;
  bool isUmurError = false;
  bool isHpError = false;
  bool isEmailError = false;
  String? _signupError;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    umurController.dispose();
    hpController.dispose();
    emailController.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => kunciPassword = !kunciPassword);
  }

  void _addNurse() {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final umur = umurController.text.trim();
    final hp = hpController.text.trim();
    final email = emailController.text.trim();

    setState(() {
      isNameError = name.isEmpty;
      isUsernameError = username.isEmpty;
      isPasswordError = password.isEmpty;
      isUmurError = umur.isEmpty;
      isHpError = hp.isEmpty;
      isEmailError = email.isEmpty;
      _signupError = null;
    });

    // 👇 VALIDASI FORMAT USERNAME
    if (username.contains(' ')) {
      setState(() {
        isUsernameError = true;
        _signupError = 'Username tidak boleh mengandung spasi';
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        isUsernameError = true;
        _signupError = 'Username minimal 3 karakter';
      });
      return;
    }

    if (!isNameError &&
        !isUsernameError &&
        !isPasswordError &&
        !isUmurError &&
        !isHpError &&
        !isEmailError) {
      context.read<AuthCubit>().signUp(
        name: name,
        username: username,
        password: password,
        umur: umur,
        pekerjaan: 'Perawat',       // default pekerjaan
        hp: hp,
        email: email,
        role: 'perawat',            // role khusus perawat

        // ✅ field tambahan kita isi string kosong
        jenisKelamin: '',
        statusPerkawinan: '',
        pendidikan: '',
        alamat: '',
        hubunganAnak: '',
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthFailed) {
          setState(() => _signupError = state.error);
        } else if (state is AuthSuccess) {
          // Tampilkan snackbar sukses dan kembali ke halaman sebelumnya
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Perawat ${state.user.name} berhasil ditambahkan',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Tambah Perawat',
            style: TextStyle(
              color: kWhiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: kPrimaryColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: kWhiteColor),
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              child: Stack(
                children: [
                  _formAddNurse(context, isLoading),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _formAddNurse(BuildContext context, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services,
                  color: kPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tambah Data Perawat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Isi form berikut untuk menambah perawat baru',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Name
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              hintText: 'Masukkan Nama Lengkap Perawat',
              errorText: isNameError ? 'Nama harus diisi' : null,
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(usernameFocus);
            },
          ),
          const SizedBox(height: 15),

          // Username
          TextFormField(
            controller: usernameController,
            focusNode: usernameFocus,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Masukkan Username untuk login',
              errorText: isUsernameError ? 'Username harus diisi' : null,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(passwordFocus);
            },
          ),
          const SizedBox(height: 15),

          // Password
          TextFormField(
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: kunciPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Masukkan Password untuk login',
              errorText: isPasswordError ? 'Password harus diisi' : null,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: GestureDetector(
                onTap: _togglePasswordVisibility,
                child: Icon(
                  kunciPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),

          // Umur
          TextFormField(
            controller: umurController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Umur',
              hintText: 'Masukkan Umur Perawat',
              errorText: isUmurError ? 'Umur harus diisi' : null,
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),

          // HP
          TextFormField(
            controller: hpController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nomor HP',
              hintText: 'Masukkan Nomor HP Perawat',
              errorText: isHpError ? 'Nomor HP harus diisi' : null,
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 15),

          // Email
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Masukkan Email Perawat',
              errorText: isEmailError ? 'Email harus diisi' : null,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 25),

          // Role & Pekerjaan Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Informasi Akun:',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '• Role: Perawat',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '• Pekerjaan: Perawat',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Error message display
          if (_signupError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _signupError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade600, size: 16),
                    onPressed: () => setState(() => _signupError = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ],
              ),
            ),

          // Add Nurse Button
          isLoading
              ? const LoadingButton()
              : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kWhiteColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(16.0),
              ),
              onPressed: _addNurse,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Tambah Perawat",
                    style: whiteTextStyle.copyWith(
                      fontWeight: extraBold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(16.0),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Batal",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}