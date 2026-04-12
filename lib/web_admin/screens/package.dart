// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:studyalquran/utils/app_text_styles.dart';
// import 'package:studyalquran/utils/color_constants.dart';

// class PackagesManagementScreen extends StatefulWidget {
//   const PackagesManagementScreen({super.key});

//   @override
//   State<PackagesManagementScreen> createState() => _PackagesManagementScreenState();
// }

// class _PackagesManagementScreenState extends State<PackagesManagementScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String searchQuery = '';
//   String filterStatus = 'all'; // all, active, inactive

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold( // ✅ ADDED SCAFFOLD
//       body: Container(
//         padding: const EdgeInsets.all(28),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildHeader(),
//             const SizedBox(height: 28),
//             _buildSearchAndFilter(),
//             const SizedBox(height: 24),
//             Expanded(child: _buildPackagesList()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Packages Management',
//               style: AppTextStyles.heading3.copyWith(
//                 color: AppColors.text,
//                 fontSize: 24,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Manage all subscription packages',
//               style: AppTextStyles.bodyMedium.copyWith(
//                 color: AppColors.subtitle,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//         ElevatedButton.icon(
//           onPressed: () => _showAddPackageDialog(),
//           icon: const Icon(Icons.add, size: 20),
//           label: const Text('Add New Package'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primary,
//             foregroundColor: AppColors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchAndFilter() {
//     return Row(
//       children: [
//         Expanded(
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: AppColors.card,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: AppColors.border),
//             ),
//             child: TextField(
//               onChanged: (value) => setState(() => searchQuery = value),
//               style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
//               decoration: InputDecoration(
//                 hintText: 'Search packages...',
//                 hintStyle: AppTextStyles.bodyMedium.copyWith(
//                   color: AppColors.subtitle,
//                 ),
//                 border: InputBorder.none,
//                 icon: Icon(Icons.search, color: AppColors.subtitle),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           decoration: BoxDecoration(
//             color: AppColors.card,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: DropdownButton<String>(
//             value: filterStatus,
//             onChanged: (value) => setState(() => filterStatus = value!),
//             underline: const SizedBox(),
//             icon: Icon(Icons.filter_list, color: AppColors.primary, size: 20),
//             items: [
//               DropdownMenuItem(
//                 value: 'all',
//                 child: Text('All Packages', style: AppTextStyles.bodyMedium),
//               ),
//               DropdownMenuItem(
//                 value: 'active',
//                 child: Text('Active Only', style: AppTextStyles.bodyMedium),
//               ),
//               DropdownMenuItem(
//                 value: 'inactive',
//                 child: Text('Inactive Only', style: AppTextStyles.bodyMedium),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPackagesList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _getPackagesStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(
//             child: CircularProgressIndicator(color: AppColors.primary),
//           );
//         }

//         if (snapshot.hasError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.error_outline, color: AppColors.error, size: 48),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Error loading packages',
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     color: AppColors.subtitle,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         var packages = snapshot.data?.docs ?? [];

//         // Filter by search query
//         if (searchQuery.isNotEmpty) {
//           packages = packages.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             final name = data['name']?.toString().toLowerCase() ?? '';
//             return name.contains(searchQuery.toLowerCase());
//           }).toList();
//         }

//         // Filter by status
//         if (filterStatus != 'all') {
//           packages = packages.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data['status'] == filterStatus;
//           }).toList();
//         }

//         if (packages.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.inventory_2_outlined,
//                     color: AppColors.subtitle, size: 64),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No packages found',
//                   style: AppTextStyles.heading5.copyWith(
//                     color: AppColors.text,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Add your first package to get started',
//                   style: AppTextStyles.bodyMedium.copyWith(
//                     color: AppColors.subtitle,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return GridView.builder(
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3,
//             childAspectRatio: 1.1, // ✅ FIXED ASPECT RATIO
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//           ),
//           padding: const EdgeInsets.only(bottom: 20), // ✅ ADDED PADDING
//           itemCount: packages.length,
//           itemBuilder: (context, index) {
//             final doc = packages[index];
//             final data = doc.data() as Map<String, dynamic>;
//             return _buildPackageCard(doc.id, data);
//           },
//         );
//       },
//     );
//   }

//   Stream<QuerySnapshot> _getPackagesStream() {
//     return _firestore.collection('packages').snapshots();
//   }

//   Widget _buildPackageCard(String packageId, Map<String, dynamic> data) {
//     final isActive = data['status'] == 'active';
    
//     return Card( // ✅ USED CARD INSTEAD OF CONTAINER
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: isActive 
//               ? AppColors.primary.withOpacity(0.3) 
//               : AppColors.border.withOpacity(0.5),
//           width: isActive ? 2 : 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header with status badge
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: isActive 
//                   ? AppColors.primary.withOpacity(0.1)
//                   : AppColors.subtitle.withOpacity(0.05),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(16),
//                 topRight: Radius.circular(16),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: isActive 
//                         ? AppColors.primary.withOpacity(0.2)
//                         : AppColors.subtitle.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     Icons.inventory_2,
//                     color: isActive ? AppColors.primary : AppColors.subtitle,
//                     size: 24,
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isActive ? AppColors.success : AppColors.subtitle,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     isActive ? 'ACTIVE' : 'INACTIVE',
//                     style: AppTextStyles.captionText.copyWith(
//                       color: AppColors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Package Details
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ FIXED SPACING
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         data['name']?.toString() ?? 'Unnamed Package',
//                         style: AppTextStyles.heading5.copyWith(
//                           color: AppColors.text,
//                           fontSize: 16,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         data['description']?.toString() ?? 'No description',
//                         style: AppTextStyles.bodySmall.copyWith(
//                           color: AppColors.subtitle,
//                           fontSize: 12,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
                  
//                   // Price & Duration
//                   Column(
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Price',
//                                   style: AppTextStyles.captionText.copyWith(
//                                     color: AppColors.subtitle,
//                                     fontSize: 10,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 2),
//                                 Text(
//                                   'Rs ${data['price'] ?? 0}',
//                                   style: AppTextStyles.labelText.copyWith(
//                                     color: AppColors.primary,
//                                     fontSize: 14, // ✅ REDUCED FONT SIZE
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Duration',
//                                   style: AppTextStyles.captionText.copyWith(
//                                     color: AppColors.subtitle,
//                                     fontSize: 10,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 2),
//                                 Text(
//                                   '${data['duration'] ?? 0} month(s)',
//                                   style: AppTextStyles.labelText.copyWith(
//                                     color: AppColors.text,
//                                     fontSize: 12, // ✅ REDUCED FONT SIZE
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 10),
                      
//                       // Classes & Expiry
//                       Row(
//                         children: [
//                           Icon(Icons.class_, color: AppColors.subtitle, size: 12),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${data['numberOfClasses'] ?? 0} classes',
//                             style: AppTextStyles.captionText.copyWith(
//                               color: AppColors.subtitle,
//                               fontSize: 10,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Icon(Icons.timer, color: AppColors.subtitle, size: 12),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${data['expiryDays'] ?? 0} days',
//                             style: AppTextStyles.captionText.copyWith(
//                               color: AppColors.subtitle,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Action Buttons
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               border: Border(
//                 top: BorderSide(color: AppColors.border.withOpacity(0.5)),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: SizedBox( // ✅ ADDED SIZEDBOX FOR BUTTON
//                     height: 36,
//                     child: OutlinedButton.icon(
//                       onPressed: () => _showAssignPackageDialog(packageId, data),
//                       icon: const Icon(Icons.person_add, size: 14),
//                       label: const Text('Assign'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: AppColors.primary,
//                         side: BorderSide(color: AppColors.primary),
//                         padding: const EdgeInsets.symmetric(vertical: 4),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 6), // ✅ REDUCED SPACING
//                 SizedBox( // ✅ ADDED SIZEDBOX FOR ICON BUTTONS
//                   height: 36,
//                   width: 36,
//                   child: IconButton(
//                     onPressed: () => _showEditPackageDialog(packageId, data),
//                     icon: Icon(Icons.edit_outlined, size: 16),
//                     color: const Color(0xFF8B5CF6),
//                     tooltip: 'Edit',
//                     padding: EdgeInsets.zero,
//                   ),
//                 ),
//                 SizedBox( // ✅ ADDED SIZEDBOX FOR ICON BUTTONS
//                   height: 36,
//                   width: 36,
//                   child: IconButton(
//                     onPressed: () => _showDeleteConfirmation(packageId),
//                     icon: Icon(Icons.delete_outline, size: 16),
//                     color: AppColors.error,
//                     tooltip: 'Delete',
//                     padding: EdgeInsets.zero,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 🔥 ADD PACKAGE DIALOG - FIXED OVERFLOW
//   void _showAddPackageDialog() {
//     final nameController = TextEditingController();
//     final descController = TextEditingController();
//     final priceController = TextEditingController();
//     final durationController = TextEditingController();
//     final classesController = TextEditingController();
//     final expiryController = TextEditingController();
//     final discountController = TextEditingController(text: '0');
//     bool isActive = true;

//     showDialog(
//       context: context,
//       builder: (context) => Dialog( // ✅ CHANGED TO DIALOG
//         insetPadding: const EdgeInsets.all(20), // ✅ ADDED INSET PADDING
//         child: ConstrainedBox( // ✅ ADDED CONSTRAINEDBOX
//           constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
//           child: StatefulBuilder(
//             builder: (context, setDialogState) => Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Header
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: AppColors.primary.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(Icons.add_box, color: AppColors.primary, size: 24),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Add New Package',
//                         style: AppTextStyles.heading5.copyWith(color: AppColors.text),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Content
//                   Expanded( // ✅ ADDED EXPANDED
//                     child: SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           _buildTextField(nameController, 'Package Name', Icons.inventory_2),
//                           const SizedBox(height: 16),
//                           _buildTextField(descController, 'Description', Icons.description, maxLines: 3),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildTextField(priceController, 'Price (Rs)', Icons.attach_money, isNumber: true),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _buildTextField(durationController, 'Duration (months)', Icons.calendar_month, isNumber: true),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildTextField(classesController, 'Number of Classes', Icons.class_, isNumber: true),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _buildTextField(expiryController, 'Expiry Days', Icons.timer, isNumber: true),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           _buildTextField(discountController, 'Discount (%)', Icons.discount, isNumber: true),
//                           const SizedBox(height: 16),
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: AppColors.background,
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(color: AppColors.border),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   'Package Status',
//                                   style: AppTextStyles.bodyMedium.copyWith(
//                                     color: AppColors.text,
//                                   ),
//                                 ),
//                                 Switch(
//                                   value: isActive,
//                                   onChanged: (value) => setDialogState(() => isActive = value),
//                                   activeThumbColor: AppColors.primary,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Actions
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton(
//                         onPressed: () async {
//                           if (nameController.text.isEmpty || priceController.text.isEmpty) {
//                             _showSnackBar('Please fill required fields', isError: true);
//                             return;
//                           }

//                           try {
//                             await _firestore.collection('packages').add({
//                               'name': nameController.text,
//                               'description': descController.text,
//                               'price': double.parse(priceController.text),
//                               'duration': int.parse(durationController.text),
//                               'numberOfClasses': int.parse(classesController.text),
//                               'expiryDays': int.parse(expiryController.text),
//                               'discount': double.parse(discountController.text),
//                               'status': isActive ? 'active' : 'inactive',
//                               'createdAt': FieldValue.serverTimestamp(),
//                             });

//                             Navigator.pop(context);
//                             _showSnackBar('Package added successfully!');
//                           } catch (e) {
//                             _showSnackBar('Error: $e', isError: true);
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primary,
//                           foregroundColor: AppColors.white,
//                         ),
//                         child: const Text('Add Package'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 🔥 EDIT PACKAGE DIALOG - SAME FIXES APPLIED
//   void _showEditPackageDialog(String packageId, Map<String, dynamic> data) {
//     final nameController = TextEditingController(text: data['name']);
//     final descController = TextEditingController(text: data['description']);
//     final priceController = TextEditingController(text: data['price'].toString());
//     final durationController = TextEditingController(text: data['duration'].toString());
//     final classesController = TextEditingController(text: data['numberOfClasses'].toString());
//     final expiryController = TextEditingController(text: data['expiryDays'].toString());
//     final discountController = TextEditingController(text: data['discount']?.toString() ?? '0');
//     bool isActive = data['status'] == 'active';

//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         insetPadding: const EdgeInsets.all(20),
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
//           child: StatefulBuilder(
//             builder: (context, setDialogState) => Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF8B5CF6).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(Icons.edit, color: const Color(0xFF8B5CF6), size: 24),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Edit Package',
//                         style: AppTextStyles.heading5.copyWith(color: AppColors.text),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           _buildTextField(nameController, 'Package Name', Icons.inventory_2),
//                           const SizedBox(height: 16),
//                           _buildTextField(descController, 'Description', Icons.description, maxLines: 3),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildTextField(priceController, 'Price (Rs)', Icons.attach_money, isNumber: true),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _buildTextField(durationController, 'Duration (months)', Icons.calendar_month, isNumber: true),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildTextField(classesController, 'Number of Classes', Icons.class_, isNumber: true),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: _buildTextField(expiryController, 'Expiry Days', Icons.timer, isNumber: true),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           _buildTextField(discountController, 'Discount (%)', Icons.discount, isNumber: true),
//                           const SizedBox(height: 16),
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: AppColors.background,
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(color: AppColors.border),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   'Package Status',
//                                   style: AppTextStyles.bodyMedium.copyWith(
//                                     color: AppColors.text,
//                                   ),
//                                 ),
//                                 Switch(
//                                   value: isActive,
//                                   onChanged: (value) => setDialogState(() => isActive = value),
//                                   activeThumbColor: AppColors.primary,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton(
//                         onPressed: () async {
//                           try {
//                             await _firestore.collection('packages').doc(packageId).update({
//                               'name': nameController.text,
//                               'description': descController.text,
//                               'price': double.parse(priceController.text),
//                               'duration': int.parse(durationController.text),
//                               'numberOfClasses': int.parse(classesController.text),
//                               'expiryDays': int.parse(expiryController.text),
//                               'discount': double.parse(discountController.text),
//                               'status': isActive ? 'active' : 'inactive',
//                               'updatedAt': FieldValue.serverTimestamp(),
//                             });

//                             Navigator.pop(context);
//                             _showSnackBar('Package updated successfully!');
//                           } catch (e) {
//                             _showSnackBar('Error: $e', isError: true);
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF8B5CF6),
//                           foregroundColor: AppColors.white,
//                         ),
//                         child: const Text('Update Package'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 🔥 ASSIGN PACKAGE DIALOG - FIXED
//   void _showAssignPackageDialog(String packageId, Map<String, dynamic> packageData) {
//     String? selectedStudentId;
//     DateTime startDate = DateTime.now();
//     DateTime endDate = DateTime.now().add(Duration(days: packageData['expiryDays'] ?? 30));

//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         insetPadding: const EdgeInsets.all(20),
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
//           child: StatefulBuilder(
//             builder: (context, setDialogState) => Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: AppColors.success.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(Icons.person_add, color: AppColors.success, size: 24),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Assign Package',
//                         style: AppTextStyles.heading5.copyWith(color: AppColors.text),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Package Info
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: AppColors.primary.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   packageData['name'],
//                                   style: AppTextStyles.labelText.copyWith(
//                                     color: AppColors.primary,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 Text(
//                                   'Rs ${packageData['price']} • ${packageData['duration']} month(s)',
//                                   style: AppTextStyles.captionText.copyWith(
//                                     color: AppColors.subtitle,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 20),

//                           // Student Selection
//                           Text(
//                             'Select Student',
//                             style: AppTextStyles.labelText.copyWith(color: AppColors.text),
//                           ),
//                           const SizedBox(height: 8),
//                           StreamBuilder<QuerySnapshot>(
//                             stream: _firestore.collection('students').snapshots(),
//                             builder: (context, snapshot) {
//                               if (!snapshot.hasData) {
//                                 return CircularProgressIndicator();
//                               }

//                               final students = snapshot.data!.docs;
                              
//                               return Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                                 decoration: BoxDecoration(
//                                   border: Border.all(color: AppColors.border),
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: DropdownButton<String>(
//                                   isExpanded: true,
//                                   underline: const SizedBox(),
//                                   hint: Text('Choose a student'),
//                                   value: selectedStudentId,
//                                   items: students.map((doc) {
//                                     final data = doc.data() as Map<String, dynamic>;
//                                     return DropdownMenuItem(
//                                       value: doc.id,
//                                       child: Text(data['name'] ?? 'Unknown'),
//                                     );
//                                   }).toList(),
//                                   onChanged: (value) {
//                                     setDialogState(() => selectedStudentId = value);
//                                   },
//                                 ),
//                               );
//                             },
//                           ),
//                           const SizedBox(height: 20),

//                           // Start Date
//                           Text(
//                             'Start Date',
//                             style: AppTextStyles.labelText.copyWith(color: AppColors.text),
//                           ),
//                           const SizedBox(height: 8),
//                           InkWell(
//                             onTap: () async {
//                               final date = await showDatePicker(
//                                 context: context,
//                                 initialDate: startDate,
//                                 firstDate: DateTime.now(),
//                                 lastDate: DateTime.now().add(const Duration(days: 365)),
//                               );
//                               if (date != null) {
//                                 setDialogState(() {
//                                   startDate = date;
//                                   endDate = date.add(Duration(days: packageData['expiryDays'] ?? 30));
//                                 });
//                               }
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: AppColors.border),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     DateFormat('dd/MM/yyyy').format(startDate),
//                                     style: AppTextStyles.bodyMedium,
//                                   ),
//                                   Icon(Icons.calendar_today, color: AppColors.primary),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),

//                           // End Date (Auto-calculated)
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: AppColors.background,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'End Date (Auto)',
//                                       style: AppTextStyles.captionText.copyWith(
//                                         color: AppColors.subtitle,
//                                       ),
//                                     ),
//                                     Text(
//                                       DateFormat('dd/MM/yyyy').format(endDate),
//                                       style: AppTextStyles.labelText.copyWith(
//                                         color: AppColors.text,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 Icon(Icons.event_available, color: AppColors.success),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton(
//                         onPressed: () async {
//                           if (selectedStudentId == null) {
//                             _showSnackBar('Please select a student', isError: true);
//                             return;
//                           }

//                           try {
//                             await _firestore.collection('packageAssignments').add({
//                               'packageId': packageId,
//                               'packageName': packageData['name'],
//                               'studentId': selectedStudentId,
//                               'price': packageData['price'],
//                               'duration': packageData['duration'],
//                               'numberOfClasses': packageData['numberOfClasses'],
//                               'remainingClasses': packageData['numberOfClasses'],
//                               'startDate': Timestamp.fromDate(startDate),
//                               'endDate': Timestamp.fromDate(endDate),
//                               'status': 'active',
//                               'assignedAt': FieldValue.serverTimestamp(),
//                             });

//                             // Log activity
//                             await _firestore.collection('activities').add({
//                               'type': 'package_assigned',
//                               'message': 'Package assigned to student',
//                               'timestamp': FieldValue.serverTimestamp(),
//                             });

//                             Navigator.pop(context);
//                             _showSnackBar('Package assigned successfully!');
//                           } catch (e) {
//                             _showSnackBar('Error: $e', isError: true);
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.success,
//                           foregroundColor: AppColors.white,
//                         ),
//                         child: const Text('Assign Package'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // 🔥 DELETE CONFIRMATION - FIXED
//   void _showDeleteConfirmation(String packageId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
//             const SizedBox(width: 12),
//             Text(
//               'Delete Package',
//               style: AppTextStyles.heading5.copyWith(color: AppColors.text),
//             ),
//           ],
//         ),
//         content: Text(
//           'Are you sure you want to delete this package? This action cannot be undone.',
//           style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 await _firestore.collection('packages').doc(packageId).delete();
                
//                 // Log activity
//                 await _firestore.collection('activities').add({
//                   'type': 'package_deleted',
//                   'message': 'Package deleted',
//                   'timestamp': FieldValue.serverTimestamp(),
//                 });

//                 Navigator.pop(context);
//                 _showSnackBar('Package deleted successfully!');
//               } catch (e) {
//                 _showSnackBar('Error: $e', isError: true);
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.error,
//               foregroundColor: AppColors.white,
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }

//   // 🔥 HELPER: TEXT FIELD BUILDER
//   Widget _buildTextField(
//     TextEditingController controller,
//     String label,
//     IconData icon, {
//     bool isNumber = false,
//     int maxLines = 1,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//       maxLines: maxLines,
//       style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
//         prefixIcon: Icon(icon, color: AppColors.primary),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: AppColors.border),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: AppColors.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: AppColors.primary, width: 2),
//         ),
//         filled: true,
//         fillColor: AppColors.card,
//       ),
//     );
//   }

//   // 🔥 HELPER: SHOW SNACKBAR
//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error_outline : Icons.check_circle_outline,
//               color: AppColors.white,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 message,
//                 style: AppTextStyles.bodyMedium.copyWith(
//                   color: AppColors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: isError ? AppColors.error : AppColors.success,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 ADD THIS TO pubspec.yaml
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';

class PackagesManagementScreen extends StatefulWidget {
  const PackagesManagementScreen({super.key});

  @override
  State<PackagesManagementScreen> createState() => _PackagesManagementScreenState();
}

class _PackagesManagementScreenState extends State<PackagesManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';
  String filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildSearchAndFilter(),
            const SizedBox(height: 24),
            Expanded(child: _buildPackagesList()),
          ],
        ),
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
              'Packages Management',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.text,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage all subscription packages',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
                fontSize: 14,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddPackageDialog(),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add New Package'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Search packages...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: AppColors.subtitle),
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
            onChanged: (value) => setState(() => filterStatus = value!),
            underline: const SizedBox(),
            icon: Icon(Icons.filter_list, color: AppColors.primary, size: 20),
            items: [
              DropdownMenuItem(value: 'all', child: Text('All Packages', style: AppTextStyles.bodyMedium)),
              DropdownMenuItem(value: 'active', child: Text('Active Only', style: AppTextStyles.bodyMedium)),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive Only', style: AppTextStyles.bodyMedium)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getPackagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Error loading packages', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle)),
              ],
            ),
          );
        }

        var packages = snapshot.data?.docs ?? [];

        if (searchQuery.isNotEmpty) {
          packages = packages.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name']?.toString().toLowerCase() ?? '';
            return name.contains(searchQuery.toLowerCase());
          }).toList();
        }

        if (filterStatus != 'all') {
          packages = packages.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == filterStatus;
          }).toList();
        }

        if (packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, color: AppColors.subtitle, size: 64),
                const SizedBox(height: 16),
                Text('No packages found', style: AppTextStyles.heading5.copyWith(color: AppColors.text)),
                const SizedBox(height: 8),
                Text('Add your first package to get started', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle)),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final doc = packages[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPackageCard(doc.id, data);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getPackagesStream() {
    return _firestore.collection('packages').snapshots();
  }

  Widget _buildPackageCard(String packageId, Map<String, dynamic> data) {
    final isActive = data['status'] == 'active';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.border.withOpacity(0.5),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.1) : AppColors.subtitle.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withOpacity(0.2) : AppColors.subtitle.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: isActive ? AppColors.primary : AppColors.subtitle,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success : AppColors.subtitle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: AppTextStyles.captionText.copyWith(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Package Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name']?.toString() ?? 'Unnamed Package',
                        style: AppTextStyles.heading5.copyWith(color: AppColors.text, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['description']?.toString() ?? 'No description',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price', style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  'Usd ${data['price'] ?? 0}',
                                  style: AppTextStyles.labelText.copyWith(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Duration', style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  '${data['duration'] ?? 0} month(s)',
                                  style: AppTextStyles.labelText.copyWith(color: AppColors.text, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.class_, color: AppColors.subtitle, size: 12),
                          const SizedBox(width: 4),
                          Text('${data['numberOfClasses'] ?? 0} classes', style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle, fontSize: 10)),
                          const SizedBox(width: 8),
                          Icon(Icons.timer, color: AppColors.subtitle, size: 12),
                          const SizedBox(width: 4),
                          Text('${data['expiryDays'] ?? 0} days', style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ✅ Action Buttons — WhatsApp button added
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAssignPackageDialog(packageId, data),
                      icon: const Icon(Icons.person_add, size: 14),
                      label: const Text('Assign'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // ✅ NEW: WhatsApp Reminder Button
                SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                    onPressed: () => _showSendReminderDialog(packageId, data),
                    icon: const Icon(Icons.chat, size: 18),
                    color: const Color(0xFF25D366), // WhatsApp green
                    tooltip: 'Send Renewal Reminder',
                    padding: EdgeInsets.zero,
                  ),
                ),

                SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                    onPressed: () => _showEditPackageDialog(packageId, data),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    color: const Color(0xFF8B5CF6),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                    onPressed: () => _showDeleteConfirmation(packageId),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: AppColors.error,
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ NEW: WHATSAPP RENEWAL REMINDER DIALOG
  // ============================================================
  void _showSendReminderDialog(String packageId, Map<String, dynamic> packageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Renewal Reminder',
                          style: AppTextStyles.heading5.copyWith(color: AppColors.text),
                        ),
                        Text(
                          'Select student to send WhatsApp message',
                          style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Package info box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              packageData['name'] ?? 'Package',
                              style: AppTextStyles.labelText.copyWith(color: AppColors.primary),
                            ),
                            Text(
                              'Usd ${packageData['price'] ?? 0}  •  ${packageData['numberOfClasses'] ?? 0} classes',
                              style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Students list with expired/expiring assignments
                Text(
                  'Students with this package:',
                  style: AppTextStyles.labelText.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('packageAssignments')
                        .where('packageId', isEqualTo: packageId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }

                      final assignments = snapshot.data?.docs ?? [];

                      if (assignments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, color: AppColors.subtitle, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'No students assigned to this package',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.subtitle),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: assignments.length,
                        itemBuilder: (context, index) {
                          final assignData = assignments[index].data() as Map<String, dynamic>;
                          final studentId = assignData['studentId']?.toString() ?? '';
                          final status = assignData['status']?.toString() ?? 'active';

                          DateTime? endDate;
                          try {
                            if (assignData['endDate'] != null) {
                              endDate = (assignData['endDate'] as Timestamp).toDate();
                            }
                          } catch (_) {}

                          // ✅ Badge color based on status
                          final isExpired = status == 'expired' ||
                              status == 'completed' ||
                              (endDate != null && endDate.isBefore(DateTime.now()));

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('students').doc(studentId).get(),
                            builder: (context, studentSnap) {
                              if (!studentSnap.hasData) return const SizedBox();

                              final studentData = studentSnap.data?.data() as Map<String, dynamic>?;
                              final studentName = studentData?['name'] ?? 'Unknown';
                              final phone = studentData?['phone']?.toString() ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isExpired
                                        ? AppColors.error.withOpacity(0.3)
                                        : AppColors.border.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: Text(
                                        studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                                        style: AppTextStyles.labelText.copyWith(color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Student info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            studentName,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 11, color: AppColors.subtitle),
                                              const SizedBox(width: 4),
                                              Text(
                                                phone.isNotEmpty ? phone : 'No phone',
                                                style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle),
                                              ),
                                              const SizedBox(width: 8),
                                              if (endDate != null) ...[
                                                Icon(Icons.event, size: 11, color: AppColors.subtitle),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('dd MMM yyyy').format(endDate),
                                                  style: AppTextStyles.captionText.copyWith(
                                                    color: isExpired ? AppColors.error : AppColors.subtitle,
                                                    fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status badge
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isExpired
                                            ? AppColors.error.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isExpired ? 'Expired' : 'Active',
                                        style: AppTextStyles.captionText.copyWith(
                                          color: isExpired ? AppColors.error : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),

                                    // ✅ WhatsApp Send Button
                                    SizedBox(
                                      height: 36,
                                      child: ElevatedButton.icon(
                                        onPressed: phone.isNotEmpty
                                            ? () {
                                                Navigator.pop(context);
                                                _sendWhatsAppReminder(
                                                  studentName: studentName,
                                                  phone: phone,
                                                  packageName: packageData['name'] ?? 'Package',
                                                  price: packageData['price']?.toString() ?? '0',
                                                  endDate: endDate,
                                                );
                                              }
                                            : null,
                                        icon: const Icon(Icons.chat, size: 14),
                                        label: const Text('Send', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF25D366),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(color: AppColors.subtitle)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ NEW: SEND WHATSAPP MESSAGE
  // ============================================================
  Future<void> _sendWhatsAppReminder({
    required String studentName,
    required String phone,
    required String packageName,
    required String price,
    DateTime? endDate,
  }) async {
    // ✅ Clean phone number — remove spaces, dashes, +
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // ✅ Add country code if not present (Pakistan = 92)
    if (!cleanPhone.startsWith('+') && !cleanPhone.startsWith('92')) {
      cleanPhone = '92$cleanPhone';
    }
    cleanPhone = cleanPhone.replaceAll('+', '');

    // ✅ Build the message
    final expiryText = endDate != null
        ? DateFormat('dd MMM yyyy').format(endDate)
        : 'recently';

    final message = '''Assalam o Alaikum $studentName! 🌙

Hope you are doing well.

Your *$packageName* plan has expired on *$expiryText*.

To continue your Quran learning sessions without any interruption, please renew your plan.

📋 *Renewal Details:*
• Package: $packageName
• Amount: Usd $price

Please make the payment and share the confirmation so we can activate your plan right away. JazakAllah Khair! 🤲

*StudyAlQuran Team*''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open WhatsApp', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // ============================================================
  // ADD PACKAGE DIALOG
  // ============================================================
  void _showAddPackageDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final classesController = TextEditingController();
    final expiryController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: StatefulBuilder(
            builder: (context, setDialogState) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_box, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('Add New Package', style: AppTextStyles.heading5.copyWith(color: AppColors.text)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTextField(nameController, 'Package Name', Icons.inventory_2),
                          const SizedBox(height: 16),
                          _buildTextField(descController, 'Description', Icons.description, maxLines: 3),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(priceController, 'Price (Usd)', Icons.attach_money, isNumber: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(durationController, 'Duration (months)', Icons.calendar_month, isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(classesController, 'Number of Classes', Icons.class_, isNumber: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(expiryController, 'Expiry Days', Icons.timer, isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(discountController, 'Discount (%)', Icons.discount, isNumber: true),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Package Status', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text)),
                                Switch(
                                  value: isActive,
                                  onChanged: (value) => setDialogState(() => isActive = value),
                                  activeThumbColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty || priceController.text.isEmpty) {
                            _showSnackBar('Please fill required fields', isError: true);
                            return;
                          }
                          try {
                            await _firestore.collection('packages').add({
                              'name': nameController.text,
                              'description': descController.text,
                              'price': double.parse(priceController.text),
                              'duration': int.parse(durationController.text),
                              'numberOfClasses': int.parse(classesController.text),
                              'expiryDays': int.parse(expiryController.text),
                              'discount': double.parse(discountController.text),
                              'status': isActive ? 'active' : 'inactive',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            Navigator.pop(context);
                            _showSnackBar('Package added successfully!');
                          } catch (e) {
                            _showSnackBar('Error: $e', isError: true);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
                        child: const Text('Add Package'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PACKAGE DIALOG
  // ============================================================
  void _showEditPackageDialog(String packageId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    final descController = TextEditingController(text: data['description']);
    final priceController = TextEditingController(text: data['price'].toString());
    final durationController = TextEditingController(text: data['duration'].toString());
    final classesController = TextEditingController(text: data['numberOfClasses'].toString());
    final expiryController = TextEditingController(text: data['expiryDays'].toString());
    final discountController = TextEditingController(text: data['discount']?.toString() ?? '0');
    bool isActive = data['status'] == 'active';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: StatefulBuilder(
            builder: (context, setDialogState) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit, color: const Color(0xFF8B5CF6), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('Edit Package', style: AppTextStyles.heading5.copyWith(color: AppColors.text)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTextField(nameController, 'Package Name', Icons.inventory_2),
                          const SizedBox(height: 16),
                          _buildTextField(descController, 'Description', Icons.description, maxLines: 3),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(priceController, 'Price (Usd)', Icons.attach_money, isNumber: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(durationController, 'Duration (months)', Icons.calendar_month, isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(classesController, 'Number of Classes', Icons.class_, isNumber: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(expiryController, 'Expiry Days', Icons.timer, isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(discountController, 'Discount (%)', Icons.discount, isNumber: true),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Package Status', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text)),
                                Switch(
                                  value: isActive,
                                  onChanged: (value) => setDialogState(() => isActive = value),
                                  activeThumbColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _firestore.collection('packages').doc(packageId).update({
                              'name': nameController.text,
                              'description': descController.text,
                              'price': double.parse(priceController.text),
                              'duration': int.parse(durationController.text),
                              'numberOfClasses': int.parse(classesController.text),
                              'expiryDays': int.parse(expiryController.text),
                              'discount': double.parse(discountController.text),
                              'status': isActive ? 'active' : 'inactive',
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                            Navigator.pop(context);
                            _showSnackBar('Package updated successfully!');
                          } catch (e) {
                            _showSnackBar('Error: $e', isError: true);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: AppColors.white),
                        child: const Text('Update Package'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGN PACKAGE DIALOG
  // ============================================================
  void _showAssignPackageDialog(String packageId, Map<String, dynamic> packageData) {
    String? selectedStudentId;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(Duration(days: packageData['expiryDays'] ?? 30));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
          child: StatefulBuilder(
            builder: (context, setDialogState) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person_add, color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('Assign Package', style: AppTextStyles.heading5.copyWith(color: AppColors.text)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(packageData['name'], style: AppTextStyles.labelText.copyWith(color: AppColors.primary, fontSize: 14)),
                                Text('Usd ${packageData['price']} • ${packageData['duration']} month(s)', style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Select Student', style: AppTextStyles.labelText.copyWith(color: AppColors.text)),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestore.collection('students').snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const CircularProgressIndicator();
                              final students = snapshot.data!.docs;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  hint: const Text('Choose a student'),
                                  value: selectedStudentId,
                                  items: students.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem(value: doc.id, child: Text(data['name'] ?? 'Unknown'));
                                  }).toList(),
                                  onChanged: (value) => setDialogState(() => selectedStudentId = value),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Text('Start Date', style: AppTextStyles.labelText.copyWith(color: AppColors.text)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setDialogState(() {
                                  startDate = date;
                                  endDate = date.add(Duration(days: packageData['expiryDays'] ?? 30));
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('dd/MM/yyyy').format(startDate), style: AppTextStyles.bodyMedium),
                                  Icon(Icons.calendar_today, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('End Date (Auto)', style: AppTextStyles.captionText.copyWith(color: AppColors.subtitle)),
                                    Text(DateFormat('dd/MM/yyyy').format(endDate), style: AppTextStyles.labelText.copyWith(color: AppColors.text)),
                                  ],
                                ),
                                Icon(Icons.event_available, color: AppColors.success),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedStudentId == null) {
                            _showSnackBar('Please select a student', isError: true);
                            return;
                          }
                          try {
                            await _firestore.collection('packageAssignments').add({
                              'packageId': packageId,
                              'packageName': packageData['name'],
                              'studentId': selectedStudentId,
                              'price': packageData['price'],
                              'duration': packageData['duration'],
                              'numberOfClasses': packageData['numberOfClasses'],
                              'remainingClasses': packageData['numberOfClasses'],
                              'startDate': Timestamp.fromDate(startDate),
                              'endDate': Timestamp.fromDate(endDate),
                              'status': 'active',
                              'assignedAt': FieldValue.serverTimestamp(),
                            });
                            await _firestore.collection('activities').add({
                              'type': 'package_assigned',
                              'message': 'Package assigned to student',
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            Navigator.pop(context);
                            _showSnackBar('Package assigned successfully!');
                          } catch (e) {
                            _showSnackBar('Error: $e', isError: true);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.white),
                        child: const Text('Assign Package'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================
  void _showDeleteConfirmation(String packageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text('Delete Package', style: AppTextStyles.heading5.copyWith(color: AppColors.text)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this package? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('packages').doc(packageId).delete();
                await _firestore.collection('activities').add({
                  'type': 'package_deleted',
                  'message': 'Package deleted',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                _showSnackBar('Package deleted successfully!');
              } catch (e) {
                _showSnackBar('Error: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 2)),
        filled: true,
        fillColor: AppColors.card,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white))),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}