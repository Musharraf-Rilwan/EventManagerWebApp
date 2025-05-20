import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class UserManagementPage extends StatefulWidget {
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  const UserManagementPage({
    super.key,
    this.refreshIndicatorKey,
  });

  @override
  State<UserManagementPage> createState() => UserManagementPageState();
}

class UserManagementPageState extends State<UserManagementPage> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> refreshData() async {
    if (mounted) {
      await _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getAllUsers();
      if (!mounted) return;
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final searchLower = _searchQuery.toLowerCase();
      return user.email.toLowerCase().contains(searchLower) ||
          (user.displayName?.toLowerCase().contains(searchLower) ?? false);
    }).toList();
  }

  Future<void> _updateUserRole(UserModel user, UserRole newRole) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final currentUserRole = authService.currentUserRole;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to perform this action'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (currentUserRole != UserRole.admin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only admins can change user roles'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      await _userService.updateUserRole(
        user.uid, 
        newRole, 
        requestedByUid: currentUser.uid
      );
      
      // Reload users to get updated data
      await _loadUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully changed ${user.email} to ${newRole.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed ?? false) {
        await _userService.deleteUser(user.uid);
        await _loadUsers(); // Reload the users list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: widget.refreshIndicatorKey,
      onRefresh: refreshData,
      color: Colors.red,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              style: const TextStyle(color: Colors.black),
              cursorColor: Colors.red,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No users found', style: TextStyle(color: Colors.black)))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black, width: 1),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red,
                                child: Text(
                                  user.email[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.displayName ?? user.email,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.email,
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Role: ${user.role.name}',
                                    style: TextStyle(
                                      color: user.role == UserRole.admin
                                          ? Colors.red
                                          : user.role == UserRole.organizer
                                              ? Colors.red.shade700
                                              : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.black),
                                color: Colors.white,
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    if (user.role == UserRole.admin) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Admin users cannot be deleted for security reasons'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    _deleteUser(user);
                                  } else {
                                    final newRole = UserRole.values.byName(value);
                                    await _updateUserRole(user, newRole);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (user.role != UserRole.admin) ...[
                                    if (user.role != UserRole.organizer)
                                      const PopupMenuItem(
                                        value: 'organizer',
                                        child: Text('Make Organizer', style: TextStyle(color: Colors.black)),
                                      ),
                                    if (user.role != UserRole.attendee)
                                      const PopupMenuItem(
                                        value: 'attendee',
                                        child: Text('Make Attendee', style: TextStyle(color: Colors.black)),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete User', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                // Show user details dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Colors.black, width: 1),
                                    ),
                                    title: Text(
                                      user.displayName ?? user.email,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email: ${user.email}',
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Role: ${user.role.name}',
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Created: ${user.createdAt.toString().split('.')[0]}',
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Last Login: ${user.lastLogin.toString().split('.')[0]}',
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Managed Events: ${user.managedEvents.length}',
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Attending Events: ${user.attendingEvents.length}',
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
