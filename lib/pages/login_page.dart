import 'package:e_spirit_care/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../components/loading_button.dart';
import '../theme/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();

  bool kunciPassword = true;
  bool isUsernameError = false;
  bool isPasswordError = false;
  String? _loginError;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void _login() {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      isUsernameError = username.isEmpty;
      isPasswordError = password.isEmpty;
      _loginError = null;
    });

    if (!isUsernameError && !isPasswordError) {
      context.read<AuthCubit>().signIn(
        username: username,
        password: password,
      );
    }
  }

  // Di LoginPage, update BlocListener
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Di LoginPage, update bagian AuthSuccess
        if (state is AuthSuccess) {
          final role = state.user.role.toLowerCase();
          debugPrint('🎉 Login sukses. Role: $role');

          if (role == 'admin' || role == 'perawat') {
            debugPrint('➡️ Redirect ke LIST ORTU PAGE');
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/list-ortu',
                  (_) => false,
            );
          } else {
            // anggap role lain = ortu
            debugPrint('➡️ Redirect ke HOME PAGE ORTU');
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
                  (_) => false,
            );
          }
        } else if (state is ChildAuthSuccess) {
          debugPrint('🎉 Redirect ke CHILD DASHBOARD');
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/child-dashboard', (_) => false);
        } else if (state is AuthFailed) {
          debugPrint('❌ Login error: ${state.error}');
          setState(() {
            _loginError = state.error;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(body: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Stack(
          children: [
            _imageLogin(),
            _formLogin(context, isLoading),
          ],
        );
      },
    );
  }

  Widget _imageLogin() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.08),
          Image.asset(
            'assets/logo-spirit.png',
            height: MediaQuery.of(context).size.height * 0.4,
          ),
        ],
      ),
    );
  }

  Widget _formLogin(BuildContext context, bool isLoading) {
    return Semantics(
      label: 'Login form',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            decoration: BoxDecoration(
              color: tPrimaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),
              ),
            ),
            child: Column(
              children: [
                // Username
                Semantics(
                  label: 'Username Input Field. Masukkan username',
                  child: TextFormField(
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Username',
                      hintStyle: const TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.person_outline, color: kPrimaryColor),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: kPrimaryColor, width: 1.0),
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                      errorText: isUsernameError ? 'Username harus diisi' : null,
                    ),
                    onChanged: (v) {
                      if (isUsernameError && v.isNotEmpty) {
                        setState(() => isUsernameError = false);
                      }
                    },
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(passwordFocusNode);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Password
                Semantics(
                  label: 'Password Input Field. Masukkan Password',
                  child: TextFormField(
                    obscureText: kunciPassword,
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Password',
                      hintStyle: const TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_outlined, color: kPrimaryColor),
                      suffixIcon: GestureDetector(
                        onTap: _togglePasswordVisibility,
                        child: Semantics(
                          label: kunciPassword ? 'Show password' : 'Hide password',
                          child: Icon(
                            kunciPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                        borderSide: const BorderSide(color: kPrimaryColor, width: 1.0),
                      ),
                      errorText: isPasswordError ? 'Password harus diisi' : null,
                    ),
                    onChanged: (v) {
                      if (isPasswordError && v.isNotEmpty) {
                        setState(() => isPasswordError = false);
                      }
                    },
                    onFieldSubmitted: (_) => _login(),
                  ),
                ),

                // ❌ Bagian "Lupa Password?" DIHAPUS

                if (_loginError != null) ...[
                  const SizedBox(height: 10),
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
                            _loginError!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red.shade600, size: 16),
                          onPressed: () => setState(() => _loginError = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                isLoading
                    ? const LoadingButton()
                    : SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: _login,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Login",
                        style: whiteTextStyle.copyWith(
                          fontWeight: extraBold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum punya akun? ", style: secondaryTextStyle),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupPage()),
                        );
                      },
                      child: Text("Sign Up", style: whiteTextStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => kunciPassword = !kunciPassword);
  }
}
