import 'package:flutter/material.dart';
import 'package:my_first_app/screens/auth/register_screen.dart';
import 'package:my_first_app/screens/home/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Global key for form validation
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  // Supabase instance shortcut
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    // Clean up controllers when the widget is permanently removed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validate form inputs first
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text
            .trim(), // Remove accidental trailing spaces
        password: _passwordController.text.trim(),
      );

      // Guard against context calls across async gaps
      if (!mounted) return;

      if (response.user != null && response.session != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      // Catch specific Supabase errors like 'Invalid login credentials'
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (e) {
      // Fallback for network issues or general runtime bugs
      if (!mounted) return;
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome Back"), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            children: [
              const SizedBox(height: 20),
              Text(
                "Sign In",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your credentials to access your account",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) =>
                    _login(), // Submits form on keyboard "Done" click
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(
                        () => _isPasswordObscured = !_isPasswordObscured,
                      );
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Register Redirection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text("Register"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
