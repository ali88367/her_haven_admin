import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:get/get.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../colors.dart'; // Ensure this file defines `primaryColor` and `pink`

class UploadTermsPrivacyScreen extends StatelessWidget {
  const UploadTermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UploadTermsPrivacyController());
    final textStyle = TextStyles();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            padding:
            const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Legal Documents',
                  style: textStyle.mack700(28.0, Colors.white),
                ),
                const SizedBox(height: 24.0),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Added margin for spacing
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.0), // Softer corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          pink,
                          Colors.pink,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 6.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorPadding: const EdgeInsets.all(6.0), // Slightly increased padding
                    indicatorSize: TabBarIndicatorSize.tab, // Ensures indicator matches tab size
                    labelStyle: textStyle.poppins400(16.0, Colors.white), // Bolder font for selected tab
                    unselectedLabelStyle: textStyle.poppins400(14.0, Colors.white.withOpacity(0.7)),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16.0), // More spacious tabs
                    overlayColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.1)), // Subtle tap effect
                    tabs: const [
                      Tab(text: 'Terms & Conditions'),
                      Tab(text: 'Privacy Policy'),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.isFirstLoad.value) {
                      return Center(
                          child: CircularProgressIndicator(color: pink));
                    }
                    if (controller.errorMessage.value.isNotEmpty) {
                      return Center(
                        child: Text(
                          controller.errorMessage.value,
                          style: textStyle.poppins500(18.0, Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return GetBuilder<UploadTermsPrivacyController>(
                      builder: (ctrl) => TabBarView(
                        children: [
                          _buildEditorTab(
                            context: context,
                            textStyle: textStyle,
                            quillController: ctrl.termsQuillController,
                            onSave: () => ctrl.saveContent('terms'),
                            isLoading: ctrl.isLoading.value,
                          ),
                          _buildEditorTab(
                            context: context,
                            textStyle: textStyle,
                            quillController: ctrl.privacyQuillController,
                            onSave: () => ctrl.saveContent('privacy'),
                            isLoading: ctrl.isLoading.value,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorTab({
    required BuildContext context,
    required TextStyles textStyle,
    required QuillController quillController,
    required VoidCallback onSave,
    required bool isLoading,
  }) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10.0,
                offset: const Offset(0, 4.0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuillSimpleToolbar(
                controller: quillController,
                config: const QuillSimpleToolbarConfig(
                  showAlignmentButtons: true,
                  showColorButton: true, // Enable text color picker
                  showBackgroundColorButton: true, // Enable background color
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                height: 450,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: QuillEditor.basic(
                  controller: quillController,
                  config: const QuillEditorConfig(
                    padding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: isLoading ? null : onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLoading
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2.0),
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text('Save Changes',
                        style: textStyle.poppins500(16.0, Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadTermsPrivacyController extends GetxController {
  final _docRef =
  FirebaseFirestore.instance.collection('legal_documents').doc('main');

  final isLoading = true.obs;
  final isFirstLoad = true.obs;
  final errorMessage = ''.obs;

  late QuillController termsQuillController;
  late QuillController privacyQuillController;

  @override
  void onInit() {
    super.onInit();
    termsQuillController = QuillController.basic();
    privacyQuillController = QuillController.basic();
    _loadContentFromFirestore();
  }

  Future<void> _loadContentFromFirestore() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final docSnapshot = await _docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        // Prioritize Delta JSON
        final termsDeltaJson = data['terms_delta'] as List<dynamic>? ?? [];
        if (termsDeltaJson.isNotEmpty) {
          termsQuillController = QuillController(
            document: Document.fromJson(termsDeltaJson),
            selection: const TextSelection.collapsed(offset: 0),
          );
          print('Loaded Terms Delta: ${termsDeltaJson}'); // Debug
        } else {
          // Fallback to HTML
          final termsHtml = data['terms_html'] as String? ?? '';
          if (termsHtml.isNotEmpty) {
            final termsDelta = HtmlToDelta().convert(termsHtml);
            print('Loaded Terms Delta from HTML: ${termsDelta.toJson()}'); // Debug
            termsQuillController = QuillController(
              document: Document.fromDelta(termsDelta),
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
        }

        final privacyDeltaJson = data['privacy_delta'] as List<dynamic>? ?? [];
        if (privacyDeltaJson.isNotEmpty) {
          privacyQuillController = QuillController(
            document: Document.fromJson(privacyDeltaJson),
            selection: const TextSelection.collapsed(offset: 0),
          );
          print('Loaded Privacy Delta: ${privacyDeltaJson}'); // Debug
        } else {
          // Fallback to HTML
          final privacyHtml = data['privacy_html'] as String? ?? '';
          if (privacyHtml.isNotEmpty) {
            final privacyDelta = HtmlToDelta().convert(privacyHtml);
            print('Loaded Privacy Delta from HTML: ${privacyDelta.toJson()}'); // Debug
            privacyQuillController = QuillController(
              document: Document.fromDelta(privacyDelta),
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
        }
      }
      update();
    } catch (e) {
      errorMessage.value = 'Failed to load content: $e';
      Get.snackbar('Error', errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
      isFirstLoad.value = false;
    }
  }

  Future<void> saveContent(String type) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final controller =
      (type == 'terms') ? termsQuillController : privacyQuillController;
      final contentName =
      type == 'terms' ? 'Terms & Conditions' : 'Privacy Policy';
      final deltaList = controller.document.toDelta().toJson();

      print('Saving Delta: $deltaList'); // Debug Delta

      // Store Delta JSON to preserve all attributes (including colors)
      await _docRef.set(
        {'${type}_delta': deltaList},
        SetOptions(merge: true),
      );

      // Attempt HTML conversion for compatibility
      final converter = QuillDeltaToHtmlConverter(
        deltaList,
        ConverterOptions(), // Use default options due to v1.0.5 limitations
      );
      final htmlContent = converter.convert();

      print('Saving HTML: $htmlContent'); // Debug HTML

      await _docRef.set(
        {'${type}_html': htmlContent},
        SetOptions(merge: true),
      );

      Get.snackbar('Success', '$contentName saved successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: pink,
          colorText: Colors.white);
    } catch (e) {
      errorMessage.value = 'Failed to save $type: $e';
      Get.snackbar('Error', errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    termsQuillController.dispose();
    privacyQuillController.dispose();
    super.onClose();
  }
}

class TextStyles {
  TextStyle mack700(double size, Color color) {
    return TextStyle(
        fontFamily: 'Mack',
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: color);
  }

  TextStyle poppins400(double size, Color color) {
    return TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        fontSize: size,
        color: color);
  }

  TextStyle poppins500(double size, Color color) {
    return TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: size,
        color: color);
  }
}