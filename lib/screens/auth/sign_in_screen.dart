import 'package:cosmic_explorer/services/supabase_service.dart';
import 'package:cosmic_explorer/widgets/auth_text_field.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isMobileView(BuildContext context) {
    return MediaQuery.of(context).size.width < 480;
  }

  Widget _buildForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Sign In',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 28 : 36,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24 : 32),

          // Email field
          AuthTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 16 : 24),

          // Password field
          AuthTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 12.0 : 16.0,
              ),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          SizedBox(height: isMobile ? 24 : 32),

          // Sign in button
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 16 : 24,
              ),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              textStyle: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: isMobile ? 20 : 24,
                    width: isMobile ? 20 : 24,
                    child: const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Sign In'),
          ),

          SizedBox(height: isMobile ? 16 : 24),

          // Sign up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account?",
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/signup');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 8,
                  ),
                ),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobileView(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 1000,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 48,
            vertical: 32,
          ),
          child: isMobile
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // SVG above form on mobile
                      SvgPicture.asset(
                        'assets/images/signin.svg',
                        height: 180,
                      ),
                      const SizedBox(height: 32),
                      _buildForm(true),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Left side - SVG illustration
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/signin.svg',
                              height: 400,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Welcome Back!',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Explore the cosmos with NASA\'s incredible collection',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 48),
                    
                    // Right side - Sign in form
                    Expanded(
                      flex: 4,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: SingleChildScrollView(
                          child: _buildForm(false),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}