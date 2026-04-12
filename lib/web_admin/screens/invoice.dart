import 'package:flutter/material.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Main Invoices Management Screen
class InvoicesManagementScreen extends StatefulWidget {
  final String? studentId; // 🔥 CHANGE: Student class ko avoid karne ke liye studentId use karo
  final String? studentName; // 🔥 OPTIONAL: Student name bhi pass kar sakte hain

  const InvoicesManagementScreen({super.key, this.studentId, this.studentName});
  
  @override
  State<InvoicesManagementScreen> createState() =>
      _InvoicesManagementScreenState();
}

class _InvoicesManagementScreenState extends State<InvoicesManagementScreen> {
  bool showCreateForm = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String searchQuery = '';
  String filterStatus = 'All';

  // 🔥 STREAM: Real-time invoices data
  Stream<List<Invoice>> getInvoicesStream() {
    return _firestore
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Invoice> invoices = [];

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data();

            // Get student name
            String studentName = 'Unknown Student';
            if (data['studentId'] != null && data['studentId'].isNotEmpty) {
              try {
                var studentDoc = await _firestore
                    .collection('students')
                    .doc(data['studentId'])
                    .get();
                if (studentDoc.exists) {
                  studentName = studentDoc.data()?['name'] ?? 'Unknown Student';
                }
              } catch (e) {
                print('Error fetching student: $e');
              }
            }

            invoices.add(Invoice.fromFirestore(data, doc.id, studentName));
          }

          return invoices;
        });
  }

  // 🔥 GET STUDENTS LIST FOR DROPDOWN
  Future<List<StudentDropdown>> getStudentsList() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('students').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return StudentDropdown(
          id: doc.id,
          name: data['name'] ?? 'Unknown Student',
        );
      }).toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  // 🔥 MARK INVOICE AS PAID
  Future<void> _markAsPaid(String invoiceId) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'status': 'Paid',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice marked as paid',
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
    }
  }

  // 🔥 DELETE INVOICE
  Future<void> _deleteInvoice(String invoiceId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Invoice', style: AppTextStyles.alertTitle),
        content: Text(
          'Are you sure you want to delete this invoice?',
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
                await _firestore.collection('invoices').doc(invoiceId).delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invoice deleted successfully',
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

  void _showAddEditDialog({Invoice? invoice}) async {
    List<StudentDropdown> students = await getStudentsList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) =>
          AddEditInvoiceDialog(invoice: invoice, availableStudents: students),
    );
  }

  List<Invoice> filterInvoices(List<Invoice> invoices) {
    if (searchQuery.isEmpty && filterStatus == 'All') {
      return invoices;
    }

    return invoices.where((invoice) {
      final matchesSearch =
          searchQuery.isEmpty ||
          invoice.studentName.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          invoice.id.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesFilter =
          filterStatus == 'All' || invoice.status == filterStatus;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return showCreateForm
        ? CreateInvoiceScreen(
            onCancel: () => setState(() => showCreateForm = false),
            onSubmit: () => setState(() => showCreateForm = false),
          )
        : _buildInvoicesListScreen();
  }

  Widget _buildInvoicesListScreen() {
    return Scaffold( // 🔥 ADDED SCAFFOLD - YEH ERROR FIX KAREGA
      body: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoices Management',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.text,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage student invoices and payments',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.subtitle,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔥 STATS CARDS WITH STREAM
            StreamBuilder<List<Invoice>>(
              stream: getInvoicesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final invoices = snapshot.data ?? [];

                final totalInvoices = invoices.length;
                final paidInvoices = invoices
                    .where((i) => i.status == 'Paid')
                    .length;
                final unpaidInvoices = invoices
                    .where((i) => i.status == 'Unpaid')
                    .length;
                final totalAmount = invoices.fold<int>(
                  0,
                  (sum, i) => sum + i.amount,
                );

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Invoices',
                        '$totalInvoices',
                        Icons.receipt_long_outlined,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Paid',
                        '$paidInvoices',
                        Icons.check_circle_outline,
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Unpaid',
                        '$unpaidInvoices',
                        Icons.pending_outlined,
                        const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Amount',
                        'Usd ${NumberFormat('#,##0').format(totalAmount)}',
                        Icons.account_balance_wallet_outlined,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Search and Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by student name or invoice ID...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.subtitle,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search, color: AppColors.subtitle),
                      filled: true,
                      fillColor: AppColors.card,
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
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: filterStatus,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.text),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text,
                      fontSize: 14,
                    ),
                    items: ['All', 'Paid', 'Unpaid'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => filterStatus = value!);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔥 INVOICES TABLE WITH STREAM
            Expanded(
              child: StreamBuilder<List<Invoice>>(
                stream: getInvoicesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  final invoices = snapshot.data ?? [];
                  final filteredInvoices = filterInvoices(invoices);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Invoice ID',
                                  style: AppTextStyles.labelText.copyWith(
                                    color: AppColors.subtitle,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Student',
                                  style: AppTextStyles.labelText.copyWith(
                                    color: AppColors.subtitle,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Amount',
                                  style: AppTextStyles.labelText.copyWith(
                                    color: AppColors.subtitle,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Due Date',
                                  style: AppTextStyles.labelText.copyWith(
                                    color: AppColors.subtitle,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: AppTextStyles.labelText.copyWith(
                                    color: AppColors.subtitle,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Actions',
                                  style: AppTextStyles.labelText.copyWith(
                                    color: AppColors.subtitle,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Table Body
                        Expanded(
                          child: filteredInvoices.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: AppColors.subtitle,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No invoices found',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.subtitle,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredInvoices.length,
                                  itemBuilder: (context, index) {
                                    final invoice = filteredInvoices[index];
                                    return _buildInvoiceRow(invoice);
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.subtitle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(Invoice invoice) {
    final isPaid = invoice.status == 'Paid';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              invoice.id.substring(0, 8),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.studentName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.package,
                  style: AppTextStyles.captionText.copyWith(
                    color: AppColors.subtitle,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Usd ${NumberFormat('#,##0').format(invoice.amount)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              invoice.dueDate,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPaid
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                invoice.status,
                style: AppTextStyles.labelText.copyWith(
                  color: isPaid
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isPaid)
                  IconButton(
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                    onPressed: () => _markAsPaid(invoice.id),
                    tooltip: 'Mark as Paid',
                  ),
                IconButton(
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () => _showInvoiceDetails(invoice),
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: const Color(0xFFEF4444),
                    size: 20,
                  ),
                  onPressed: () => _deleteInvoice(invoice.id),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice Details',
                    style: AppTextStyles.heading4.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.subtitle),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                Icons.tag,
                'Invoice ID',
                invoice.id.substring(0, 8),
              ),
              _buildDetailRow(Icons.person, 'Student', invoice.studentName),
              _buildDetailRow(Icons.receipt_long, 'Package', invoice.package),
              _buildDetailRow(
                Icons.currency_rupee,
                'Amount',
                'Usd ${NumberFormat('#,##0').format(invoice.amount)}',
              ),
              _buildDetailRow(
                Icons.calendar_today,
                'Due Date',
                invoice.dueDate,
              ),
              _buildDetailRow(Icons.info_outline, 'Status', invoice.status),
              _buildDetailRow(
                Icons.date_range,
                'Created Date',
                invoice.createdDate,
              ),
              if (invoice.paidDate != null)
                _buildDetailRow(
                  Icons.check_circle,
                  'Paid Date',
                  invoice.paidDate!,
                ),
              const SizedBox(height: 20),
              if (invoice.status == 'Unpaid')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _markAsPaid(invoice.id);
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.check_circle),
                    label: Text('Mark as Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: AppTextStyles.labelText.copyWith(
              color: AppColors.subtitle,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔥 ADD/EDIT INVOICE DIALOG WITH STUDENT PACKAGES
class AddEditInvoiceDialog extends StatefulWidget {
  final Invoice? invoice;
  final List<StudentDropdown> availableStudents;

  const AddEditInvoiceDialog({
    super.key,
    this.invoice,
    required this.availableStudents,
  });

  @override
  State<AddEditInvoiceDialog> createState() => _AddEditInvoiceDialogState();
}

class _AddEditInvoiceDialogState extends State<AddEditInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _packageController;
  late TextEditingController _amountController;
  String? _selectedStudentId;
  DateTime? _selectedDueDate;
  String _selectedStatus = 'Unpaid';
  bool _isLoading = false;

  // 🔥 STUDENT PACKAGES LIST
  List<Map<String, dynamic>> _studentPackages = [];
  bool _loadingPackages = false;

  @override
  void initState() {
    super.initState();
    _packageController = TextEditingController(
      text: widget.invoice?.package ?? '',
    );
    _amountController = TextEditingController(
      text: widget.invoice?.amount.toString() ?? '',
    );
    _selectedStudentId =
        widget.invoice?.studentId ??
        (widget.availableStudents.isNotEmpty
            ? widget.availableStudents.first.id
            : null);
    _selectedStatus = widget.invoice?.status ?? 'Unpaid';

    // Parse existing due date
    if (widget.invoice != null) {
      try {
        _selectedDueDate = DateTime.parse(widget.invoice!.dueDate);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Load packages for selected student
    if (_selectedStudentId != null) {
      _loadStudentPackages(_selectedStudentId!);
    }
  }

  @override
  void dispose() {
    _packageController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // 🔥 LOAD STUDENT PACKAGES FROM PACKAGEASSIGNMENTS
  Future<void> _loadStudentPackages(String studentId) async {
    setState(() => _loadingPackages = true);

    try {
      final packageAssignments = await _firestore
          .collection('packageAssignments')
          .where('studentId', isEqualTo: studentId)
          .get();

      List<Map<String, dynamic>> packages = [];

      for (var doc in packageAssignments.docs) {
        final data = doc.data();
        final packageId = data['packageId']?.toString() ?? '';

        if (packageId.isNotEmpty) {
          // Get package details from packages collection
          final packageDoc = await _firestore
              .collection('packages')
              .doc(packageId)
              .get();

          if (packageDoc.exists) {
            final packageData = packageDoc.data();
            packages.add({
              'id': packageId,
              'name': packageData?['name'] ?? 'Unknown Package',
              'price': packageData?['price'] ?? 0,
              'description': packageData?['description'] ?? '',
            });
          }
        }
      }

      setState(() {
        _studentPackages = packages;
        _loadingPackages = false;
      });

      print('📦 Loaded ${packages.length} packages for student $studentId');
    } catch (e) {
      print('❌ Error loading student packages: $e');
      setState(() => _loadingPackages = false);
    }
  }

  // 🔥 ADD INVOICE
  Future<void> _addInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format date
      final formattedDate =
          '${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}';

      await _firestore.collection('invoices').add({
        'studentId': _selectedStudentId,
        'package': _packageController.text.trim(),
        'amount': int.parse(_amountController.text.trim()),
        'dueDate': formattedDate,
        'status': _selectedStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice created successfully!',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔥 UPDATE INVOICE
  Future<void> _updateInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format date
      final formattedDate =
          '${_selectedDueDate!.year}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}';

      await _firestore.collection('invoices').doc(widget.invoice!.id).update({
        'studentId': _selectedStudentId,
        'package': _packageController.text.trim(),
        'amount': int.parse(_amountController.text.trim()),
        'dueDate': formattedDate,
        'status': _selectedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice updated successfully!',
            style: AppTextStyles.bodySmall,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.invoice != null;

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
                      isEdit ? 'Edit Invoice' : 'Create New Invoice',
                      style: AppTextStyles.heading2,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Student Selection
                _buildStudentDropdown(),
                const SizedBox(height: 20),

                // Package Selection
                _buildPackageDropdown(),
                const SizedBox(height: 20),

                // Amount
                _buildAmountField(),
                const SizedBox(height: 20),

                // Due Date
                _buildDateField(),
                const SizedBox(height: 20),

                // Status
                _buildStatusSelection(),
                const SizedBox(height: 24),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'The student will receive the invoice via email and in their app immediately after creation.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
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
                          : (isEdit ? _updateInvoice : _addInvoice),
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
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Invoice' : 'Create Invoice',
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

  Widget _buildStudentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Student', style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedStudentId,
          style: AppTextStyles.inputValue,
          decoration: InputDecoration(
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
          items: widget.availableStudents.map((student) {
            return DropdownMenuItem(
              value: student.id,
              child: Text(student.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStudentId = value;
              _packageController.clear();
              _amountController.clear();
            });
            // Load packages for selected student
            if (value != null) {
              _loadStudentPackages(value);
            }
          },
          validator: (value) =>
              value == null ? 'Please select a student' : null,
        ),
      ],
    );
  }

  Widget _buildPackageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Package', style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),

        if (_loadingPackages)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading packages...',
                  style: AppTextStyles.inputValue.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          )
        else if (_studentPackages.isEmpty && _selectedStudentId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Text(
                  'No packages assigned to this student',
                  style: AppTextStyles.inputValue.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _packageController.text.isEmpty
                ? null
                : _packageController.text,
            style: AppTextStyles.inputValue,
            decoration: InputDecoration(
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
            items: _studentPackages.map((package) {
              return DropdownMenuItem(
                value: package['name'] as String,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(package['name'] as String),
                    const SizedBox(height: 2),
                    Text(
                      '₨ ${NumberFormat('#,##0').format(package['price'])}',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.subtitle,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _packageController.text = value!;
                final selectedPackage = _studentPackages.firstWhere(
                  (p) => p['name'] == value,
                );
                _amountController.text = selectedPackage['price'].toString();
              });
            },
            validator: (value) =>
                value == null ? 'Please select a package' : null,
          ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amount (Usd))', style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: AppTextStyles.inputValue,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary),
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
              return 'Please enter amount';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter valid amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Due Date', style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  _selectedDueDate ??
                  DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: AppColors.primary),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDueDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDueDate == null
                    ? AppColors.border
                    : AppColors.primary,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _selectedDueDate == null
                      ? AppColors.subtitle
                      : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDueDate == null
                      ? 'Select due date'
                      : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                  style: AppTextStyles.inputValue.copyWith(
                    color: _selectedDueDate == null
                        ? AppColors.subtitle
                        : AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedDueDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'Please select a due date',
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedStatus = 'Unpaid'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedStatus == 'Unpaid'
                        ? const Color(0xFFF59E0B).withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedStatus == 'Unpaid'
                          ? const Color(0xFFF59E0B)
                          : AppColors.border,
                      width: _selectedStatus == 'Unpaid' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pending_outlined,
                        color: const Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unpaid',
                        style: AppTextStyles.labelText.copyWith(
                          color: const Color(0xFFF59E0B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedStatus = 'Paid'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedStatus == 'Paid'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedStatus == 'Paid'
                          ? const Color(0xFF10B981)
                          : AppColors.border,
                      width: _selectedStatus == 'Paid' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Paid',
                        style: AppTextStyles.labelText.copyWith(
                          color: const Color(0xFF10B981),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 🔥 INVOICE MODEL
class Invoice {
  final String id;
  final String studentId;
  final String studentName;
  final String package;
  final int amount;
  final String dueDate;
  final String status;
  final String createdDate;
  final String? paidDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Invoice({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.package,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.createdDate,
    this.paidDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String studentName,
  ) {
    return Invoice(
      id: id,
      studentId: data['studentId']?.toString() ?? '',
      studentName: studentName,
      package: data['package']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      dueDate: data['dueDate']?.toString() ?? '',
      status: data['status']?.toString() ?? 'Unpaid',
      createdDate: data['createdAt']?.toDate() != null
          ? '${data['createdAt']!.toDate().year}-${data['createdAt']!.toDate().month.toString().padLeft(2, '0')}-${data['createdAt']!.toDate().day.toString().padLeft(2, '0')}'
          : '',
      paidDate: data['paidAt']?.toDate() != null
          ? '${data['paidAt']!.toDate().year}-${data['paidAt']!.toDate().month.toString().padLeft(2, '0')}-${data['paidAt']!.toDate().day.toString().padLeft(2, '0')}'
          : null,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }
}

// 🔥 STUDENT DROPDOWN MODEL
class StudentDropdown {
  final String id;
  final String name;

  StudentDropdown({required this.id, required this.name});
}

// Create Invoice Screen (Legacy - for reference)
class CreateInvoiceScreen extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const CreateInvoiceScreen({
    super.key,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.text),
                onPressed: widget.onCancel,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Invoice',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.text,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill in the details to create a new invoice',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.subtitle,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: AppColors.subtitle),
                  const SizedBox(height: 16),
                  Text(
                    'Use the "Create Invoice" button to add new invoices',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: widget.onCancel,
                    child: Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}