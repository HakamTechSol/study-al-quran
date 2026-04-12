import 'package:flutter/material.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Profile Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  // final phoneController = TextEditingController();

  // Finance Settings
  String selectedCurrency = 'PKR';
  final invoicePrefixController = TextEditingController();
  final nextInvoiceController = TextEditingController();
  double teacherCommission = 70.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromFirebase();
  }

  // 🔥 FIREBASE: Load settings from Firestore
  Future<void> _loadSettingsFromFirebase() async {
    try {
      print('🔄 Loading settings from Firebase...');

      // 🔥 LOAD FROM AUTHENTICATION ONLY
      final user = _auth.currentUser;
      if (user != null) {
        print('👤 User from Auth: ${user.email}');

        // Set default values from Authentication
        setState(() {
          nameController.text = 'Admin User'; // Default name
          emailController.text = user.email ?? 'admin@studyalquran.com';
          // phoneController.text = '+92 300 1234567'; // Default phone
        });

        // 🔥 CHECK IF USER EXISTS IN FIRESTORE, IF NOT CREATE ADMIN USER
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          print('📝 Creating admin user document in Firestore...');
          await _firestore.collection('users').doc(user.uid).set({
            'name': 'Admin User',
            'email': user.email ?? 'admin@studyalquran.com',
            'phone': '+92 300 1234567',
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });
        } else {
          // 🔥 IF USER EXISTS, LOAD THEIR DATA
          final userData = userDoc.data()!;
          setState(() {
            nameController.text = userData['name'] ?? 'Admin User';
            // phoneController.text = userData['phone'] ?? '+92 300 1234567';
          });
        }
      }

      // 🔥 CHECK IF FINANCE SETTINGS EXIST
      final settingsDoc = await _firestore
          .collection('system_settings')
          .doc('admin_settings')
          .get();
      if (settingsDoc.exists) {
        final data = settingsDoc.data()!;
        setState(() {
          selectedCurrency = data['currency'] ?? 'PKR';
          invoicePrefixController.text = data['invoice_prefix'] ?? 'INV-';
          nextInvoiceController.text = (data['next_invoice_number'] ?? 1001)
              .toString();
          teacherCommission = (data['teacher_commission'] ?? 70.0).toDouble();
        });
      }

      setState(() => _isLoading = false);
      print('✅ Settings loaded successfully!');
    } catch (e) {
      print('❌ Error loading settings: $e');
      setState(() => _isLoading = false);

      // 🔥 SHOW DEFAULT UI EVEN IF FIREBASE FAILS
      setState(() {
        nameController.text = 'Admin User';
        emailController.text = 'admin@studyalquran.com';
        // phoneController.text = '+92 300 1234567';
        invoicePrefixController.text = 'INV-';
        nextInvoiceController.text = '1001';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Using default settings',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  // 🔥 FIREBASE: Save all settings to Firestore
  Future<void> _saveSettingsToFirebase() async {
    try {
      setState(() => _isLoading = true);

      // Save admin profile
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': nameController.text.trim(),
          // 'phone': phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Save finance settings
      await _firestore.collection('system_settings').doc('admin_settings').set({
        'currency': selectedCurrency,
        'invoice_prefix': invoicePrefixController.text.trim(),
        'next_invoice_number':
            int.tryParse(nextInvoiceController.text.trim()) ?? 1001,
        'teacher_commission': teacherCommission,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid,
      }, SetOptions(merge: true));

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings saved successfully!',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving settings: $e',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 🔥 FIREBASE: Change Password
  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(cred);

        // Update password
        await user.updatePassword(newPassword);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password changed successfully!',
              style: AppTextStyles.bodySmall,
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error changing password: $e',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 28),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile and Finance Settings Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAdminProfile()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildFinanceSettings()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.text,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your system preferences and configurations',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Settings synced with Firebase',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.text,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminProfile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Admin Profile',
                style: AppTextStyles.heading5.copyWith(
                  color: AppColors.text,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Profile Photo
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.person, color: AppColors.primary, size: 50),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Name
          _buildTextField('Full Name', nameController, Icons.person_outline),
          const SizedBox(height: 16),

          // Email
          _buildTextField(
            'Email Address',
            emailController,
            Icons.email_outlined,
            enabled: false,
          ),
          const SizedBox(height: 16),

          // Phone
          // _buildTextField(
          //   'Phone Number',
          //   // phoneController,
          //   Icons.phone_outlined,
          // ),
          const SizedBox(height: 20),

          // Change Password Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showChangePasswordDialog(),
              icon: Icon(Icons.lock_outline, size: 18),
              label: Text('Change Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Finance Settings',
                style: AppTextStyles.heading5.copyWith(
                  color: AppColors.text,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Currency
          _buildDropdown(
            'Default Currency',
            selectedCurrency,
            ['PKR', 'USD', 'GBP', 'EUR', 'AED'],
            (value) => setState(() => selectedCurrency = value!),
            Icons.currency_exchange,
          ),
          const SizedBox(height: 16),

          // Invoice Prefix
          _buildTextField(
            'Invoice Prefix',
            invoicePrefixController,
            Icons.receipt_outlined,
          ),
          const SizedBox(height: 16),

          // Next Invoice Number
          _buildTextField(
            'Next Invoice Number',
            nextInvoiceController,
            Icons.numbers,
          ),
          const SizedBox(height: 16),

          // Teacher Commission
          Text(
            'Teacher Commission (%)',
            style: AppTextStyles.labelText.copyWith(
              color: AppColors.text,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: teacherCommission,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${teacherCommission.toStringAsFixed(0)}%',
                  activeColor: AppColors.primary,
                  onChanged: (value) =>
                      setState(() => teacherCommission = value),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${teacherCommission.toStringAsFixed(0)}%',
                  style: AppTextStyles.labelText.copyWith(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelText.copyWith(
            color: AppColors.text,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.subtitle, size: 20),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelText.copyWith(
            color: AppColors.text,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.subtitle, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            dropdownColor: AppColors.card,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => _loadSettingsFromFirebase(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.subtitle,
            side: BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('Reload'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveSettingsToFirebase,
          icon: _isLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.check, size: 18),
          label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password', style: AppTextStyles.heading5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Passwords do not match!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              _changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Change Password'),
          ),
        ],
      ),
    );
  }
}