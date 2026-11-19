import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      try {
        // Call your backend register method
        await ref.read(authControllerProvider.notifier).registerAndSaveUser(email, password, name);
        // Do not need to navigate, the Router handles it automatically!
      } catch (e) {
        // Red background for error visibility
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent, 
            behavior: SnackBarBehavior.floating, // Ekta sundor floating effect asbe
            content: Text(
              e.toString(), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        
        print('Firebase Error: $e'); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            
            // Name Input
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Full Name',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Email Input
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Password Input
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            
            // Register Button
            isLoading 
              ? const CircularProgressIndicator(color: Colors.deepPurpleAccent)
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _register,
                    child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
            
            const SizedBox(height: 16),
            
            // Go back to Login Screen
            TextButton(
              onPressed: () => context.pop(), // Go back
              child: const Text('Already have an account? Login', style: TextStyle(color: Colors.deepPurpleAccent)),
            ),
          ],
        ),
      ),
    );
  }
}