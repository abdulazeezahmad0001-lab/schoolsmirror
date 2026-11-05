import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _loading = false;
  bool _bioLoading = false;
  bool _bioAvailable = false;
  bool _bioEnrolled = false;
  bool _enableBioToggle = false;
  String? _error;
  String? _bioStatus;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final available = await BiometricService.isAvailable();
    final enrolled  = available && await BiometricService.isEnrolled();

    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _bioEnrolled  = enrolled;
      _enableBioToggle = enrolled;
      if (enrolled) _bioStatus = 'Fingerprint is set up';
    });

    if (enrolled) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _biometricLogin();
    }
  }

  Future<void> _passwordLogin() async {
    final login = _loginCtrl.text.trim();
    final pass  = _passCtrl.text;

    if (login.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter your email/ID and password');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final result = await ApiClient.login(
        login: login,
        password: pass,
        deviceId: 'flutter_device',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        if (_enableBioToggle && !_bioEnrolled && _bioAvailable) {
          await BiometricService.enable(login, pass);
        }
        _routeByRole(result['data']['role']);
      } else {
        setState(() => _error = result['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometricLogin() async {
    if (!_bioEnrolled) return;

    setState(() { _bioLoading = true; _bioStatus = 'Verifying fingerprint…'; _error = null; });

    final ok = await BiometricService.authenticate();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _bioLoading = false;
        _bioStatus = 'Fingerprint not recognised. Use password below.';
      });
      return;
    }

    final creds = await BiometricService.retrieveCredentials();
    if (creds == null) {
      if (!mounted) return;
      setState(() {
        _bioLoading = false;
        _bioEnrolled = false;
        _bioStatus = null;
      });
      return;
    }

    try {
      final result = await ApiClient.login(
        login: creds.login,
        password: creds.password,
        deviceId: 'flutter_device',
        isBiometric: true,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _routeByRole(result['data']['role']);
      } else {
        await BiometricService.disable();
        setState(() {
          _bioLoading = false;
          _bioEnrolled = false;
          _enableBioToggle = false;
          _bioStatus = null;
          _error = 'Fingerprint login failed. Please sign in with password.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bioLoading = false;
        _bioStatus = 'Network error. Use password below.';
      });
    }
  }

  void _routeByRole(String role) {
    if (role == 'student') {
      Navigator.of(context).pushReplacementNamed('/student');
    } else {
      Navigator.of(context).pushReplacementNamed('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school, size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'SchoolsMirror',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const Text(
                    'Secure Login Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 32),

                  if (_bioEnrolled) ...[
                    Center(
                      child: InkWell(
                        onTap: _bioLoading ? null : _biometricLogin,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(_bioLoading ? 0.4 : 0.15),
                              width: 2,
                            ),
                          ),
                          child: _bioLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Icon(Icons.fingerprint, size: 44, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _bioStatus ?? 'Tap to sign in with fingerprint',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    const Row(children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR PASSWORD', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _loginCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Email or Student ID', Icons.person),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Password', Icons.lock),
                  ),

                  if (_bioAvailable && !_bioEnrolled) ...[
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: _enableBioToggle,
                      onChanged: (v) => setState(() => _enableBioToggle = v),
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF3A57A5),
                      title: const Text(
                        'Enable fingerprint login',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      secondary: const Icon(Icons.fingerprint, color: Colors.white54),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _passwordLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3A57A5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Forgot Password?', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5A7AC7), width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}