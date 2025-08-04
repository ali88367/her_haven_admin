import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../colors.dart';

class ResourcesList extends StatefulWidget {
  const ResourcesList({super.key});

  @override
  State<ResourcesList> createState() => _ResourcesListState();
}

class _ResourcesListState extends State<ResourcesList> with TickerProviderStateMixin {
  bool _isDeleting = false;
  bool _isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _listAnimationController;
  late Animation<double> _listScaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _listAnimationController.forward();
  }

  Future<void> _deleteResource(String docId, String imageUrl) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete().timeout(const Duration(seconds: 10));
      await FirebaseFirestore.instance
          .collection('resources')
          .doc(docId)
          .delete()
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Resource deleted successfully!'),
            backgroundColor: pink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete resource: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _showEditDialog(String docId, String currentTitle, String currentDescription, String currentImageUrl) async {
    final TextEditingController titleController = TextEditingController(text: currentTitle);
    final TextEditingController descriptionController = TextEditingController(text: currentDescription);
    Uint8List? newImageBytes;
    String? newFileName;
    double? uploadProgress;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              elevation: 2,
              content: SingleChildScrollView(
                child: Container(
                  width: width < 768 ? double.infinity : 500,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Resource',
                        style: TextStyle(
                          fontSize: width < 768 ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: pink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Image Upload
                      GestureDetector(
                        onTap: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(type: FileType.image);
                            if (result != null && result.files.single.bytes != null) {
                              setDialogState(() {
                                newImageBytes = result.files.single.bytes!;
                                newFileName = result.files.single.name;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Image selection failed: $e'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  margin: const EdgeInsets.all(12),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: width < 768 ? 120 : 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: newImageBytes != null ? pink : blue.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: newImageBytes != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              newImageBytes!,
                              fit: BoxFit.cover,
                              height: width < 768 ? 120 : 150,
                              width: double.infinity,
                            ),
                          )
                              : currentImageUrl.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              currentImageUrl,
                              fit: BoxFit.cover,
                              height: width < 768 ? 120 : 150,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(color: pink));
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(Icons.error_rounded, color: Colors.redAccent, size: 24),
                                );
                              },
                            ),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_rounded,
                                size: width < 768 ? 32 : 40,
                                color: blue,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload new image',
                                style: TextStyle(
                                  fontSize: width < 768 ? 13 : 14,
                                  color: pink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Title Field
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Resource title...',
                          labelStyle: TextStyle(color: pink, fontSize: 14),
                          filled: true,
                          fillColor: primaryColor.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: pink, width: 1.5),
                          ),
                        ),
                        style: TextStyle(
                          color: black,
                          fontWeight: FontWeight.w500,
                          fontSize: width < 768 ? 15 : 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Description Field
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Resource description...',
                          labelStyle: TextStyle(color: pink, fontSize: 14),
                          filled: true,
                          fillColor: primaryColor.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: pink, width: 1.5),
                          ),
                        ),
                        style: TextStyle(
                          color: black,
                          fontWeight: FontWeight.w500,
                          fontSize: width < 768 ? 15 : 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Upload Progress or Buttons
                      Center(
                        child: _isEditing
                            ? Column(
                          children: [
                            CircularProgressIndicator(
                              value: uploadProgress,
                              valueColor: AlwaysStoppedAnimation<Color>(pink),
                              strokeWidth: 3,
                            ),
                            if (uploadProgress != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${(uploadProgress! * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: black.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: width < 768 ? 13 : 14,
                                ),
                              ),
                            ],
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.save_rounded,
                                  color: pink,
                                  size: 18,
                                ),
                              ),
                              label: Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: width < 768 ? 14 : 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                shadowColor: black.withOpacity(0.2),
                              ),
                              onPressed: () async {
                                if (titleController.text.trim().isEmpty ||
                                    descriptionController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                      content: Text('Please enter a title and description'),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      margin: const EdgeInsets.all(12),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  _isEditing = true;
                                  uploadProgress = 0.0;
                                });

                                try {
                                  String? newImageUrl = currentImageUrl;
                                  if (newImageBytes != null) {
                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child('resources/${DateTime.now().millisecondsSinceEpoch}_$newFileName');
                                    final uploadTask = storageRef.putData(newImageBytes!);
                                    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
                                      setDialogState(() {
                                        uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
                                      });
                                    });
                                    final snapshot = await uploadTask.timeout(const Duration(seconds: 30));
                                    newImageUrl = await snapshot.ref.getDownloadURL();
                                    if (currentImageUrl.isNotEmpty) {
                                      await FirebaseStorage.instance
                                          .refFromURL(currentImageUrl)
                                          .delete()
                                          .timeout(const Duration(seconds: 10));
                                    }
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('resources')
                                      .doc(docId)
                                      .update({
                                    'title': titleController.text.trim(),
                                    'description': descriptionController.text.trim(),
                                    'imageUrl': newImageUrl,
                                    'timestamp': FieldValue.serverTimestamp(),
                                  })
                                      .timeout(const Duration(seconds: 10));

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                        content: Text('Resource updated successfully!'),
                                        backgroundColor: pink,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        margin: const EdgeInsets.all(12),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update resource: $e'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        margin: const EdgeInsets.all(12),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setDialogState(() {
                                      _isEditing = false;
                                      uploadProgress = null;
                                    });
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDescriptionDialog(String title, String description) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          elevation: 2,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: pink,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: black.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: pink,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
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
              primaryColor,
              purple.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width < 768 ? 16 : 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Resources List',
                        style: TextStyle(
                          fontSize: width < 768 ? 22 : 26,
                          fontWeight: FontWeight.w700,
                          color: text1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.list_rounded,
                          color: pink,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Resource List
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: width < 768 ? double.infinity : width < 1024 ? 600 : 700,
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('resources')
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
                                style: TextStyle(
                                  color: text1,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'No resources found',
                                style: TextStyle(
                                  color: text1,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: width < 768 ? 16 : 24,
                              vertical: 8,
                            ),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final title = data['title'] ?? 'Untitled';
                              final description = data['description'] ?? '';
                              final imageUrl = data['imageUrl'] ?? '';

                              return ScaleTransition(
                                scale: _listScaleAnimation,
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _listAnimationController,
                                      curve: Interval(0.05 * index, 1.0, curve: Curves.easeOutCubic),
                                    ),
                                  ),
                                  child: Material(
                                    elevation: 2,
                                    borderRadius: BorderRadius.circular(12),
                                    shadowColor: black.withOpacity(0.15),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: pink.withOpacity(0.3), width: 1),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          if (description.length > 100) {
                                            _showDescriptionDialog(title, description);
                                          }
                                        },
                                        hoverColor: purple.withOpacity(0.1),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Image
                                              Container(
                                                height: width < 768 ? 120 : 150,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: primaryColor.withOpacity(0.5),
                                                  borderRadius: BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: black.withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: imageUrl.isNotEmpty
                                                    ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    height: width < 768 ? 120 : 150,
                                                    width: double.infinity,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          color: pink,
                                                          strokeWidth: 3,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Center(
                                                        child: Icon(
                                                          Icons.error_rounded,
                                                          color: Colors.redAccent,
                                                          size: 28,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                                    : Center(
                                                  child: Icon(
                                                    Icons.image_rounded,
                                                    color: blue,
                                                    size: 32,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // Title
                                              Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: width < 768 ? 16 : 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: pink,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                              const SizedBox(height: 8),
                                              // Description
                                              GestureDetector(
                                                onTap: () {
                                                  if (description.length > 100) {
                                                    _showDescriptionDialog(title, description);
                                                  }
                                                },
                                                child: Text(
                                                  description,
                                                  style: TextStyle(
                                                    fontSize: width < 768 ? 14 : 15,
                                                    color: black.withOpacity(0.8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 4,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // Actions
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: blue.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.edit_rounded,
                                                        color: blue,
                                                        size: 20,
                                                      ),
                                                      onPressed: () => _showEditDialog(doc.id, title, description, imageUrl),
                                                      tooltip: 'Edit Resource',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.redAccent.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.delete_rounded,
                                                        color: Colors.redAccent,
                                                        size: 20,
                                                      ),
                                                      onPressed: _isDeleting
                                                          ? null
                                                          : () => _deleteResource(doc.id, imageUrl),
                                                      tooltip: 'Delete Resource',
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }
}