import 'package:flutter/material.dart';
import 'package:my_first_app/screens/home/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
    // Clean up controllers when the widget is removed from the widget tree
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(), // Trim whitespace
        password: _passwordController.text.trim(),
      );

      // Check if context is still valid after async gap
      if (!mounted) return;

      // Note: If email confirmation is enabled in Supabase,
      // response.session might be null until they confirm.
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      // Handle specific Supabase Auth errors gracefully
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (e) {
      // Handle fallback or network errors
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
      appBar: AppBar(title: const Text("Create Account"), centerTitle: true),
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
                "Get Started",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Create a new account to continue",
                style: TextStyle(color: Colors.grey[600]),
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
                  // Simple regex for email validation
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
                onFieldSubmitted: (_) => _register(),
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
                    return 'Please enter a password';
                  }
                  if (value.trim().length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Register Button
              SizedBox(
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Login Redirection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      // Navigate back to Login Screen if it exists in the stack
                      Navigator.pop(context);
                    },
                    child: const Text("Login"),
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
