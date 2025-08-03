import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:herhaven_admin/sidebar/sidebar_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import '../colors.dart'; // Assuming your colors are defined here

class UserDetails extends StatefulWidget {
  UserDetails({super.key});

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  final SidebarController sidebarController = Get.put(SidebarController());
  String searchQuery = '';

  // REMOVE the static usersData list
  // List<Map<String, dynamic>> usersData = [ ... ];

  // --- Firebase Firestore instance ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: pink.withOpacity(0.5),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width < 380
              ? 5
              : width < 425
              ? 15
              : width < 768
              ? 20
              : width < 1024
              ? 70
              : width <= 1440
              ? 60
              : width > 1440 && width <= 2550
              ? 60
              : 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Menu Icon --- (Keep as is)
            Get.width < 768
                ? GestureDetector(
                onTap: () {
                  sidebarController.showsidebar.value = true;
                },
                child: Padding(
                    padding: const EdgeInsets.only(left: 10, top: 10),
                    child: Icon(Icons.menu)))
                : const SizedBox.shrink(),
            SizedBox(
              height: width < 425
                  ? 20
                  : width < 768
                  ? 20
                  : width < 1024
                  ? 80
                  : width <= 1440
                  ? 80
                  : width > 1440 && width <= 2550
                  ? 80
                  : 80,
            ),
            // --- Search Bar --- (Keep as is)
            Center(
              child: SizedBox(
                width: width < 425
                    ? 250
                    : width < 768
                    ? 350
                    : width < 1024
                    ? 400
                    : width <= 1440
                    ? 500
                    : width > 1440 && width <= 2550
                    ? 500
                    : 800,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16.0,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: secondaryColor,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
            // --- Header Row ---
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: width < 425
                      ? 20
                      : width < 768
                      ? 20
                      : width < 1024
                      ? 40
                      : width <= 1440
                      ? 100
                      : width > 1440 && width <= 2550
                      ? 100
                      : 80,
                  vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: width < 425
                        ? 40
                        : width < 500
                        ? 40
                        : width < 768
                        ? 40
                        : width < 1024
                        ? 40
                        : width <= 1440
                        ? 50
                        : width > 1440 && width <= 2550
                        ? 50
                        : 80,
                  ),
                  Expanded(
                    child: Text(
                      'Name', // Keep header as 'Name'
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Email', // Keep header as 'Email'
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Visibility', // Changed header to 'Visibility' as per Firestore field
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(width: 30,)
                ],
              ),
            ),
            // --- StreamBuilder for User List ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Listen to the 'users' collection
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  // --- Handle Loading State ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // --- Handle Error State ---
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  // --- Handle No Data State ---
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }

                  // --- Process Data ---
                  final userDocs = snapshot.data!.docs;

                  // Map Firestore documents to your desired Map structure
                  List<Map<String, dynamic>> fetchedUsersData =
                  userDocs.map((doc) {
                    // Explicitly cast data to Map<String, dynamic>
                    final data = doc.data() as Map<String, dynamic>?;

                    // Handle potential null data map
                    if (data == null) {
                      return {
                        'uid': doc.id, // Use document ID as fallback UID
                        'name': 'Error: Null data',
                        'email': 'N/A',
                        'visibility': 'N/A', // Field from Firestore
                        'profileImage': null, // Assuming no profile image field yet
                      };
                    }

                    return {
                      // Use the 'uid' field from the document, fallback to doc.id
                      'uid': data['uid'] ?? doc.id,
                      // Use 'name' or 'displayName' field, provide default
                      'name': data['name'] ?? data['displayName'] ?? 'No Name',
                      // Use 'email' field, provide default
                      'email': data['email'] ?? 'No Email',
                      // Use 'visibility' field from Firestore for the role column
                      'visibility': data['visibility'] ?? 'N/A',
                      // Try to get profileImage, default to null if not present
                      'profileImage': data['profileImage'],
                    };
                  }).toList();

                  // Apply the search filter
                  final filteredUsers = fetchedUsersData.where((user) {
                    // Make sure 'name' exists and is a string before calling toLowerCase
                    final name = user['name'] as String?;
                    return name?.toLowerCase().contains(searchQuery) ?? false;
                  }).toList();

                  // --- Build ListView with Filtered Data ---
                  return ListView.builder(
                    itemCount: filteredUsers.length, // Use filtered list length
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index]; // Use filtered user data

                      // Get profileImage safely
                      final profileImage = user['profileImage'] as String?;

                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: width < 380
                                ? 5
                                : width < 425
                                ? 15
                                : width < 768
                                ? 20
                                : width < 1024
                                ? 20
                                : width <= 1440
                                ? 90
                                : width > 1440 && width <= 2550
                                ? 90
                                : 80),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // --- Profile Image/Icon ---
                                Container(
                                  width: width < 425
                                      ? 40
                                      : width < 768
                                      ? 40
                                      : width < 1024
                                      ? 50
                                      : width <= 1440
                                      ? 50
                                      : width > 1440 && width <= 2550
                                      ? 50
                                      : 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    // Show red background only if URL is null/empty
                                    color: (profileImage == null || profileImage.isEmpty)
                                        ? Colors.red
                                        : Colors.transparent,
                                  ),
                                  child: (profileImage != null && profileImage.isNotEmpty)
                                      ? CircleAvatar(
                                    backgroundImage: NetworkImage(profileImage),
                                    backgroundColor: Colors.grey[200], // Placeholder bg
                                    onBackgroundImageError: (exception, stackTrace) {
                                      // Optional: Handle image loading errors
                                      print("Error loading image: $exception");
                                    },
                                  )
                                      : const Icon(Icons.person, color: Colors.white), // Default icon
                                ),
                                // --- Name ---
                                Expanded(
                                  child: SizedBox(
                                    width: width < 425
                                        ? 20
                                        : width < 768
                                        ? 20
                                        : width < 1024
                                        ? 50
                                        : width <= 1440
                                        ? 50
                                        : width > 1440 && width <= 2550
                                        ? 50
                                        : 80,
                                    child: Text(
                                      // Use the 'name' field from the map
                                      user['name'] ?? 'N/A',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: width < 425
                                              ? 14
                                              : width < 768
                                              ? 16
                                              : width < 1024
                                              ? 15
                                              : width <= 1440
                                              ? 18
                                              : width > 1440 && width <= 2550
                                              ? 18
                                              : 30),
                                    ),
                                  ),
                                ),
                                // --- Email ---
                                Expanded(
                                    child: SizedBox(
                                      width: width < 425
                                          ? 20
                                          : width < 768
                                          ? 20
                                          : width < 1024
                                          ? 50
                                          : width <= 1440
                                          ? 80
                                          : width > 1440 && width <= 2550
                                          ? 80
                                          : 80,
                                      child: Text(
                                        // Use the 'email' field from the map
                                        user['email'] ?? 'N/A',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: width < 425
                                                ? 14
                                                : width < 768
                                                ? 16
                                                : width < 1024
                                                ? 15
                                                : width <= 1440
                                                ? 18
                                                : width > 1440 && width <= 2550
                                                ? 18
                                                : 30),
                                      ),
                                    )),
                                // --- Visibility (Role Column) ---
                                Expanded(
                                    child: Text(
                                      // Use the 'visibility' field from the map
                                      user['visibility'] ?? 'N/A',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: width < 425
                                              ? 14
                                              : width < 768
                                              ? 16
                                              : width < 1024
                                              ? 15
                                              : width <= 1440
                                              ? 18
                                              : width > 1440 && width <= 2550
                                              ? 18
                                              : 30),
                                    )),
                                width < 500
                                    ? Column(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        // TODO: Implement Edit User Action
                                        print('Edit user: ${user['uid']}');
                                      },
                                      iconSize: 25,
                                      icon: const Icon(Icons.edit),
                                      color: primaryColorKom,
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        // TODO: Implement Delete User Action
                                        _showDeleteConfirmationDialog(context, user['uid'], user['name']);
                                        print('Delete user: ${user['uid']}');
                                      },
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      iconSize: 25,
                                    ),
                                  ],
                                )
                                    : Row(
                                  children: [
                                    // IconButton(
                                    //   onPressed: () {
                                    //     // TODO: Implement Edit User Action
                                    //     print('Edit user: ${user['uid']}');
                                    //   },
                                    //   icon: const Icon(Icons.edit),
                                    //   iconSize: 25,
                                    //   color: primaryColorKom,
                                    // ),
                                    IconButton(
                                      onPressed: () {
                                        // TODO: Implement Delete User Action
                                        _showDeleteConfirmationDialog(context, user['uid'], user['name']);
                                        print('Delete user: ${user['uid']}');
                                      },
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      iconSize: 25,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                          ],
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
    );
  }

  // --- Helper Function for Delete Confirmation ---
  Future<void> _showDeleteConfirmationDialog(BuildContext context, String? userId, String? userName) async {
    if (userId == null) return; // Don't show dialog if userId is null

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete the user "${userName ?? 'this user'}"?'),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                try {
                  // Perform the delete operation
                  await _firestore.collection('users').doc(userId).delete();
                  Navigator.of(dialogContext).pop(); // Close the dialog
                  // Optional: Show a success message (e.g., using a SnackBar)
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User "${userName ?? userId}" deleted successfully.'))
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop(); // Close the dialog
                  // Optional: Show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting user: $e'))
                  );
                  print("Error deleting user: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }
}