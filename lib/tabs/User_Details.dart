import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:herhaven_admin/sidebar/sidebar_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../colors.dart';

class UserDetails extends StatefulWidget {
  const UserDetails({super.key});

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> with TickerProviderStateMixin {
  final SidebarController sidebarController = Get.find<SidebarController>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _visibilityController = TextEditingController();
  String searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _listAnimationController;
  late Animation<double> _listScaleAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Initialize animations for page load
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    // Initialize animations for list items
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _listScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _listAnimationController.forward();

    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
        _listAnimationController.forward(from: 0.0); // Restart list animation on search
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  Future<void> _showEditUserDialog(BuildContext context, Map<String, dynamic> user) async {
    _nameController.text = user['name'] ?? '';
    _visibilityController.text = user['visibility'] ?? 'Public';
    String selectedVisibility = user['visibility'] ?? 'Public';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AnimatedScaleDialog(
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 8,
            title: Text(
              'Edit User',
              style: TextStyle(
                color: text1,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: pink),
                      filled: true,
                      fillColor: primaryColor.withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: pink, width: 2),
                      ),
                      prefixIcon: Icon(Icons.person_outline, color: pink, size: 22),
                    ),
                    style: TextStyle(color: black, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: user['email'] ?? 'No Email',
                      labelStyle: TextStyle(color: blue),
                      filled: true,
                      fillColor: greyColor1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.email_outlined, color: blue, size: 22),
                    ),
                    style: TextStyle(color: black, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedVisibility,
                    decoration: InputDecoration(
                      labelText: 'Visibility',
                      labelStyle: TextStyle(color: pink),
                      filled: true,
                      fillColor: primaryColor.withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: pink, width: 2),
                      ),
                      prefixIcon: Icon(Icons.visibility_outlined, color: pink, size: 22),
                    ),
                    items: ['Public', 'Private'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(color: black, fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        selectedVisibility = newValue;
                        _visibilityController.text = newValue;
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: pink, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  try {
                    await _firestore.collection('users').doc(user['uid']).update({
                      'name': _nameController.text.trim(),
                      'visibility': _visibilityController.text.trim(),
                    });
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User "${_nameController.text}" updated successfully.'),
                        backgroundColor: pink,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating user: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String? userId, String? userName) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid user ID.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AnimatedScaleDialog(
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 8,
            title: Text(
              'Confirm Deletion',
              style: TextStyle(
                color: text1,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    'Are you sure you want to delete "${userName ?? 'this user'}"?',
                    style: TextStyle(color: black, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone.',
                    style: TextStyle(color: black.withOpacity(0.7), fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: pink, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  try {
                    await _firestore.collection('users').doc(userId).delete();
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User "${userName ?? userId}" deleted successfully.'),
                        backgroundColor: pink,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting user: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor, // Creamy background
              purple.withOpacity(0.1), // Light purple tint
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width < 768 ? 16 : 32,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (width < 768)
                        GestureDetector(
                          onTap: () => sidebarController.showsidebar.value = true,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.menu_rounded,
                              color: pink,
                              size: 28,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 28),
                      Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: width < 768 ? 22 : 26,
                          fontWeight: FontWeight.w800,
                          color: text1,
                        ),
                      ),
                      SizedBox(width: width < 768 ? 28 : 32),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search Bar
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: width < 425
                        ? width * 0.9
                        : width < 768
                        ? width * 0.85
                        : width < 1024
                        ? 700
                        : 900,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users by name...',
                        hintStyle: TextStyle(color: blue.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search_rounded, color: pink, size: 24),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: pink, size: 22),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchQuery = '';
                              _listAnimationController.forward(from: 0.0);
                            });
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: pink, width: 2),
                        ),
                      ),
                      style: TextStyle(color: black, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Table Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width < 768 ? 16 : 32),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: width < 768 ? 48 : 64), // For avatar
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Name',
                            style: TextStyle(
                              fontSize: width < 768 ? 15 : 16,
                              fontWeight: FontWeight.w700,
                              color: text1,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              fontSize: width < 768 ? 15 : 16,
                              fontWeight: FontWeight.w700,
                              color: text1,
                            ),
                            textAlign: TextAlign.center, // Centered email header
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Visibility',
                            style: TextStyle(
                              fontSize: width < 768 ? 15 : 16,
                              fontWeight: FontWeight.w700,
                              color: text1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: width < 768 ? 64 : 80), // For actions
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // User List (Table-like)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: pink));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: text1, fontSize: 16),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No users found.',
                            style: TextStyle(color: text1, fontSize: 16),
                          ),
                        );
                      }

                      final userDocs = snapshot.data!.docs;
                      final filteredUsers = userDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        return {
                          'uid': data?['uid'] ?? doc.id,
                          'name': data?['name'] ?? data?['displayName'] ?? 'No Name',
                          'email': data?['email'] ?? 'No Email',
                          'visibility': data?['visibility'] ?? 'Public',
                          'profileImage': data?['profileImage'],
                        };
                      }).where((user) {
                        final name = user['name'] as String?;
                        return name?.toLowerCase().contains(searchQuery) ?? false;
                      }).toList();

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: width < 768 ? 16 : 32, vertical: 8),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final profileImage = user['profileImage'] as String?;

                          return ScaleTransition(
                            scale: _listScaleAnimation,
                            child: FadeTransition(
                              opacity: Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(
                                CurvedAnimation(
                                  parent: _listAnimationController,
                                  curve: Interval(0.05 * index, 1.0, curve: Curves.easeOutCubic),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Material(
                                  elevation: 3,
                                  borderRadius: BorderRadius.circular(16),
                                  shadowColor: black.withOpacity(0.15),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: pink.withOpacity(0.3), width: 1),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        // Optional: Add tap action (e.g., show user details)
                                      },
                                      hoverColor: purple.withOpacity(0.1),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Profile Image
                                            CircleAvatar(
                                              radius: width < 768 ? 24 : 32,
                                              backgroundColor: profileImage == null || profileImage.isEmpty
                                                  ? pink
                                                  : blue.withOpacity(0.9),
                                              backgroundImage: profileImage != null && profileImage.isNotEmpty
                                                  ? NetworkImage(profileImage)
                                                  : null,
                                              child: profileImage == null || profileImage.isEmpty
                                                  ? Icon(Icons.person_rounded, color: Colors.white, size: width < 768 ? 28 : 36)
                                                  : null,
                                            ),
                                            const SizedBox(width: 16),
                                            // Name
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                user['name'] ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: width < 768 ? 15 : 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: text1,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.left,
                                              ),
                                            ),
                                            // Email
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                user['email'] ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: width < 768 ? 14 : 15,
                                                  color: black.withOpacity(0.8),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center, // Centered email
                                              ),
                                            ),
                                            // Visibility
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                                                // decoration: BoxDecoration(
                                                //   color: user['visibility'] == 'Public'
                                                //       ? blue.withOpacity(0.15)
                                                //       : pink.withOpacity(0.15),
                                                //   borderRadius: BorderRadius.circular(10),
                                                //   border: Border.all(
                                                //     color: user['visibility'] == 'Public'
                                                //         ? blue.withOpacity(0.5)
                                                //         : pink.withOpacity(0.5),
                                                //   ),
                                                // ),
                                                child: Text(
                                                  user['visibility'] ?? 'Public',
                                                  style: TextStyle(
                                                    fontSize: width < 768 ? 12 : 13,
                                                    color: user['visibility'] == 'Public' ? blue : pink,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            // Actions
                                            SizedBox(
                                              width: width < 768 ? 60 : 72, // Reduced width to prevent overflow
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: blue.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(Icons.edit_rounded, color: blue, size: 20),
                                                      onPressed: () => _showEditUserDialog(context, user),
                                                      tooltip: 'Edit User',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.redAccent.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                                      onPressed: () => _showDeleteConfirmationDialog(context, user['uid'], user['name']),
                                                      tooltip: 'Delete User',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Animated Dialog Widget
class AnimatedScaleDialog extends StatefulWidget {
  final Widget child;

  const AnimatedScaleDialog({super.key, required this.child});

  @override
  _AnimatedScaleDialogState createState() => _AnimatedScaleDialogState();
}

class _AnimatedScaleDialogState extends State<AnimatedScaleDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}