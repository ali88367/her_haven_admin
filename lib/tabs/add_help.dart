import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Needed for main
import '../colors.dart';
import '../firebase_options.dart'; // Needed for main

// --- START: SHARED DEFINITIONS (Model, Constants) ---

// Data Model for Help Center
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
      'createdAt': FieldValue.serverTimestamp(), // Add a timestamp
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

// Placeholder Constants
const Color blue = Color(0xFF2196F3); // Not used in this single page, but kept for model context
const Color purple = Color(0xFF9C27B0); // Not used
const Color black = Colors.black;
const Color primaryColor = Color(0xFFFCE4EC);
// final Color yellowGreen = Color.fromRGBO(199, 201, 116, 1); // Not used
// final Color generalSupportColor = Color.fromRGBO(193, 121, 76, 1); // Not used

class TextStyles {
  const TextStyles();
  TextStyle mack700(double size, Color color) => TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color, fontFamily: 'Mack');
  TextStyle poppins500(double size, Color color) => TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: color, fontFamily: 'Poppins');
  TextStyle poppins400(double size, Color color) => TextStyle(fontSize: size, fontWeight: FontWeight.w400, color: color, fontFamily: 'Poppins');
  TextStyle poppins300(double size, Color color) => TextStyle(fontSize: size, fontWeight: FontWeight.w300, color: color, fontFamily: 'Poppins');
}
// --- END: SHARED DEFINITIONS ---




// --- START: ADMIN PANEL SINGLE PAGE WIDGET ---
class AdminPanelSinglePage extends StatefulWidget {
  const AdminPanelSinglePage({super.key});

  @override
  State<AdminPanelSinglePage> createState() => _AdminPanelSinglePageState();
}

class _AdminPanelSinglePageState extends State<AdminPanelSinglePage> with SingleTickerProviderStateMixin {
  final TextStyles textStyle = const TextStyles();
  late TabController _tabController;

  // State for the Add/Edit Form
  final _formKey = GlobalKey<FormState>();
  final _formScrollController = ScrollController(); // To scroll form to top
  var uuid = const Uuid();

  HelpCenter? _editingCenter; // If not null, we are editing

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _idController = TextEditingController(); // Initialized when form is prepared
    _prepareFormForAdd(); // Initialize form for "Add" mode
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
      _formKey.currentState?.reset(); // Reset validation state
      _idController.text = center.id;
      _nameController.text = center.name;
      _descriptionController.text = center.description;
      _addressController.text = center.address;
      _phoneController.text = center.phone;
      _selectedCategory = center.category;
      _selectedAvailability = center.availability;
      _selectedServices = { // Reset and then set based on center's services
        'Shelter': false, 'Counseling': false, 'Legal Aid': false, 'Food Bank': false,
      };
      for (var service in center.services) {
        if (_selectedServices.containsKey(service)) {
          _selectedServices[service] = true;
        }
      }
      _tabController.animateTo(1); // Switch to Add/Edit tab
      if (_formScrollController.hasClients) {
        _formScrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmittingForm = true; });

    final servicesList = _selectedServices.entries.where((e) => e.value).map((e) => e.key).toList();    final helpCenterData = HelpCenter(
      id: _idController.text,
      name: _nameController.text,
      description: _descriptionController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      category: _selectedCategory!,
      services: servicesList,
      availability: _selectedAvailability,
    );

    try {
      final ref = FirebaseFirestore.instance.collection('helpCenters').doc(helpCenterData.id);
      if (_editingCenter != null) { // Editing
        await ref.update(helpCenterData.toJson());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${helpCenterData.name} updated!')));
      } else { // Adding
        await ref.set(helpCenterData.toJson());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${helpCenterData.name} added!')));
      }
      _prepareFormForAdd(); // Reset form to "Add" mode
      _tabController.animateTo(0); // Switch back to Manage tab
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() { _isSubmittingForm = false; });
    }
  }

  Future<void> _deleteHelpCenter(String docId, String centerName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Delete', style: textStyle.mack700(18, black)),
        content: Text('Delete "$centerName"? This cannot be undone.', style: textStyle.poppins400(14, black)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: textStyle.poppins500(14, pink))),
          TextButton(
              style: TextButton.styleFrom(backgroundColor: pink),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Delete', style: textStyle.poppins500(14, Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('helpCenters').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$centerName" deleted.')));
        if (_editingCenter?.id == docId) _prepareFormForAdd(); // If currently editing the deleted item, reset form
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
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
    super.dispose();
  }

  // --- UI WIDGETS ---
  Widget _buildFormTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, bool isMultiLine = false, bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          fillColor: Colors.white,
          filled: true,
        ),
        keyboardType: keyboardType,
        maxLines: isMultiLine ? null : 1,
        minLines: isMultiLine ? 3 : 1,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (label.contains('Distance') && double.tryParse(value) == null) return 'Invalid number';
          return null;
        },
      ),
    );
  }

  Widget _buildAddEditForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _formScrollController,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_editingCenter == null ? 'Add New Help Center' : 'Edit: ${_editingCenter!.name}', style: textStyle.mack700(18, black)),
            SizedBox(height: 10),
            _buildFormTextField(_idController, 'ID', enabled: false),
            _buildFormTextField(_nameController, 'Name'),
            _buildFormTextField(_descriptionController, 'Description', isMultiLine: true),
            _buildFormTextField(_addressController, 'Address'),
            _buildFormTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone),


            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), fillColor:Colors.white, filled: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                value: _selectedCategory,
                hint: const Text('Select Category'),
                isExpanded: true,
                items: _availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) => val == null ? 'Select a category' : null,
              ),
            ),

            Text('Services Offered:', style: textStyle.poppins500(16, black)),
            ..._selectedServices.keys.map((key) => CheckboxListTile(
              title: Text(key, style: textStyle.poppins400(14, black)),
              value: _selectedServices[key],
              onChanged: (val) => setState(() => _selectedServices[key] = val!),
              controlAffinity: ListTileControlAffinity.leading, dense: true, contentPadding: EdgeInsets.zero, activeColor: pink,
            )).toList(),
            SizedBox(height: 10),

            Text('Availability:', style: textStyle.poppins500(16, black)),
            ..._availabilityOptions.map((opt) => RadioListTile<String>(
              title: Text(opt['label']!, style: textStyle.poppins400(14, black)),
              value: opt['value']!,
              groupValue: _selectedAvailability,
              onChanged: (val) => setState(() => _selectedAvailability = val!),
              dense: true, contentPadding: EdgeInsets.zero, activeColor: pink,
            )).toList(),
            SizedBox(height: 20),

            Center(
              child: _isSubmittingForm
                  ? CircularProgressIndicator(color: pink)
                  : ElevatedButton.icon(
                icon: Icon(_editingCenter == null ? Icons.add_circle_outline : Icons.save_outlined),
                label: Text(_editingCenter == null ? 'Add Center' : 'Update Center'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(backgroundColor: pink, foregroundColor:Colors.white, padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
              ),
            ),
            if (_editingCenter != null)
              Padding(
                padding: EdgeInsets.only(top:10),
                child: Center(
                  child: OutlinedButton(
                    child: Text('Cancel Edit & Add New', style: textStyle.poppins400(14, pink)),
                    onPressed: _prepareFormForAdd,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: pink)),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildManageCentersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('helpCenters').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return  Center(child: CircularProgressIndicator(color: pink));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No help centers found. Add one!', style: textStyle.poppins400(16, Colors.grey.shade700)));

        return ListView(
          padding: EdgeInsets.all(8),
          children: snapshot.data!.docs.map((doc) {
            final center = HelpCenter.fromJson(doc.data()! as Map<String, dynamic>, doc.id);
            return Card(
              margin: EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              child: ListTile(
                title: Text(center.name, style: textStyle.poppins500(16, black)),
                subtitle: Text("${center.category} - ${center.address}", maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle.poppins300(12, Colors.grey.shade700)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700, size: 20), tooltip: 'Edit', onPressed: () => _prepareFormForEdit(center)),
                    IconButton(icon: Icon(Icons.delete_outline, color: pink, size: 20), tooltip: 'Delete', onPressed: () => _deleteHelpCenter(center.id, center.name)),
                  ],
                ),
                onTap: () => _prepareFormForEdit(center), // Also allow tap on list item to edit
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController( // Can remove this if using _tabController explicitly for TabBarView
      length: 2,
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          title: Text('Add Help Centers', style: textStyle.mack700(22, Colors.white)),
          backgroundColor: pink,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelStyle: textStyle.poppins500(14, Colors.white),
            unselectedLabelStyle: textStyle.poppins400(14, Colors.white),
            tabs: const [
              Tab(text: 'Manage Centers', icon: Icon(Icons.list_alt_outlined)),
              Tab(text: 'Add/Edit Center', icon: Icon(Icons.edit_note_outlined)),
            ],
            onTap: (index) {
              if (index == 1 && _editingCenter == null) { // Tapped Add/Edit but not editing
                _prepareFormForAdd(); // Ensure form is in "Add" mode
              }
            },
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildManageCentersList(),
            _buildAddEditForm(),
          ],
        ),
        floatingActionButton: _tabController.index == 0 // Show FAB only on Manage tab
            ? FloatingActionButton(
          onPressed: () {
            _prepareFormForAdd();
            _tabController.animateTo(1);
          },
          backgroundColor: pink,
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Add New Help Center',
        )
            : null,
      ),
    );
  }
}
// --- END: ADMIN PANEL SINGLE PAGE WIDGET ---