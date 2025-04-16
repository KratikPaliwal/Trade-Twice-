import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trade_twice/utils/routes.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
        });

        Navigator.pushReplacementNamed(context, MyRoutes.homeroutes);
      } on FirebaseAuthException catch (e) {
        String errorMessage = "An error occurred.";
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Email is already in use.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak.';
            break;
          default:
            errorMessage = e.message ?? "Unexpected error occurred.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Sign Up")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 👇 App Logo
                Center(
                  child: Image.asset(
                    'assets/images/Twice_logo.png', // Update the path if needed
                    height: 100,
                    width: 100,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // 👇 Title
                const Text(
                  "Create a new account",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // 👇 Username Field
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value != null && value.isNotEmpty ? null : "Enter your name",
                ),
                const SizedBox(height: 20),

                // 👇 Email Field
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value != null && value.contains('@') ? null : "Enter a valid email",
                ),
                const SizedBox(height: 20),

                // 👇 Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value != null && value.length >= 6 ? null : "Password must be at least 6 characters",
                ),
                const SizedBox(height: 30),

                // 👇 Signup Button
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: signUp,
                    child: const Text("Create Account"),
                  ),
                ),
                const SizedBox(height: 10),

                // 👇 Login Redirect
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, MyRoutes.loginroute);
                  },
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
