import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mjworkmanagement/screens/payment.dart';
import 'package:mjworkmanagement/screens/payments.dart';
import 'package:mjworkmanagement/screens/products.dart';
import 'package:mjworkmanagement/widgets/neu.dart';
import 'package:velocity_x/velocity_x.dart';
import 'register.dart';
import 'invoice_sender_screen.dart';
import 'worker2_screen.dart';
import 'worker3_screen.dart';
import 'worker4_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();
      String role = userDoc['role'];
      _navigateToRoleScreen(role);
    } catch (e) {
      _showErrorDialog();
    }
  }

  void _navigateToRoleScreen(String role) {
    Widget roleScreen;
    switch (role) {
      case 'Invoice':
        roleScreen = InvoiceSenderScreen();
        break;
      case 'Worker2':
        roleScreen = Worker2Screen();
        break;
      case 'Worker3':
        roleScreen = Worker3Screen();
        break;
      case 'Worker4':
        roleScreen = Worker4Screen();
        break;
      case 'Payments':
        roleScreen = PaymentsPage();
        break;
      case 'Admin':
        roleScreen = AdminPanel();
        break;
      case 'Products':
        roleScreen = ProductVideoPage();
        break;
      default:
        roleScreen = LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => roleScreen,
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Failed'),
        content: Text('Invalid email or password'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.jpeg',
                      height: 100, width: 100),
                  SizedBox(height: 50),
                  _buildCustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                  ),
                  SizedBox(height: 20),
                  _buildCustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    obscureText: _obscureText,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 40),
                  NeuMo(
                    height: 60,
                    widget: ElevatedButton(
                      onPressed: _login,
                      child: Text(
                        'Login',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 20,),
                      ),
                      style: ElevatedButton.styleFrom(
                        overlayColor: Colors.blue,
                        backgroundColor: Colors.transparent,elevation: 0,
                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize:
                            Size(double.infinity, 50), // Full width button
                      ),
                    ),
                  ),
                  // SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Developed By',
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            'CoDec',
            style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ).box.margin(EdgeInsets.symmetric(vertical: 15)).make(),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    return TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.blueAccent),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.blueAccent)
              : null,
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide(
              color: Colors.transparent,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Colors.blueAccent,
              width: 2.0,
            ),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        ),

    );
  }
}
