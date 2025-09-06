import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import '../colors.dart';

class Resources extends StatefulWidget {
  const Resources({super.key});

  @override
  State<Resources> createState() => _ResourcesState();
}

class _ResourcesState extends State<Resources> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  Uint8List? _imageBytes;
  String? _fileName;
  String? _selectedCategory;
  bool _isUploading = false;
  bool _isFirebaseInitialized = false;
  double? _uploadProgress;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardScaleAnimation;

  final List<String> _categories = [
    'Educational Guides',
    'HerHaven News',
    'Know Your Rights',
    'Life After Abuse',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _cardAnimationController.forward();

    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      if (mounted) {
        setState(() => _isFirebaseInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase initialization failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        if (mounted) {
          setState(() {
            _imageBytes = result.files.single.bytes!;
            _fileName = result.files.single.name;
            _cardAnimationController.forward(from: 0.0);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selection failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _uploadResource() async {
    if (!_isFirebaseInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase is not initialized'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (_imageBytes == null ||
        _titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        (_selectedCategory == null || (_selectedCategory == 'Custom' && _customCategoryController.text.trim().isEmpty))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select an image, enter a title, description, and category'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('resources/${DateTime.now().millisecondsSinceEpoch}_$_fileName');

      final uploadTask = storageRef.putData(_imageBytes!);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
          });
        }
      });

      final snapshot = await uploadTask.timeout(const Duration(seconds: 30));
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('resources').add({
        'imageUrl': imageUrl,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory == 'Custom' ? _customCategoryController.text.trim() : _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _imageBytes = null;
          _fileName = null;
          _titleController.clear();
          _descriptionController.clear();
          _customCategoryController.clear();
          _selectedCategory = null;
          _uploadProgress = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Resource uploaded successfully!'),
            backgroundColor: pink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
        });
      }
    }
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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: width < 768 ? 16 : 32,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upload Resource',
                        style: TextStyle(
                          fontSize: width < 768 ? 22 : 26,
                          fontWeight: FontWeight.w800,
                          color: text1,
                        ),
                      ),
                      Container(
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
                          Icons.cloud_upload_rounded,
                          color: pink,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ScaleTransition(
                    scale: _cardScaleAnimation,
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(16),
                      shadowColor: black.withOpacity(0.15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: pink.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share a Resource',
                              style: TextStyle(
                                fontSize: width < 768 ? 18 : 20,
                                fontWeight: FontWeight.w700,
                                color: pink,
                              ),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: _pickImage,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: width < 768 ? 150 : 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _imageBytes != null ? pink : blue.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _imageBytes != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    height: width < 768 ? 150 : 200,
                                    width: double.infinity,
                                  ),
                                )
                                    : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_rounded,
                                      size: width < 768 ? 40 : 48,
                                      color: blue,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to upload an image',
                                      style: TextStyle(
                                        fontSize: width < 768 ? 14 : 16,
                                        color: pink,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: pink.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.title_rounded,
                                    color: pink,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      labelText: 'Resource Title',
                                      hintText: 'Enter a title for your resource...',
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
                                    ),
                                    style: TextStyle(color: black, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: pink.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.description_rounded,
                                    color: pink,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _descriptionController,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      labelText: 'Article / Guide Description',
                                      hintText: 'Describe your resource...',
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
                                    ),
                                    style: TextStyle(color: black, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: pink.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.category_rounded,
                                    color: pink,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: InputDecoration(
                                      labelText: 'Category',
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
                                    ),
                                    items: _categories.map((String category) {
                                      return DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(
                                          category,
                                          style: TextStyle(color: black, fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategory = newValue;
                                        if (newValue != 'Custom') {
                                          _customCategoryController.clear();
                                        }
                                      });
                                    },
                                    hint: Text(
                                      'Select a category',
                                      style: TextStyle(color: pink.withOpacity(0.6)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedCategory == 'Custom') ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: pink.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      color: pink,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _customCategoryController,
                                      decoration: InputDecoration(
                                        labelText: 'Custom Category',
                                        hintText: 'Enter custom category...',
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
                                      ),
                                      style: TextStyle(color: black, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),
                            Center(
                              child: _isUploading
                                  ? Column(
                                children: [
                                  CircularProgressIndicator(
                                    value: _uploadProgress,
                                    valueColor: AlwaysStoppedAnimation<Color>(pink),
                                    strokeWidth: 6,
                                  ),
                                  if (_uploadProgress != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      '${(_uploadProgress! * 100).toStringAsFixed(0)}% Complete',
                                      style: TextStyle(
                                        color: black.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                        fontSize: width < 768 ? 14 : 15,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                                  : ElevatedButton.icon(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.cloud_upload_rounded,
                                    color: pink,
                                    size: 24,
                                  ),
                                ),
                                label: Text(
                                  'Upload Resource',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: width < 768 ? 15 : 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: pink,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  shadowColor: black.withOpacity(0.2),
                                ),
                                onPressed: _uploadResource,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }
}