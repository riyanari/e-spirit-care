import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../components/loading_button.dart';
import '../theme/theme.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController umurController = TextEditingController();
  final TextEditingController pekerjaanController = TextEditingController();
  final TextEditingController hpController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pendidikanController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController hubunganAnakController = TextEditingController();

  String? selectedGender;           // 👈 untuk jenis kelamin
  String? selectedStatusPerkawinan; // 👈 untuk status perkawinan

  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool kunciPassword = true;
  bool isNameError = false;
  bool isUsernameError = false;
  bool isPasswordError = false;
  bool isUmurError = false;
  bool isPekerjaanError = false;
  bool isHpError = false;
  bool isEmailError = false;
  String? _signupError;
  bool isJenisKelaminError = false;
  bool isStatusPerkawinanError = false;
  bool isPendidikanError = false;
  bool isAlamatError = false;
  bool isHubunganAnakError = false;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    umurController.dispose();
    pekerjaanController.dispose();
    hpController.dispose();
    emailController.dispose();
    pendidikanController.dispose();      // 👈 NEW
    alamatController.dispose();          // 👈 NEW
    hubunganAnakController.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => kunciPassword = !kunciPassword);
  }

  void _signUp() {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final umur = umurController.text.trim();
    final pekerjaan = pekerjaanController.text.trim();
    final hp = hpController.text.trim();
    final email = emailController.text.trim();
    final pendidikan = pendidikanController.text.trim();
    final alamat = alamatController.text.trim();
    final hubunganAnak = hubunganAnakController.text.trim();

    setState(() {
      isNameError = name.isEmpty;
      isUsernameError = username.isEmpty;
      isPasswordError = password.isEmpty;
      isUmurError = umur.isEmpty;
      isPekerjaanError = pekerjaan.isEmpty;
      isHpError = hp.isEmpty;
      isEmailError = email.isEmpty;

      isJenisKelaminError =
          selectedGender == null || selectedGender!.isEmpty;           // 👈 NEW
      isStatusPerkawinanError =
          selectedStatusPerkawinan == null ||
              selectedStatusPerkawinan!.isEmpty;                            // 👈 NEW
      isPendidikanError = pendidikan.isEmpty;                           // 👈 NEW
      isAlamatError = alamat.isEmpty;                                   // 👈 NEW
      isHubunganAnakError = hubunganAnak.isEmpty;                       // 👈 NEW

      _signupError = null;
    });

    if (!isNameError &&
        !isUsernameError &&
        !isPasswordError &&
        !isUmurError &&
        !isPekerjaanError &&
        !isHpError &&
        !isEmailError &&
        !isJenisKelaminError &&           // 👈 NEW
        !isStatusPerkawinanError &&       // 👈 NEW
        !isPendidikanError &&             // 👈 NEW
        !isAlamatError &&                 // 👈 NEW
        !isHubunganAnakError) {           // 👈 NEW
      context.read<AuthCubit>().signUp(
        name: name,
        username: username,
        password: password,
        umur: umur,
        pekerjaan: pekerjaan,
        hp: hp,
        email: email,
        role: 'ortu',
        jenisKelamin: selectedGender!,                // 👈 NEW
        statusPerkawinan: selectedStatusPerkawinan!,  // 👈 NEW
        pendidikan: pendidikan,                       // 👈 NEW
        alamat: alamat,                               // 👈 NEW
        hubunganAnak: hubunganAnak,                   // 👈 NEW
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
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign Up'),

        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              child: Stack(
                children: [
                  _formSignup(context, isLoading),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _formSignup(BuildContext context, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Masukkan Nama Lengkap',
              errorText: isNameError ? 'Nama harus diisi' : null,
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(usernameFocus);
            },
          ),
          const SizedBox(height: 10),

          // Username
          TextFormField(
            controller: usernameController,
            focusNode: usernameFocus,
            decoration: InputDecoration(
              hintText: 'Masukkan Username',
              errorText: isUsernameError ? 'Username harus diisi' : null,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(passwordFocus);
            },
          ),
          const SizedBox(height: 10),

          // Password
          TextFormField(
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: kunciPassword,
            decoration: InputDecoration(
              hintText: 'Masukkan Password',
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
          const SizedBox(height: 10),

          // Umur
          TextFormField(
            controller: umurController,
            decoration: InputDecoration(
              hintText: 'Masukkan Umur',
              errorText: isUmurError ? 'Umur harus diisi' : null,
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),

          // Jenis Kelamin
          DropdownButtonFormField<String>(
            value: selectedGender,
            decoration: InputDecoration(
              hintText: 'Pilih Jenis Kelamin',
              errorText:
              isJenisKelaminError ? 'Jenis kelamin harus dipilih' : null,
              prefixIcon: const Icon(Icons.wc),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Laki-laki',
                child: Text('Laki-laki'),
              ),
              DropdownMenuItem(
                value: 'Perempuan',
                child: Text('Perempuan'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedGender = value;
                isJenisKelaminError = false;
              });
            },
          ),
          const SizedBox(height: 10),

// Status Perkawinan
          DropdownButtonFormField<String>(
            value: selectedStatusPerkawinan,
            decoration: InputDecoration(
              hintText: 'Pilih Status Perkawinan',
              errorText: isStatusPerkawinanError
                  ? 'Status perkawinan harus dipilih'
                  : null,
              prefixIcon: const Icon(Icons.family_restroom),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Belum Menikah',
                child: Text('Belum Menikah'),
              ),
              DropdownMenuItem(
                value: 'Menikah',
                child: Text('Menikah'),
              ),
              DropdownMenuItem(
                value: 'Cerai',
                child: Text('Cerai'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedStatusPerkawinan = value;
                isStatusPerkawinanError = false;
              });
            },
          ),
          const SizedBox(height: 10),

// Pendidikan
          TextFormField(
            controller: pendidikanController,
            decoration: InputDecoration(
              hintText: 'Masukkan Pendidikan Terakhir',
              errorText: isPendidikanError ? 'Pendidikan harus diisi' : null,
              prefixIcon: const Icon(Icons.school),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),

// Alamat
          TextFormField(
            controller: alamatController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Masukkan Alamat Lengkap',
              errorText: isAlamatError ? 'Alamat harus diisi' : null,
              prefixIcon: const Icon(Icons.home_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),

// Hubungan dengan anak
          TextFormField(
            controller: hubunganAnakController,
            decoration: InputDecoration(
              hintText: 'Hubungan dengan anak (Ayah/Ibu/Wali)',
              errorText: isHubunganAnakError
                  ? 'Hubungan dengan anak harus diisi'
                  : null,
              prefixIcon: const Icon(Icons.people_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Pekerjaan
          TextFormField(
            controller: pekerjaanController,
            decoration: InputDecoration(
              hintText: 'Masukkan Pekerjaan',
              errorText: isPekerjaanError ? 'Pekerjaan harus diisi' : null,
              prefixIcon: const Icon(Icons.work_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),

          // HP
          TextFormField(
            controller: hpController,
            decoration: InputDecoration(
              hintText: 'Masukkan Nomor HP',
              errorText: isHpError ? 'Nomor HP harus diisi' : null,
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),

          // Email
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: 'Masukkan Email',
              errorText: isEmailError ? 'Email harus diisi' : null,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),

          // Error message display
          if (_signupError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 10),

          // Sign Up Button
          isLoading
              ? const LoadingButton()
              : SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: _signUp,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Sign Up",
                  style: whiteTextStyle.copyWith(
                    fontWeight: extraBold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Back to Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Sudah punya akun? ", style: secondaryTextStyle),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text("Login", style: whiteTextStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
