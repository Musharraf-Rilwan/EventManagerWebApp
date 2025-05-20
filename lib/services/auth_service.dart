import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  bool _isLoading = false;
  User? _currentUser;
  UserRole? _currentUserRole;

  // Getters
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  UserRole? get currentUserRole => _currentUserRole;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      _currentUser = user;
      if (user != null) {
        _userService.getUser(user.uid).then((userModel) {
          if (userModel != null) {
            _currentUserRole = userModel.role;
            debugPrint('Updated user role to: ${userModel.role}');
            notifyListeners();
          }
        });
      } else {
        _currentUserRole = null;
      }
      return user;
    });
  }

  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<void> initializeAuth() async {
    try {
      debugPrint('Initializing auth service...');
      
      // Create admin and organizer accounts if they don't exist
      await resetAdminAccount();
      await _initializeAdminAndOrganizer();
      
      // Listen for auth state changes
      _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          debugPrint('Auth state changed: ${user.email}');
          _currentUser = user;
          
          try {
            final userModel = await _userService.getUser(user.uid);
            if (userModel != null) {
              _currentUserRole = userModel.role;
              debugPrint('Current user role set to: ${userModel.role}');
              await _userService.updateLastLogin(user.uid);
            } else {
              debugPrint('Error: Could not find user model for ${user.email}');
            }
          } catch (e) {
            debugPrint('Error getting user: $e');
          }
        } else {
          debugPrint('No current user found');
          _currentUser = null;
          _currentUserRole = null;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }
  }

  Future<void> _initializeAdminAndOrganizer() async {
    try {
      // Admin credentials
      const adminEmail = 'admin@eventmanager.com';
      const adminPassword = 'admin123';

      // Check if admin exists first
      final adminUserDoc = await _firestore.collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (adminUserDoc.docs.isEmpty) {
        debugPrint('Creating new admin account...');
        // Create admin account if it doesn't exist
        try {
          final adminCredential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

          if (adminCredential.user != null) {
            debugPrint('Admin Firebase auth account created, setting up Firestore document...');
            
            // Create user document in Firestore
            await _firestore.collection('users').doc(adminCredential.user!.uid).set({
              'email': adminEmail,
              'displayName': 'Admin',
              'role': 'admin',
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'managedEvents': [],
              'attendingEvents': [],
            });

            debugPrint('Admin account created successfully with ID: ${adminCredential.user!.uid}');
          }
        } catch (e) {
          debugPrint('Error creating admin account: $e');
          // Try to sign in with existing credentials in case the auth account exists but Firestore doc doesn't
          try {
            final adminCredential = await _auth.signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
            
            if (adminCredential.user != null) {
              debugPrint('Found existing admin auth account, creating Firestore document...');
              
              await _firestore.collection('users').doc(adminCredential.user!.uid).set({
                'email': adminEmail,
                'displayName': 'Admin',
                'role': 'admin',
                'createdAt': FieldValue.serverTimestamp(),
                'lastLogin': FieldValue.serverTimestamp(),
                'managedEvents': [],
                'attendingEvents': [],
              });
              
              debugPrint('Admin Firestore document created for existing auth account');
            }
          } catch (signInError) {
            debugPrint('Error signing in as admin: $signInError');
          }
        }
      } else {
        debugPrint('Admin account exists with ID: ${adminUserDoc.docs.first.id}');
        // Verify the role is set correctly
        final adminDoc = adminUserDoc.docs.first;
        if (adminDoc.data()['role'] != 'admin') {
          debugPrint('Fixing admin role...');
          await _firestore.collection('users').doc(adminDoc.id).update({
            'role': 'admin'
          });
        }
      }

      // Check if organizer exists first
      final organizerUserDoc = await _firestore.collection('users')
          .where('email', isEqualTo: 'organizer@eventmanager.com')
          .get();

      if (organizerUserDoc.docs.isEmpty) {
        // Create organizer account if it doesn't exist
        try {
          final organizerCredential = await _auth.createUserWithEmailAndPassword(
            email: 'organizer@eventmanager.com',
            password: 'organizer123',
          );

          if (organizerCredential.user != null) {
            // Create user document in Firestore
            await _firestore.collection('users').doc(organizerCredential.user!.uid).set({
              'email': 'organizer@eventmanager.com',
              'displayName': 'Organizer',
              'role': 'organizer',
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'managedEvents': [],
              'attendingEvents': [],
            });

            debugPrint('Organizer account created successfully');
          }
        } catch (e) {
          debugPrint('Error creating organizer account: $e');
        }
      } else {
        debugPrint('Organizer account already exists');
      }
    } catch (e) {
      debugPrint('Error in _initializeAdminAndOrganizer: $e');
    }
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      debugPrint('Attempting email/password sign in: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _currentUser = userCredential.user;
        
        // Get user data from Firestore
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          // If user document doesn't exist but it's the admin email, create it
          if (email == 'admin@eventmanager.com') {
            debugPrint('Creating missing admin document...');
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
              'email': email,
              'displayName': 'Admin',
              'role': 'admin',
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'managedEvents': [],
              'attendingEvents': [],
            });
            _currentUserRole = UserRole.admin;
          } else {
            throw Exception('User data not found');
          }
        } else {
          final userData = userDoc.data()!;
          _currentUserRole = UserRole.fromString(userData['role'] as String? ?? 'attendee');
        }
        
        debugPrint('Successfully signed in as ${email} with role: ${_currentUserRole?.name}');
        await _userService.updateLastLogin(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUserWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      print('Creating new user: $email');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the user's profile with display name
      await userCredential.user?.updateDisplayName(displayName);
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'role': 'attendee',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Successfully created user with display name: $displayName');
      
      if (userCredential.user != null) {
        _currentUser = userCredential.user;
      }
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _auth.signOut();
      _currentUser = null;
      _currentUserRole = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      debugPrint('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    try {
      _setLoading(true);
      if (_currentUser != null) {
        await _userService.deleteUser(_currentUser!.uid);
        await _currentUser!.delete();
        await signOut();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      _setLoading(true);
      // Delete user from Firestore first
      await _userService.deleteUser(userId);
      // Delete user from Firebase Auth
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        final userToDelete = await FirebaseAuth.instance.signInWithCustomToken(token)
          .then((_) => FirebaseAuth.instance.currentUser);
        if (userToDelete != null) {
          await userToDelete.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetAdminAccount() async {
    try {
      debugPrint('Starting admin account reset...');
      const adminEmail = 'admin@eventmanager.com';
      const adminPassword = 'admin123';

      // First try to delete any existing admin user documents
      final adminDocs = await _firestore.collection('users')
          .where('email', isEqualTo: adminEmail)
          .get();

      for (var doc in adminDocs.docs) {
        debugPrint('Deleting existing admin document: ${doc.id}');
        await _firestore.collection('users').doc(doc.id).delete();
      }

      // Try to delete the auth account if it exists
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        if (userCredential.user != null) {
          debugPrint('Found existing admin auth account, deleting...');
          await userCredential.user!.delete();
          debugPrint('Existing admin auth account deleted');
        }
      } catch (e) {
        debugPrint('No existing admin auth account found or error: $e');
      }

      // Create new admin account
      debugPrint('Creating new admin account...');
      final adminCredential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      if (adminCredential.user != null) {
        debugPrint('Created new admin auth account, setting up Firestore document...');
        
        // Create user document in Firestore
        await _firestore.collection('users').doc(adminCredential.user!.uid).set({
          'email': adminEmail,
          'displayName': 'Admin',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'managedEvents': [],
          'attendingEvents': [],
        });

        debugPrint('Admin account reset complete with ID: ${adminCredential.user!.uid}');
        return;
      }
    } catch (e) {
      debugPrint('Error resetting admin account: $e');
      throw Exception('Failed to reset admin account: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }
}
