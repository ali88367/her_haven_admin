import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../colors.dart';

class HelpCenter {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phone;
  final String category;
  final List<String> services;
  final String availability;

  HelpCenter({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.category,
    required this.services,
    required this.availability,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'category': category,
      'services': services,
      'availability': availability,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory HelpCenter.fromJson(Map<String, dynamic> json, String documentId) {
    return HelpCenter(
      id: documentId,
      name: json['name'] as String? ?? 'Unnamed Center',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? 'No address',
      phone: json['phone'] as String? ?? 'N/A',
      category: json['category'] as String? ?? 'Uncategorized',
      services: json['services'] != null ? List<String>.from(json['services'] as List<dynamic>) : [],
      availability: json['availability'] as String? ?? 'any',
    );
  }
}

class TextStyles {
  const TextStyles();
  TextStyle mack700(double size, Color color) => TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color, fontFamily: 'Mack');
  TextStyle poppins500(double size, Color color) => TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: color, fontFamily: 'Poppins');
  TextStyle poppins400(double size, Color color) => TextStyle(fontSize: size, fontWeight: FontWeight.w400, color: color, fontFamily: 'Poppins');
  TextStyle poppins300(double size, Color color) => TextStyle(fontSize: size, fontWeight: FontWeight.w300, color: color, fontFamily: 'Poppins');
}

class AdminPanelSinglePage extends StatefulWidget {
  const AdminPanelSinglePage({super.key});

  @override
  State<AdminPanelSinglePage> createState() => _AdminPanelSinglePageState();
}

class _AdminPanelSinglePageState extends State<AdminPanelSinglePage> with TickerProviderStateMixin {
  final TextStyles textStyle = const TextStyles();
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _formScrollController = ScrollController();
  var uuid = const Uuid();
  HelpCenter? _editingCenter;
  late TextEditingController _idController;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCategory;
  final List<String> _availableCategories = [
    'Domestic Abuse', 'Mental Health', 'Sexual Abuse', 'General Support',
  ];
  String _selectedAvailability = 'any';
  final List<Map<String, String>> _availabilityOptions = [
    {'value': 'any', 'label': 'Any Time'},
    {'value': 'now', 'label': 'Open Now'},
    {'value': '247', 'label': '24/7 Services'},
  ];
  Map<String, bool> _selectedServices = {
    'Shelter': false, 'Counseling': false, 'Legal Aid': false, 'Food Bank': false,
  };
  bool _isSubmittingForm = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardScaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _idController = TextEditingController();
    _prepareFormForAdd();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _cardAnimationController.forward();
  }

  void _prepareFormForAdd() {
    setState(() {
      _editingCenter = null;
      _formKey.currentState?.reset();
      _idController.text = uuid.v4();
      _nameController.clear();
      _descriptionController.clear();
      _addressController.clear();
      _phoneController.clear();
      _selectedCategory = null;
      _selectedAvailability = 'any';
      _selectedServices = {
        'Shelter': false, 'Counseling': false, 'Legal Aid': false, 'Food Bank': false,
      };
      if (_formScrollController.hasClients) {
        _formScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _prepareFormForEdit(HelpCenter center) {
    setState(() {
      _editingCenter = center;
      _formKey.currentState?.reset();
      _idController.text = center.id;
      _nameController.text = center.name;
      _descriptionController.text = center.description;
      _addressController.text = center.address;
      _phoneController.text = center.phone;
      _selectedCategory = center.category;
      _selectedAvailability = center.availability;
      _selectedServices = {
        'Shelter': false, 'Counseling': false, 'Legal Aid': false, 'Food Bank': false,
      };
      for (var service in center.services) {
        if (_selectedServices.containsKey(service)) {
          _selectedServices[service] = true;
        }
      }
      _tabController.animateTo(1);
      if (_formScrollController.hasClients) {
        _formScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmittingForm = true; });

    final servicesList = _selectedServices.entries.where((e) => e.value).map((e) => e.key).toList();
    final helpCenterData = HelpCenter(
      id: _idController.text,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      category: _selectedCategory!,
      services: servicesList,
      availability: _selectedAvailability,
    );

    try {
      final ref = FirebaseFirestore.instance.collection('helpCenters').doc(helpCenterData.id);
      if (_editingCenter != null) {
        await ref.set(helpCenterData.toJson(), SetOptions(merge: true)).timeout(Duration(seconds: 10));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${helpCenterData.name} updated successfully!'),
            backgroundColor: pink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        await ref.set(helpCenterData.toJson()).timeout(Duration(seconds: 10));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${helpCenterData.name} added successfully!'),
            backgroundColor: pink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      _prepareFormForAdd();
      _tabController.animateTo(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() { _isSubmittingForm = false; });
    }
  }

  Future<void> _deleteHelpCenter(String docId, String centerName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text('Confirm Delete', style: textStyle.mack700(16, pink)),
        content: Text('Delete "$centerName"? This cannot be undone.', style: textStyle.poppins400(14, black.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: textStyle.poppins500(14, blue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: textStyle.poppins500(14, Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('helpCenters').doc(docId).delete().timeout(Duration(seconds: 10));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$centerName" deleted successfully.'),
            backgroundColor: pink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
          ),
        );
        if (_editingCenter?.id == docId) _prepareFormForAdd();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _formScrollController.dispose();
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Widget _buildFormTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, bool isMultiLine = false, bool enabled = true}) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter $label...',
          labelStyle: textStyle.poppins400(14, pink),
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
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        keyboardType: keyboardType,
        maxLines: isMultiLine ? 3 : 1,
        style: textStyle.poppins500(width < 768 ? 15 : 16, black),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Please enter $label';
          if (label == 'Phone Number' && !RegExp(r'^[\+]?[0-9\s\-\(\)]{7,15}$').hasMatch(value)) return 'Invalid phone number';
          return null;
        },
      ),
    );
  }

  Widget _buildAddEditForm() {
    final width = MediaQuery.of(context).size.width;
    return Center(
      child: ScaleTransition(
        scale: _cardScaleAnimation,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          shadowColor: black.withOpacity(0.15),
          child: Container(
            width: width < 768 ? double.infinity : width < 1024 ? 600 : 700,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pink.withOpacity(0.3), width: 1),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _formScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingCenter == null ? 'Add New Help Center' : 'Edit: ${_editingCenter!.name}',
                          style: textStyle.mack700(width < 768 ? 16 : 18, pink),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
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
                            _editingCenter == null ? Icons.add_rounded : Icons.edit_rounded,
                            color: pink,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormTextField(_nameController, 'Name'),
                    _buildFormTextField(_descriptionController, 'Description', isMultiLine: true),
                    _buildFormTextField(_addressController, 'Address'),
                    _buildFormTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          hintText: 'Select Category',
                          labelStyle: textStyle.poppins400(14, pink),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        value: _selectedCategory,
                        isExpanded: true,
                        items: _availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: textStyle.poppins500(14, black)))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        validator: (val) => val == null ? 'Select a category' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Services Offered:', style: textStyle.poppins500(width < 768 ? 15 : 16, black)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedServices.keys.map((key) => ChoiceChip(
                        label: Text(key, style: textStyle.poppins400(14, _selectedServices[key]! ? Colors.white : black)),
                        selected: _selectedServices[key]!,
                        onSelected: (val) => setState(() => _selectedServices[key] = val),
                        selectedColor: pink,
                        backgroundColor: primaryColor.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: pink.withOpacity(0.3)),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text('Availability:', style: textStyle.poppins500(width < 768 ? 15 : 16, black)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availabilityOptions.map((opt) => ChoiceChip(
                        label: Text(opt['label']!, style: textStyle.poppins400(14, _selectedAvailability == opt['value'] ? Colors.white : black)),
                        selected: _selectedAvailability == opt['value'],
                        onSelected: (val) => setState(() => _selectedAvailability = opt['value']!),
                        selectedColor: pink,
                        backgroundColor: primaryColor.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: pink.withOpacity(0.3)),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: _isSubmittingForm
                          ? Column(
                        children: [
                          CircularProgressIndicator(color: pink, strokeWidth: 3),
                          const SizedBox(height: 6),
                          Text('Submitting...', style: textStyle.poppins400(14, black.withOpacity(0.7))),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_editingCenter != null)
                            OutlinedButton(
                              onPressed: _prepareFormForAdd,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: Text('Cancel Edit', style: textStyle.poppins500(14, blue)),
                            ),
                          if (_editingCenter != null) const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _editingCenter == null ? Icons.add_rounded : Icons.save_rounded,
                                color: pink,
                                size: 20,
                              ),
                            ),
                            label: Text(
                              _editingCenter == null ? 'Add Center' : 'Update Center',
                              style: textStyle.poppins500(width < 768 ? 14 : 15, Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pink,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                              shadowColor: black.withOpacity(0.2),
                            ),
                            onPressed: _submitForm,
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
    );
  }

  Widget _buildManageCentersList() {
    final width = MediaQuery.of(context).size.width;
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: width < 768 ? double.infinity : width < 1024 ? 600 : 700,
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('helpCenters').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: pink, strokeWidth: 3));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: textStyle.poppins400(15, text1),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No help centers found. Add one!',
                  style: textStyle.poppins400(15, text1),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: width < 768 ? 16 : 24, vertical: 8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final center = HelpCenter.fromJson(docs[index].data()! as Map<String, dynamic>, docs[index].id);
                return ScaleTransition(
                  scale: _cardScaleAnimation,
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _cardAnimationController,
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
                          onTap: () => _prepareFormForEdit(center),
                          hoverColor: purple.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        center.name,
                                        style: textStyle.mack700(width < 768 ? 16 : 18, pink),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: pink.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.local_hospital_rounded,
                                        color: pink,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${center.category} - ${center.address}',
                                  style: textStyle.poppins400(width < 768 ? 14 : 15, black.withOpacity(0.8)),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  center.description,
                                  style: textStyle.poppins400(width < 768 ? 14 : 15, black.withOpacity(0.8)),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: center.services.map((service) => Chip(
                                    label: Text(service, style: textStyle.poppins400(13, Colors.white)),
                                    backgroundColor: blue,
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: blue.withOpacity(0.3)),
                                    ),
                                  )).toList(),
                                ),
                                const SizedBox(height: 12),
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
                                        onPressed: () => _prepareFormForEdit(center),
                                        tooltip: 'Edit Center',
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
                                        onPressed: () => _deleteHelpCenter(center.id, center.name),
                                        tooltip: 'Delete Center',
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
          child: DefaultTabController(
            length: 2,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width < 768 ? 16 : 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Help Centers',
                          style: textStyle.mack700(width < 768 ? 22 : 26, text1),
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
                            Icons.local_hospital_rounded,
                            color: pink,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: pink,
                    labelColor: pink,
                    unselectedLabelColor: text1.withOpacity(0.6),
                    labelStyle: textStyle.poppins500(14, pink),
                    unselectedLabelStyle: textStyle.poppins400(14, text1.withOpacity(0.6)),
                    padding: EdgeInsets.symmetric(horizontal: width < 768 ? 16 : 24),
                    tabs: const [
                      Tab(text: 'Manage Centers', icon: Icon(Icons.list_rounded)),
                      Tab(text: 'Add/Edit Center', icon: Icon(Icons.edit_rounded)),
                    ],
                    onTap: (index) {
                      if (index == 1 && _editingCenter == null) {
                        _prepareFormForAdd();
                      }
                    },
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildManageCentersList(),
                        _buildAddEditForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _prepareFormForAdd();
          _tabController.animateTo(1);
        },
        backgroundColor: pink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.add_rounded, size: 28),
        tooltip: 'Add New Help Center',
      ),
    );
  }
}