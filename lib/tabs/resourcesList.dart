import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../colors.dart';

class ResourcesList extends StatefulWidget {
  const ResourcesList({super.key});

  @override
  State<ResourcesList> createState() => _ResourcesListState();
}

class _ResourcesListState extends State<ResourcesList> {
  bool _isDeleting = false;

  Future<void> _deleteResource(String docId, String imageUrl) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Extract the storage path from the image URL
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);

      // Delete the image from Firebase Storage
      await storageRef.delete().timeout(const Duration(seconds: 10));

      // Delete the document from Firestore
      await FirebaseFirestore.instance
          .collection('resources')
          .doc(docId)
          .delete()
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete resource: $e')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resources List',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: theme.colorScheme.onSurface,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: pink,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('resources')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No resources found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final description = data['description'] ?? '';
              final imageUrl = data['imageUrl'] ?? '';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 150,
                                color: theme.colorScheme.surfaceContainer,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: theme.colorScheme.surfaceContainer,
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: pink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          if (description.length > 100) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(title),
                                content: SingleChildScrollView(
                                  child: Text(description),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 7,
                          overflow: TextOverflow.ellipsis,

                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _isDeleting
                            ? const CircularProgressIndicator()
                            : IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _deleteResource(doc.id, imageUrl),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}