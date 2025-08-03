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

class _ResourcesState extends State<Resources> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Uint8List? _imageBytes;
  String? _fileName;
  bool _isUploading = false;
  bool _isFirebaseInitialized = false;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      setState(() => _isFirebaseInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase initialization failed: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _imageBytes = result.files.single.bytes!;
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selection failed: $e')),
        );
      }
    }
  }

  Future<void> _uploadResource() async {
    if (!_isFirebaseInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase is not initialized')),
        );
      }
      return;
    }

    if (_imageBytes == null ||
        _titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select an image and enter a title and description')),
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
        setState(() {
          _uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
        });
      });

      // Timeout after 30 seconds for upload
      final snapshot = await uploadTask.timeout(const Duration(seconds: 30));
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Firestore write with timeout
      await FirebaseFirestore.instance.collection('resources').add({
        'imageUrl': imageUrl,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _imageBytes = null;
          _fileName = null;
          _titleController.clear();
          _descriptionController.clear();
          _uploadProgress = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Resource',style: TextStyle(color: Colors.white),),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: theme.colorScheme.onSurface,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: pink
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share a Resource',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: pink,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _imageBytes != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload an image',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: pink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Resource Title',
                    hintText: 'Enter a title for your resource...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Article / Guide Description',
                    hintText: 'Describe your resource...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: _isUploading
                      ? Column(
                    children: [
                      CircularProgressIndicator(
                        value: _uploadProgress,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      if (_uploadProgress != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${(_uploadProgress! * 100).toStringAsFixed(0)}% Complete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  )
                      : ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload Resource'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
                      backgroundColor: pink,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: _uploadResource,
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}