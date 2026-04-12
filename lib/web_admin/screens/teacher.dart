import 'package:flutter/material.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class TeachersManagementScreen extends StatefulWidget {
  const TeachersManagementScreen({super.key});

  @override
  State<TeachersManagementScreen> createState() =>
      _TeachersManagementScreenState();
}

class _TeachersManagementScreenState extends State<TeachersManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 STREAM: Real-time teachers data from Firestore
  Stream<List<Teacher>> getTeachersStream() {
    return _firestore.collection('teachers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Teacher.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  List<Teacher> filterTeachers(List<Teacher> teachers) {
    if (_searchQuery.isEmpty) return teachers;
    return teachers.where((teacher) {
      return teacher.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          teacher.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          teacher.region.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showAddEditDialog({Teacher? teacher}) {
    showDialog(
      context: context,
      builder: (context) => AddEditTeacherDialog(teacher: teacher),
    );
  }

  // 🔥 DELETE TEACHER FUNCTION
  Future<void> _deleteTeacher(String teacherId, String email) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Teacher', style: AppTextStyles.alertTitle),
        content: Text(
          'Are you sure you want to delete this teacher?',
          style: AppTextStyles.alertBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.buttonSecondary),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Step 1: Delete from 'teachers' collection
                await _firestore.collection('teachers').doc(teacherId).delete();

                // Step 2: Delete from 'users' collection (by teacherId = uid)
                await _firestore.collection('users').doc(teacherId).delete();

                // Note: Firebase Auth user deletion requires re-authentication
                // So admin cannot directly delete Auth user from here
                // You need Cloud Function or ask teacher to re-login

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Teacher deleted successfully',
                      style: AppTextStyles.bodySmall,
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e', style: AppTextStyles.bodySmall),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Teachers Management', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: AppColors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teachers List', style: AppTextStyles.heading1),
                    const SizedBox(height: 8),
                    Text(
                      'Manage all teachers from here',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add Teacher',
                    style: AppTextStyles.buttonPrimary,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: AppTextStyles.inputValue,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or region...',
                  hintStyle: AppTextStyles.inputHint,
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.subtitle),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.subtitle),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔥 TEACHERS TABLE WITH STREAM
            Expanded(
              child: StreamBuilder<List<Teacher>>(
                stream: getTeachersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: AppTextStyles.bodySmall,
                      ),
                    );
                  }

                  final teachers = snapshot.data ?? [];
                  final filteredTeachers = filterTeachers(teachers);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Name',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Email',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Region',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Per Class (USD)',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Wallet (USD)',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Status',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Actions',
                                  style: AppTextStyles.tableHeader,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Table Body
                        Expanded(
                          child: filteredTeachers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: AppColors.subtitle,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No teachers found',
                                        style: AppTextStyles.heading4,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredTeachers.length,
                                  itemBuilder: (context, index) {
                                    final teacher = filteredTeachers[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Name
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        AppColors.primaryLight,
                                                    child: Text(
                                                      teacher.name[0]
                                                          .toUpperCase(),
                                                      style: AppTextStyles
                                                          .buttonPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    teacher.name,
                                                    style:
                                                        AppTextStyles.tableCell,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                teacher.email,
                                                style: AppTextStyles.tableCell,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  teacher.region,
                                                  style: AppTextStyles.chipText
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'USD ${teacher.rate.toStringAsFixed(0)}',
                                                style: AppTextStyles.tableCell
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'USD ${teacher.wallet.toStringAsFixed(0)}',
                                                style: AppTextStyles.tableCell
                                                    .copyWith(
                                                      color: AppColors.success,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: teacher.isActive
                                                      ? AppColors.success
                                                            .withOpacity(0.1)
                                                      : AppColors.error
                                                            .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  teacher.isActive
                                                      ? 'Active'
                                                      : 'Inactive',
                                                  style: AppTextStyles.badge
                                                      .copyWith(
                                                        color: teacher.isActive
                                                            ? AppColors.success
                                                            : AppColors.error,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      color: AppColors.primary,
                                                    ),
                                                    onPressed: () =>
                                                        _showAddEditDialog(
                                                          teacher: teacher,
                                                        ),
                                                    tooltip: 'Edit',
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: AppColors.error,
                                                    ),
                                                    onPressed: () =>
                                                        _deleteTeacher(
                                                          teacher.id,
                                                          teacher.email,
                                                        ),
                                                    tooltip: 'Delete',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 ADD/EDIT TEACHER DIALOG WITH FIREBASE
class AddEditTeacherDialog extends StatefulWidget {
  final Teacher? teacher;

  const AddEditTeacherDialog({super.key, this.teacher});

  @override
  State<AddEditTeacherDialog> createState() => _AddEditTeacherDialogState();
}

class _AddEditTeacherDialogState extends State<AddEditTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _regionController;
  late TextEditingController _zoomLinkController;
  late TextEditingController _rateController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _subjectsController;
  bool _isActive = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher?.name ?? '');
    _emailController = TextEditingController(text: widget.teacher?.email ?? '');
    _regionController = TextEditingController(
      text: widget.teacher?.region ?? '',
    );
    _zoomLinkController = TextEditingController(
      text: widget.teacher?.zoomLink ?? '',
    );
    _rateController = TextEditingController(
      text: widget.teacher?.rate.toString() ?? '',
    );
    _phoneController = TextEditingController(text: widget.teacher?.phone ?? '');
    _subjectsController = TextEditingController(
      text: widget.teacher?.subjects ?? '',
    );
    _passwordController = TextEditingController();
    _isActive = widget.teacher?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    _zoomLinkController.dispose();
    _rateController.dispose();
    _phoneController.dispose();
    _subjectsController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    setState(() {
      _passwordController.text = _generateRandomPassword();
    });
  }

  // 🔥 GENERATE RANDOM PASSWORD FUNCTION
  String _generateRandomPassword({int length = 12}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // 🔥 ADD TEACHER FUNCTION WITH PASSWORD RESET EMAIL
  Future<void> _addTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Generate a random temporary password
      String tempPassword = _passwordController.text.isNotEmpty
          ? _passwordController.text.trim()
          : _generateRandomPassword();

      // Step 2: Create Firebase Auth account with temporary password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: tempPassword,
          );

      String uid = userCredential.user!.uid;

      // Step 3: Send password reset email to teacher
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

      // Step 4: Add to 'users' collection
      await _firestore.collection('users').doc(uid).set({
        'userId': uid,
        'role': 'teacher',
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': _isActive ? 'active' : 'inactive',
        'hasResetPassword': false,
      });

      // Step 5: Add to 'teachers' collection
      await _firestore.collection('teachers').doc(uid).set({
        'teacherId': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'region': _regionController.text.trim(),
        'zoomLink': _zoomLinkController.text.trim(),
        'rate': double.parse(_rateController.text.trim()),
        'subjects': _subjectsController.text.trim(),
        'walletBalance': 0.0,
        'isActive': _isActive,
        'hasResetPassword': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Step 6: Show success dialog
      if (!mounted) return;
      Navigator.pop(context);
      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to add teacher';

      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      } else if (e.code == 'weak-password') {
        errorMessage =
            'Password is too weak. Please use at least 6 characters.';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Email/password accounts are not enabled.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔥 SHOW SUCCESS DIALOG
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text('Teacher Added Successfully!', style: AppTextStyles.heading5),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teacher has been registered successfully.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Password Reset Email Sent',
                        style: AppTextStyles.labelText.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A password reset link has been sent to:',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _emailController.text.trim(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teacher will receive an email to set their password.',
                    style: AppTextStyles.captionText.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'They can click the link in the email to create their password.',
                    style: AppTextStyles.captionText.copyWith(
                      color: AppColors.subtitle,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('OK', style: AppTextStyles.buttonPrimary),
          ),
        ],
      ),
    );
  }

  // 🔥 UPDATE TEACHER FUNCTION
  Future<void> _updateTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String teacherId = widget.teacher!.id;

      // Update 'users' collection
      await _firestore.collection('users').doc(teacherId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'status': _isActive ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update 'teachers' collection
      await _firestore.collection('teachers').doc(teacherId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'region': _regionController.text.trim(),
        'zoomLink': _zoomLinkController.text.trim(),
        'rate': double.parse(_rateController.text.trim()),
        'subjects': _subjectsController.text.trim(),
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Teacher updated successfully!',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.teacher != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Teacher' : 'Add New Teacher',
                      style: AppTextStyles.heading2,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildTextField('Name', _nameController, 'Enter teacher name'),
                const SizedBox(height: 20),
                _buildTextField(
                  'Email',
                  _emailController,
                  'Enter email address',
                  enabled: !isEdit,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Phone',
                  _phoneController,
                  'Enter phone number',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Region',
                  _regionController,
                  'Enter region (e.g., Karachi)',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Subjects',
                  _subjectsController,
                  'e.g., Quran, Arabic',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Zoom Link',
                  _zoomLinkController,
                  'https://zoom.us/j/...',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Per Class Rate (USD)',
                  _rateController,
                  'Enter per class rate',
                  isNumber: true,
                ),
                const SizedBox(height: 20),

                if (!isEdit) ...[
                  Text('Password', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: AppTextStyles.inputValue,
                          decoration: InputDecoration(
                            hintText: 'Leave blank to auto-generate',
                            hintStyle: AppTextStyles.inputHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.subtitle,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _generatePassword,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          'Auto Gen',
                          style: AppTextStyles.buttonSmall,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Teacher will receive a password reset email to set their password',
                            style: AppTextStyles.captionText.copyWith(
                              color: AppColors.info,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Status Toggle
                Row(
                  children: [
                    Text('Status:', style: AppTextStyles.inputLabel),
                    const SizedBox(width: 16),
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      activeThumbColor: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isActive ? 'Active' : 'Inactive',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isActive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.buttonSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (isEdit ? _updateTeacher : _addTeacher),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Teacher' : 'Add Teacher',
                              style: AppTextStyles.buttonPrimary,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: AppTextStyles.inputValue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label is required';
            }
            if (isNumber && double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            if (label == 'Email' && !value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }
}

// 🔥 TEACHER MODEL WITH FIRESTORE
class Teacher {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String region;
  final String subjects;
  final double rate;
  final double wallet;
  final String zoomLink;
  final bool isActive;
  final bool hasResetPassword;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.region,
    required this.subjects,
    required this.rate,
    required this.wallet,
    required this.zoomLink,
    required this.isActive,
    this.hasResetPassword = false,
  });

  factory Teacher.fromFirestore(Map<String, dynamic> data, String id) {
    String subjectsStr = '';
    if (data['subjects'] is List) {
      subjectsStr = (data['subjects'] as List).join(', ');
    } else if (data['subjects'] is String) {
      subjectsStr = data['subjects'];
    }

    return Teacher(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      region: data['region'] ?? '',
      subjects: subjectsStr,
      rate: (data['rate'] ?? 0).toDouble(),
      wallet: (data['walletBalance'] ?? 0).toDouble(),
      zoomLink: data['zoomLink'] ?? '',
      isActive: data['isActive'] ?? true,
      hasResetPassword: data['hasResetPassword'] ?? false,
    );
  }
}
