// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
// import 'package:get/get.dart';
// import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
//
// import '../colors.dart'; // Ensure this file defines `primaryColor` and `pink`
//
// class UploadTermsPrivacyController extends GetxController {
//   final _docRef =
//   FirebaseFirestore.instance.collection('legal_documents').doc('main');
//
//   final isLoading = true.obs;
//   final isFirstLoad = true.obs;
//   final errorMessage = ''.obs;
//
//   late QuillController termsQuillController;
//   late QuillController privacyQuillController;
//
//   @override
//   void onInit() {
//     super.onInit();
//     termsQuillController = QuillController.basic();
//     privacyQuillController = QuillController.basic();
//     _loadContentFromFirestore();
//   }
//
//   Future<void> _loadContentFromFirestore() async {
//     try {
//       isLoading.value = true;
//       errorMessage.value = '';
//
//       final docSnapshot = await _docRef.get();
//
//       if (docSnapshot.exists) {
//         final data = docSnapshot.data() as Map<String, dynamic>;
//
//         // Try loading Delta JSON first (if available)
//         final termsDeltaJson = data['terms_delta'] as List<dynamic>? ?? [];
//         if (termsDeltaJson.isNotEmpty) {
//           termsQuillController = QuillController(
//             document: Document.fromJson(termsDeltaJson),
//             selection: const TextSelection.collapsed(offset: 0), // Fixed
//           );
//           print('Loaded Terms Delta: ${termsDeltaJson}'); // Debug
//         } else {
//           // Fallback to HTML
//           final termsHtml = data['terms_html'] as String? ?? '';
//           if (termsHtml.isNotEmpty) {
//             final termsDelta = HtmlToDelta().convert(termsHtml);
//             print('Loaded Terms Delta from HTML: ${termsDelta.toJson()}'); // Debug
//             termsQuillController = QuillController(
//               document: Document.fromDelta(termsDelta),
//               selection: const TextSelection.collapsed(offset: 0), // Fixed
//             );
//           }
//         }
//
//         final privacyDeltaJson = data['privacy_delta'] as List<dynamic>? ?? [];
//         if (privacyDeltaJson.isNotEmpty) {
//           privacyQuillController = QuillController(
//             document: Document.fromJson(privacyDeltaJson),
//             selection: const TextSelection.collapsed(offset: 0), // Fixed
//           );
//           print('Loaded Privacy Delta: ${privacyDeltaJson}'); // Debug
//         } else {
//           // Fallback to HTML
//           final privacyHtml = data['privacy_html'] as String? ?? '';
//           if (privacyHtml.isNotEmpty) {
//             final privacyDelta = HtmlToDelta().convert(privacyHtml);
//             print('Loaded Privacy Delta from HTML: ${privacyDelta.toJson()}'); // Debug
//             privacyQuillController = QuillController(
//               document: Document.fromDelta(privacyDelta),
//               selection: const TextSelection.collapsed(offset: 0), // Fixed
//             );
//           }
//         }
//       }
//       update();
//     } catch (e) {
//       errorMessage.value = 'Failed to load content: $e';
//       Get.snackbar('Error', errorMessage.value,
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: Colors.red,
//           colorText: Colors.white);
//     } finally {
//       isLoading.value = false;
//       isFirstLoad.value = false;
//     }
//   }
//
//   Future<void> saveContent(String type) async {
//     try {
//       isLoading.value = true;
//       errorMessage.value = '';
//
//       final controller =
//       (type == 'terms') ? termsQuillController : privacyQuillController;
//       final contentName =
//       type == 'terms' ? 'Terms & Conditions' : 'Privacy Policy';
//       final deltaList = controller.document.toDelta().toJson();
//
//       print('Saving Delta: $deltaList'); // Debug Delta
//
//       // Store Delta JSON to preserve all attributes (including colors)
//       await _docRef.set(
//         {'${type}_delta': deltaList},
//         SetOptions(merge: true),
//       );
//
//       // Attempt HTML conversion for compatibility
//       final converter = QuillDeltaToHtmlConverter(
//         deltaList,
//         ConverterOptions(
//           // Use default options, as inlineStyles is not supported in v1.0.5
//           // Custom handling can be added if a newer version is used
//         ),
//       );
//       final htmlContent = converter.convert();
//
//       print('Saving HTML: $htmlContent'); // Debug HTML
//
//       await _docRef.set(
//         {'${type}_html': htmlContent},
//         SetOptions(merge: true),
//       );
//
//       Get.snackbar('Success', '$contentName saved successfully.',
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: pink,
//           colorText: Colors.white);
//     } catch (e) {
//       errorMessage.value = 'Failed to save $type: $e';
//       Get.snackbar('Error', errorMessage.value,
//           snackPosition: SnackPosition.TOP,
//           backgroundColor: Colors.red,
//           colorText: Colors.white);
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   @override
//   void onClose() {
//     termsQuillController.dispose();
//     privacyQuillController.dispose();
//     super.onClose();
//   }
// }
//
