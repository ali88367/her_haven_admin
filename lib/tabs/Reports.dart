import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Login.dart';
import '../colors.dart'; // For Post model

class AdminReportedPostsScreen extends StatelessWidget {
  const AdminReportedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyles();
    final controller = Get.put(AdminReportedPostsController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, pink.withOpacity(0.7)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24.0),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adds spacing around TabBar
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade900.withOpacity(0.15),
                      Colors.grey.shade900.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: controller.tabController,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.pink.shade600,
                        Colors.pink.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorPadding: const EdgeInsets.all(6.0), // Slightly increased for better spacing
                  indicatorSize: TabBarIndicatorSize.tab, // Aligns indicator with tab
                  labelColor: Colors.white, // White for better contrast on pink indicator
                  unselectedLabelColor: Colors.white.withOpacity(0.7), // Softer unselected color
                  labelStyle: textStyle.poppins500(16.0, Colors.white), // Bolder for selected tab
                  unselectedLabelStyle: textStyle.poppins400(14.0, Colors.white.withOpacity(0.7)),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16.0), // Spacious tap targets
                  overlayColor: WidgetStateProperty.all(Colors.pink.withOpacity(0.1)), // Subtle tap effect
                  tabs: const [
                    Tab(text: 'Reported Posts'),
                    Tab(text: 'Blocked Posts'),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              Expanded(
                child: TabBarView(
                  controller: controller.tabController,
                  children: [
                    // Unhidden Posts Tab
                    Obx(() {
                      if (controller.isLoading.value) {
                        return Center(child: CircularProgressIndicator(color: pink));
                      }
                      if (controller.errorMessage.value.isNotEmpty) {
                        return Center(
                          child: Text(
                            controller.errorMessage.value,
                            style: textStyle.poppins500(18.0, Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      if (controller.unhiddenPosts.isEmpty) {
                        return Center(
                          child: Text(
                            'No unhidden reported posts found.',
                            style: textStyle.poppins500(18.0, black.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        itemCount: controller.unhiddenPosts.length,
                        itemBuilder: (context, index) {
                          final reportedPost = controller.unhiddenPosts[index];
                          return _ReportedPostCard(
                            key: ValueKey(reportedPost['postId']),
                            post: reportedPost['post'],
                            reporters: reportedPost['reporters'],
                            controller: controller,
                            textStyle: textStyle,
                          );
                        },
                      );
                    }),
                    // Hidden Posts Tab
                    Obx(() {
                      if (controller.isLoading.value) {
                        return Center(child: CircularProgressIndicator(color: pink));
                      }
                      if (controller.errorMessage.value.isNotEmpty) {
                        return Center(
                          child: Text(
                            controller.errorMessage.value,
                            style: textStyle.poppins500(18.0, Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      if (controller.hiddenPosts.isEmpty) {
                        return Center(
                          child: Text(
                            'No hidden reported posts found.',
                            style: textStyle.poppins500(18.0, black.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        itemCount: controller.hiddenPosts.length,
                        itemBuilder: (context, index) {
                          final reportedPost = controller.hiddenPosts[index];
                          return _ReportedPostCard(
                            key: ValueKey(reportedPost['postId']),
                            post: reportedPost['post'],
                            reporters: reportedPost['reporters'],
                            controller: controller,
                            textStyle: textStyle,
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportedPostCard extends StatefulWidget {
  final Post? post;
  final List<String> reporters;
  final AdminReportedPostsController controller;
  final TextStyles textStyle;

  const _ReportedPostCard({
    super.key,
    required this.post,
    required this.reporters,
    required this.controller,
    required this.textStyle,
  });

  @override
  _ReportedPostCardState createState() => _ReportedPostCardState();
}

class _ReportedPostCardState extends State<_ReportedPostCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.post == null || widget.post!.id == null || widget.post!.title == null || widget.post!.content == null) {
      print('Invalid post data detected: postId=${widget.post?.id ?? "null"}, title=${widget.post?.title ?? "null"}, content=${widget.post?.content ?? "null"}');
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5, // 50% of screen width
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.0,
                offset: const Offset(0, 4.0),
              ),
            ],
          ),
          child: Text(
            'Post unavailable (may have been deleted or corrupted). Reported by ${widget.reporters.length} user${widget.reporters.length == 1 ? '' : 's'}.',
            style: widget.textStyle.poppins500(12.0, Colors.grey.shade800),
          ),
        ),
      );
    }

    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: GestureDetector(
          onTap: () => _showPostDetailsDialog(context, widget.post!, widget.reporters, widget.controller),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
            width: MediaQuery.of(context).size.width * 0.5, // 50% of screen width
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: pink,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isHovered ? 0.2 : 0.15),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4.0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post!.title!,
                  style: widget.textStyle.mack700(18.0, Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.post!.content!,
                  style: widget.textStyle.poppins500(14.0, Colors.white.withOpacity(0.9)),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'This post is reported by ${widget.reporters.length} user${widget.reporters.length == 1 ? '' : 's'}.',
                  style: widget.textStyle.poppins400(12.0, Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPostDetailsDialog(BuildContext context, Post post, List<String> reporters, AdminReportedPostsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF6E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        contentPadding: const EdgeInsets.all(32.0),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.title ?? 'Untitled',
                  style: widget.textStyle.mack700(28.0, black),
                ),
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    post.content ?? 'No content',
                    style: widget.textStyle.poppins400(16.0, black),
                  ),
                ),
                const SizedBox(height: 20.0),
                if (post.category != null)
                  Text(
                    'Category: ${post.category}',
                    style: widget.textStyle.poppins500(14.0, black.withOpacity(0.7)),
                  ),
                const SizedBox(height: 12.0),
                if (post.author != null)
                  Text(
                    'Author: ${post.author}',
                    style: widget.textStyle.poppins500(14.0, black.withOpacity(0.7)),
                  ),
                const SizedBox(height: 12.0),
                if (post.timestamp != null)
                  Text(
                    'Posted: ${controller.formatTimestamp(post.timestamp!)}',
                    style: widget.textStyle.poppins500(14.0, black.withOpacity(0.7)),
                  ),
                const SizedBox(height: 12.0),
                Text(
                  'Reported by ${reporters.length} user${reporters.length == 1 ? '' : 's'}.',
                  style: widget.textStyle.poppins500(14.0, black.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: widget.textStyle.poppins500(16.0, black.withOpacity(0.7)),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                controller.togglePostVisibility(post.id!);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: post.isHidden ?? false
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4.0),
                    ),
                  ],
                ),
                child: Text(
                  post.isHidden ?? false ? 'UnBlock Post' : 'Block Post',
                  style: widget.textStyle.mack700(16.0, Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminReportedPostsController extends GetxController with SingleGetTickerProviderMixin {
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final reportedPosts = <Map<String, dynamic>>[].obs;
  final hiddenPosts = <Map<String, dynamic>>[].obs;
  final unhiddenPosts = <Map<String, dynamic>>[].obs;
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    fetchReportedPosts();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> fetchReportedPosts() async {
    try {
      isLoading.value = true;
      final firestore = FirebaseFirestore.instance;

      final reportsSnapshot = await firestore.collection('reports').get();
      final Map<String, List<String>> postReporters = {};

      for (var report in reportsSnapshot.docs) {
        final postId = report.data()['postId'] as String?;
        final reportedBy = report.data()['reportedBy'] as String?;
        if (postId != null && reportedBy != null) {
          postReporters.putIfAbsent(postId, () => []).add(reportedBy);
        } else {
          print('Invalid report data: postId=$postId, reportedBy=$reportedBy');
        }
      }

      final List<Map<String, dynamic>> reportedPostsList = [];
      for (var postId in postReporters.keys) {
        final postDoc = await firestore.collection('posts').doc(postId).get();
        if (postDoc.exists) {
          try {
            final post = Post.fromFirestore(postDoc);
            if (post.id != null && post.title != null && post.content != null) {
              reportedPostsList.add({
                'postId': postId,
                'post': post,
                'reporters': postReporters[postId]!,
              });
            } else {
              print('Skipping post with missing fields: postId=$postId, title=${post.title ?? "null"}, content=${post.content ?? "null"}');
              reportedPostsList.add({
                'postId': postId,
                'post': null,
                'reporters': postReporters[postId]!,
              });
            }
          } catch (e) {
            print('Error parsing post $postId: $e');
            reportedPostsList.add({
              'postId': postId,
              'post': null,
              'reporters': postReporters[postId]!,
            });
          }
        } else {
          print('Post not found: postId=$postId');
          reportedPostsList.add({
            'postId': postId,
            'post': null,
            'reporters': postReporters[postId]!,
          });
        }
      }

      reportedPosts.assignAll(reportedPostsList);
      _updatePostLists();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Failed to load reported posts: $e';
      print('Error fetching reported posts: $e');
    }
  }

  void _updatePostLists() {
    hiddenPosts.assignAll(
      reportedPosts.where((rp) => rp['post'] != null && rp['post'].isHidden == true).toList(),
    );
    unhiddenPosts.assignAll(
      reportedPosts.where((rp) => rp['post'] == null || rp['post'].isHidden == false).toList(),
    );
  }

  Future<void> togglePostVisibility(String postId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final postRef = firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) {
        Get.snackbar(
          'Error',
          'Post not found.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final currentIsHidden = postDoc.data()?['isHidden'] as bool? ?? false;
      await postRef.update({'isHidden': !currentIsHidden});

      final index = reportedPosts.indexWhere((rp) => rp['postId'] == postId);
      if (index != -1 && reportedPosts[index]['post'] != null) {
        final updatedPost = Post(
          id: reportedPosts[index]['post'].id,
          title: reportedPosts[index]['post'].title,
          content: reportedPosts[index]['post'].content,
          category: reportedPosts[index]['post'].category,
          author: reportedPosts[index]['post'].author,
          timestamp: reportedPosts[index]['post'].timestamp,
          likes: reportedPosts[index]['post'].likes,
          likedBy: reportedPosts[index]['post'].likedBy,
          comments: reportedPosts[index]['post'].comments,
          isHidden: !currentIsHidden,
        );
        reportedPosts[index]['post'] = updatedPost;
        reportedPosts.refresh();
        _updatePostLists();
      }

      Get.snackbar(
        'Success',
        currentIsHidden ? 'Post unhidden.' : 'Post hidden.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: pink,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error toggling post visibility: $e');
      Get.snackbar(
        'Error',
        'Failed to update post visibility: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String? getCurrentUserId() {
    return '';
  }
}

class Post {
  String? id;
  String? title;
  String? content;
  String? category;
  String? author;
  Timestamp? timestamp;
  int? likes;
  List<String>? likedBy;
  int? comments;
  bool? isHidden;

  Post({
    this.id,
    this.title,
    this.content,
    this.category,
    this.author,
    this.timestamp,
    this.likes,
    this.likedBy,
    this.comments,
    this.isHidden = false,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      print('Error: Firestore document data is null for docId=${doc.id}');
      return Post(id: doc.id);
    }
    return Post(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled',
      content: data['description'] as String? ?? 'No content',
      category: data['category'] as String?,
      author: data['author'] as String?,
      timestamp: data['timestamp'] as Timestamp?,
      likes: data['likes'] as int?,
      likedBy: data['likedBy'] != null ? List<String>.from(data['likedBy']) : [],
      comments: data['comments'] as int?,
      isHidden: data['isHidden'] as bool? ?? false,
    );
  }
}