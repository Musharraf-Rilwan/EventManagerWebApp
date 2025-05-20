import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isInitializing = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      debugPrint('Initializing auth service...');

      await authService.initializeAuth();
      final currentUser = authService.currentUser;
      debugPrint('Current user: ${currentUser?.email}');

      if (!mounted) return;

      if (currentUser == null) {
        debugPrint('No current user found');
        await Future.delayed(const Duration(seconds: 5));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final userService = UserService();
      UserModel? userModel;
      try {
        userModel = await Future.any([
          userService.getUser(currentUser.uid),
          Future.delayed(const Duration(seconds: 10))
              .then((_) => throw TimeoutException('Failed to get user data')),
        ]);
      } on TimeoutException catch (e) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _error = e.message ?? 'Connection timeout. Please try again.';
          });
          return;
        }
      }

      if (!mounted) return;

      if (userModel == null) {
        // Create default user profile
        userModel = UserModel(
          uid: currentUser.uid,
          email: currentUser.email!,
          displayName: currentUser.displayName ??
              currentUser.email?.split('@')[0] ??
              'User',
          role: UserRole.attendee,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await userService.createUser(userModel);
      }

      if (!mounted) return;

      // Add a small delay to show the splash screen
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      // Navigate based on user role
      if (userModel.role == UserRole.admin) {
        debugPrint('Navigating to admin panel...');
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (userModel.role == UserRole.organizer) {
        debugPrint('Navigating to organizer panel...');
        Navigator.pushReplacementNamed(context, '/organizer');
      } else {
        debugPrint('Navigating to dashboard...');
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = 'An error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.red.shade50,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: screenSize.width * 0.7,
                        height: screenSize.height * 0.3,
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/dmu_logo1.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Text(
                      'DMU Event Manager',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Text(
                      'We are AweSome',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_isInitializing) ...[
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red.shade700),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ] else if (_error != null) ...[
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isInitializing = true;
                          _error = null;
                        });
                        _initializeApp();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
