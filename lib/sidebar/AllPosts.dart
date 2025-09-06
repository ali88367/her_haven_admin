import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:herhaven_admin/sidebar/sidebar_controller.dart';
import '../colors.dart';

class AllPosts extends StatefulWidget {
  const AllPosts({super.key});

  @override
  State<AllPosts> createState() => _AllPostsState();
}

class _AllPostsState extends State<AllPosts> with TickerProviderStateMixin {
  final SidebarController sidebarController = Get.find<SidebarController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _listAnimationController;
  late Animation<double> _listScaleAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String postId, String title) async {
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
                    'Are you sure you want to delete "$title"?',
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
                  style: TextStyle(
                      color: pink, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  try {
                    await _firestore.collection('posts').doc(postId).delete();
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Post "$title" deleted successfully.'),
                        backgroundColor: pink,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting post: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text('Delete',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRepliesDialog(BuildContext context, String postId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AnimatedScaleDialog(
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 8,
            title: Text(
              'Replies',
              style: TextStyle(
                color: text1,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxHeight: 400),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .doc(postId)
                    .collection('replies')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
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
                        'No replies found.',
                        style: TextStyle(color: text1, fontSize: 16),
                      ),
                    );
                  }

                  final replies = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      final reply = replies[index];
                      final replyData = reply.data() as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          shadowColor: black.withOpacity(0.1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: blue.withOpacity(0.3), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                        replyData['profileUrl'] == null ||
                                            replyData['profileUrl'].isEmpty
                                            ? pink
                                            : blue.withOpacity(0.9),
                                        backgroundImage:
                                        replyData['profileUrl'] != null &&
                                            replyData['profileUrl']
                                                .isNotEmpty
                                            ? NetworkImage(
                                            replyData['profileUrl'])
                                            : null,
                                        child: replyData['profileUrl'] == null ||
                                            replyData['profileUrl'].isEmpty
                                            ? Icon(Icons.person_rounded,
                                            color: Colors.white, size: 20)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          replyData['authorName'] ?? 'Anonymous',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: text1,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    replyData['comment'] ?? 'No comment',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: black.withOpacity(0.8),
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    replyData['timestamp'] != null
                                        ? (replyData['timestamp'] as Timestamp)
                                        .toDate()
                                        .toString()
                                        : 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: black.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
            actions: [
              TextButton(
                child: Text(
                  'Close',
                  style: TextStyle(
                      color: pink, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
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
                        'All Posts',
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
                const SizedBox(height: 24),
                // Post List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('posts').snapshots(),
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
                            'No posts found.',
                            style: TextStyle(color: text1, fontSize: 16),
                          ),
                        );
                      }

                      final posts = snapshot.data!.docs;

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: width < 768 ? 16 : 32, vertical: 8),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final postData = post.data() as Map<String, dynamic>;
                          final postId = post.id;

                          return ScaleTransition(
                            scale: _listScaleAnimation,
                            child: FadeTransition(
                              opacity: Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(
                                CurvedAnimation(
                                  parent: _listAnimationController,
                                  curve: Interval(0.05 * index, 1.0,
                                      curve: Curves.easeOutCubic),
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
                                      border: Border.all(
                                          color: pink.withOpacity(0.3), width: 1),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      hoverColor: purple.withOpacity(0.1),
                                      onTap: () {
                                        // Optional: Add tap action (e.g., view post details)
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    postData['title'] ??
                                                        'No Title',
                                                    style: TextStyle(
                                                      fontSize:
                                                      width < 768 ? 16 : 18,
                                                      fontWeight: FontWeight.w600,
                                                      color: text1,
                                                    ),
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                  const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent
                                                        .withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete_rounded,
                                                        color: Colors.redAccent,
                                                        size: 20),
                                                    onPressed: () =>
                                                        _showDeleteConfirmationDialog(
                                                            context,
                                                            postId,
                                                            postData['title'] ??
                                                                'Post'),
                                                    tooltip: 'Delete Post',
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                    const BoxConstraints(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Posted by: ${postData['userName'] ?? 'Anonymous'}',
                                              style: TextStyle(
                                                fontSize:
                                                width < 768 ? 14 : 15,
                                                color: black.withOpacity(0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Category: ${postData['category'] ?? 'Uncategorized'}',
                                              style: TextStyle(
                                                fontSize:
                                                width < 768 ? 14 : 15,
                                                color: black.withOpacity(0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              postData['description'] ??
                                                  'No description',
                                              style: TextStyle(
                                                fontSize:
                                                width < 768 ? 14 : 15,
                                                color: black.withOpacity(0.8),
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Likes: ${postData['likes'] ?? 0}',
                                                  style: TextStyle(
                                                    fontSize:
                                                    width < 768 ? 12 : 13,
                                                    color: blue,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showRepliesDialog(
                                                          context, postId),
                                                  child: Text(
                                                    'Comments: ${postData['commentsCount'] ?? 0}',
                                                    style: TextStyle(
                                                      fontSize:
                                                      width < 768 ? 12 : 13,
                                                      color: blue,
                                                      fontWeight: FontWeight.w600,
                                                      decoration:
                                                      TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Posted on: ${postData['createdAt'] != null ? (postData['createdAt'] as Timestamp).toDate().toString() : 'Unknown'}',
                                              style: TextStyle(
                                                fontSize:
                                                width < 768 ? 12 : 13,
                                                color: black.withOpacity(0.7),
                                              ),
                                              overflow: TextOverflow.ellipsis,
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

class _AnimatedScaleDialogState extends State<AnimatedScaleDialog>
    with SingleTickerProviderStateMixin {
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