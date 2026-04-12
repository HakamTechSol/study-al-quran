import 'package:flutter/material.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 🔥 PACKAGE MODEL FOR SCHEDULE
class StudentPackage {
  final String id;
  final String name;
  final int totalSessions;
  final int remainingSessions;
  final DateTime expiryDate;
  final bool isActive;

  StudentPackage({
    required this.id,
    required this.name,
    required this.totalSessions,
    required this.remainingSessions,
    required this.expiryDate,
    required this.isActive,
  });

  factory StudentPackage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime expiryDate = DateTime.now();
    try {
      if (data['endDate'] != null) {
        expiryDate = (data['endDate'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Date parsing error: $e');
    }

    return StudentPackage(
      id: doc.id,
      name: data['packageName'] ?? 'Unknown Package',
      totalSessions: (data['numberOfClasses'] ?? 0).toInt(),
      remainingSessions:
          (data['remainingClasses'] ?? data['numberOfClasses'] ?? 0).toInt(),
      expiryDate: expiryDate,
      isActive:
          data['status'] == 'active' && expiryDate.isAfter(DateTime.now()),
    );
  }
}

// 🔥 SCHEDULE MODEL
class Schedule {
  final String id;
  final String teacherId;
  final String studentId;
  final String teacherName;
  final String studentName;
  final String date;
  final String time;
  final String duration;
  final String timezone;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? packageId;
  final String? packageName;

  Schedule({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.teacherName,
    required this.studentName,
    required this.date,
    required this.time,
    required this.duration,
    required this.timezone,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.packageId,
    this.packageName,
    // this.notes,
  });

  factory Schedule.fromFirestore(
    Map<String, dynamic> data,
    String id,
    String teacherName,
    String studentName,
  ) {
    return Schedule(
      id: id,
      teacherId: data['teacherId']?.toString() ?? '',
      studentId: data['studentId']?.toString() ?? '',
      teacherName: teacherName,
      studentName: studentName,
      date: data['date']?.toString() ?? '',
      time: data['time']?.toString() ?? '',
      duration: data['duration']?.toString() ?? '60 min',
      timezone: data['timezone']?.toString() ?? 'PKT (UTC+5)',
      status: data['status']?.toString() ?? 'Upcoming',
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
      packageId: data['packageId']?.toString(),
      packageName: data['packageName']?.toString(),
      // notes: data['notes']?.toString(),
    );
  }
}

// 🔥 TEACHER DROPDOWN MODEL
class TeacherDropdown {
  final String id;
  final String name;
  final String? timezone;

  TeacherDropdown({required this.id, required this.name, this.timezone});
}

// 🔥 STUDENT DROPDOWN MODEL
class StudentDropdown {
  final String id;
  final String name;
  final String? timezone;

  StudentDropdown({required this.id, required this.name, this.timezone});
}

// 🔥 ADD/EDIT SCHEDULE DIALOG - WITH TIMEZONE AUTO-ADJUSTMENT
class AddEditScheduleDialog extends StatefulWidget {
  final Schedule? schedule;
  final List<TeacherDropdown> availableTeachers;
  final List<StudentDropdown> availableStudents;
  final Function(String)? onPackageUpdate;
  final bool isReschedule;

  const AddEditScheduleDialog({
    super.key,
    this.schedule,
    required this.availableTeachers,
    required this.availableStudents,
    this.onPackageUpdate,
    this.isReschedule = false,
  });

  @override
  State<AddEditScheduleDialog> createState() => _AddEditScheduleDialogState();
}

class _AddEditScheduleDialogState extends State<AddEditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedTeacherId;
  String? _selectedStudentId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedDuration = '60 min';
  String _selectedTimezone = 'PKT (UTC+5)';
  final _notesController = TextEditingController();
  bool _isLoading = false;

  // Packages related variables
  List<StudentPackage> _availablePackages = [];
  String? _selectedPackageId;
  bool _isLoadingPackages = false;

  final List<String> durations = [
    '30 min',
    '45 min',
    '60 min',
    '90 min',
    '120 min',
  ];
  final List<String> timezones = [
    'PKT (UTC+5)',
    'GST (UTC+4)',
    'EST (UTC-5)',
    'PST (UTC-8)',
    'GMT (UTC+0)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTeacherId =
        widget.schedule?.teacherId ??
        (widget.availableTeachers.isNotEmpty
            ? widget.availableTeachers.first.id
            : null);
    _selectedStudentId =
        widget.schedule?.studentId ??
        (widget.availableStudents.isNotEmpty
            ? widget.availableStudents.first.id
            : null);
    _selectedDuration = widget.schedule?.duration ?? '60 min';
    _selectedTimezone = widget.schedule?.timezone ?? 'PKT (UTC+5)';
    // _notesController.text = widget.schedule?.notes ?? '';

    // Parse existing date and time
    if (widget.schedule != null) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.schedule!.date);

        // Parse time like "2:30 PM"
        final timeParts = widget.schedule!.time.split(' ');
        if (timeParts.length == 2) {
          final timeValue = timeParts[0].split(':');
          final period = timeParts[1];
          if (timeValue.length == 2) {
            int hour = int.parse(timeValue[0]);
            final minute = int.parse(timeValue[1]);

            if (period == 'PM' && hour != 12) hour += 12;
            if (period == 'AM' && hour == 12) hour = 0;

            _selectedTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
      } catch (e) {
        print('Error parsing existing date/time: $e');
      }
    }

    if (_selectedStudentId != null) {
      _loadStudentPackages(_selectedStudentId!);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentPackages(String studentId) async {
    setState(() => _isLoadingPackages = true);

    try {
      final packages = await _getStudentPackages(studentId);
      setState(() {
        _availablePackages = packages;
        if (packages.isNotEmpty) {
          _selectedPackageId = widget.schedule?.packageId ?? packages.first.id;
        }
      });
    } catch (e) {
      print('Error loading packages: $e');
    } finally {
      setState(() => _isLoadingPackages = false);
    }
  }

  Future<List<StudentPackage>> _getStudentPackages(String studentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('packageAssignments')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'active')
          .get();

      List<StudentPackage> packages = snapshot.docs
          .map((doc) => StudentPackage.fromFirestore(doc))
          .toList();

      return packages
          .where((package) => package.isActive && package.remainingSessions > 0)
          .toList();
    } catch (e) {
      print('Error fetching student packages: $e');
      return [];
    }
  }

  // 🔥 AUTO-ADJUST TIMEZONE BASED ON TEACHER AND STUDENT
  void _autoAdjustTimezone() {
    if (_selectedTeacherId != null && _selectedStudentId != null) {
      final teacher = widget.availableTeachers.firstWhere(
        (t) => t.id == _selectedTeacherId,
        orElse: () => TeacherDropdown(id: '', name: ''),
      );

      final student = widget.availableStudents.firstWhere(
        (s) => s.id == _selectedStudentId,
        orElse: () => StudentDropdown(id: '', name: ''),
      );

      // Simple timezone adjustment logic
      // In a real app, you'd use a proper timezone conversion library
      if (teacher.timezone != null && student.timezone != null) {
        setState(() {
          _selectedTimezone =
              teacher.timezone!; // Use teacher's timezone as default
        });
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null ||
        _selectedStudentId == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hour = _selectedTime!.hourOfPeriod;
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
      final formattedTime = '$hour:$minute $period';

      final formattedDate =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      // String zoomLink = _zoomLinkController.text.trim();
      // if (zoomLink.isEmpty) {
      //   zoomLink = 'https://zoom.us/j/${DateTime.now().millisecondsSinceEpoch}';
      // }

      String packageName = 'No Package';
      if (_selectedPackageId != null) {
        final selectedPackage = _availablePackages.firstWhere(
          (pkg) => pkg.id == _selectedPackageId,
          orElse: () => StudentPackage(
            id: '',
            name: 'No Package',
            totalSessions: 0,
            remainingSessions: 0,
            expiryDate: DateTime.now(),
            isActive: false,
          ),
        );
        packageName = selectedPackage.name;
      }

      final scheduleData = {
        'teacherId': _selectedTeacherId,
        'studentId': _selectedStudentId,

        'date': formattedDate, // Local date string (for display)
        'time': formattedTime, // Local time string (for display)
        // 🔥 YEH NAYI FIELD ADD KARO
        'scheduledAt': Timestamp.fromDate(
          DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          ).toUtc(),
        ),

        'duration': _selectedDuration,
        'timezone': _selectedTimezone,
        // 'zoomLink': zoomLink,
        'status': widget.isReschedule
            ? 'Upcoming'
            : (widget.schedule?.status ?? 'Upcoming'),
        'packageId': _selectedPackageId,
        'packageName': packageName,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.schedule != null) {
        await _firestore
            .collection('schedules')
            .doc(widget.schedule!.id)
            .update(scheduleData);
      } else {
        scheduleData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('schedules').add(scheduleData);
      }

      if (_selectedPackageId != null &&
          widget.onPackageUpdate != null &&
          widget.schedule == null) {
        widget.onPackageUpdate!(_selectedPackageId!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar(
        widget.isReschedule
            ? 'Class rescheduled successfully!'
            : 'Class scheduled successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teacher *',
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTeacherId,
              isExpanded: true,
              hint: Text(
                'Select Teacher',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
              items: widget.availableTeachers.map((teacher) {
                return DropdownMenuItem<String>(
                  value: teacher.id,
                  child: Text(teacher.name, style: AppTextStyles.bodyMedium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTeacherId = newValue;
                  _autoAdjustTimezone();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student *',
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStudentId,
              isExpanded: true,
              hint: Text(
                'Select Student',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
              items: widget.availableStudents.map((student) {
                return DropdownMenuItem<String>(
                  value: student.id,
                  child: Text(student.name, style: AppTextStyles.bodyMedium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStudentId = newValue;
                  if (newValue != null) {
                    _loadStudentPackages(newValue);
                  }
                  _autoAdjustTimezone();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Package (Optional)',
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: _isLoadingPackages
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading packages...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPackageId,
                    isExpanded: true,
                    hint: Text(
                      'Select Package',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.subtitle,
                      ),
                    ),
                    items: _availablePackages.map((package) {
                      return DropdownMenuItem<String>(
                        value: package.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(package.name, style: AppTextStyles.bodyMedium),
                            Text(
                              '${package.remainingSessions}/${package.totalSessions} sessions - Expires ${DateFormat('MMM dd, yyyy').format(package.expiryDate)}',
                              style: AppTextStyles.captionText.copyWith(
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPackageId = newValue;
                      });
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date *',
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null && picked != _selectedDate) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppColors.subtitle),
                const SizedBox(width: 8),
                Text(
                  _selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                      : 'Select Date',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _selectedDate != null
                        ? AppColors.text
                        : AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time *',
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
            );
            if (picked != null && picked != _selectedTime) {
              setState(() => _selectedTime = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: AppColors.subtitle),
                const SizedBox(width: 8),
                Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Select Time',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _selectedTime != null
                        ? AppColors.text
                        : AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDuration,
              isExpanded: true,
              items: durations.map((duration) {
                return DropdownMenuItem<String>(
                  value: duration,
                  child: Text(duration, style: AppTextStyles.bodyMedium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() => _selectedDuration = newValue!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timezone',
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTimezone,
              isExpanded: true,
              items: timezones.map((timezone) {
                return DropdownMenuItem<String>(
                  value: timezone,
                  child: Text(timezone, style: AppTextStyles.bodyMedium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() => _selectedTimezone = newValue!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelText.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              prefixIcon: Icon(icon, size: 18, color: AppColors.subtitle),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.schedule != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.isReschedule
                                ? Icons.schedule
                                : (isEdit
                                      ? Icons.edit_calendar
                                      : Icons.add_box),
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.isReschedule
                              ? 'Reschedule Class'
                              : (isEdit
                                    ? 'Edit Schedule'
                                    : 'Schedule New Class'),
                          style: AppTextStyles.heading5.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ✅ SCROLLABLE CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Teacher & Student Row
                        Row(
                          children: [
                            Expanded(child: _buildTeacherDropdown()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStudentDropdown()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Package Selection
                        if (_selectedStudentId != null) _buildPackageDropdown(),
                        if (_selectedStudentId != null)
                          const SizedBox(height: 16),

                        // Date & Time Row
                        Row(
                          children: [
                            Expanded(child: _buildDateField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTimeField()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Duration & Timezone Row
                        Row(
                          children: [
                            Expanded(child: _buildDurationDropdown()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTimezoneDropdown()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // // Zoom Link
                        // _buildTextField(
                        //   controller: _zoomLinkController,
                        //   label: 'Zoom Meeting Link (Optional)',
                        //   icon: Icons.videocam,
                        // ),
                        const SizedBox(height: 16),

                        // // Notes
                        // _buildTextField(
                        //   controller: _notesController,
                        //   label: 'Special Notes (Optional)',
                        //   icon: Icons.note,
                        //   maxLines: 3,
                        // ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ ACTION BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.subtitle),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              widget.isReschedule
                                  ? 'Reschedule Class'
                                  : (isEdit
                                        ? 'Update Schedule'
                                        : 'Schedule Class'),
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
}

// Main Schedule Management Screen
class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String searchQuery = '';
  String _selectedTab = 'Upcoming';
  DateTime? _selectedCalendarDate;
  bool _showCalendar = false;

  // 🔥 OPTIMIZED STREAM: Cached teacher and student data
  final Map<String, String> _teacherCache = {};
  final Map<String, String> _studentCache = {};

  // 🔥 STREAM: Optimized real-time schedules data
  Stream<List<Schedule>> getSchedulesStream() {
    return _firestore
        .collection('schedules')
        .orderBy('date', descending: false)
        .orderBy('time', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Schedule> schedules = [];

          // Pre-fetch all teachers and students
          await _prefetchTeachersAndStudents();

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data();

            // Get teacher name from cache
            String teacherName =
                _teacherCache[data['teacherId']] ?? 'Unknown Teacher';

            // Get student name from cache
            String studentName =
                _studentCache[data['studentId']] ?? 'Unknown Student';

            schedules.add(
              Schedule.fromFirestore(data, doc.id, teacherName, studentName),
            );
          }

          return schedules;
        });
  }

  // 🔥 PRE-FETCH TEACHERS AND STUDENTS FOR BETTER PERFORMANCE
  Future<void> _prefetchTeachersAndStudents() async {
    if (_teacherCache.isEmpty) {
      try {
        final teachersSnapshot = await _firestore.collection('teachers').get();
        for (var doc in teachersSnapshot.docs) {
          _teacherCache[doc.id] = doc.data()['name'] ?? 'Unknown Teacher';
        }
      } catch (e) {
        print('Error prefetching teachers: $e');
      }
    }

    if (_studentCache.isEmpty) {
      try {
        final studentsSnapshot = await _firestore.collection('students').get();
        for (var doc in studentsSnapshot.docs) {
          _studentCache[doc.id] = doc.data()['name'] ?? 'Unknown Student';
        }
      } catch (e) {
        print('Error prefetching students: $e');
      }
    }
  }

  // 🔥 GET TEACHERS LIST FOR DROPDOWN
  Future<List<TeacherDropdown>> getTeachersList() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('teachers').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return TeacherDropdown(
          id: doc.id,
          name: data['name'] ?? 'Unknown Teacher',
          timezone: data['timezone'] ?? 'PKT (UTC+5)',
        );
      }).toList();
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
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
          timezone: data['timezone'] ?? 'PKT (UTC+5)',
        );
      }).toList();
    } catch (e) {
      print('Error fetching students: $e');
      return [];
    }
  }

  // 🔥 DELETE SCHEDULE
  Future<void> _deleteSchedule(String scheduleId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text('Delete Schedule', style: AppTextStyles.heading5),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this scheduled class?',
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
                await _firestore
                    .collection('schedules')
                    .doc(scheduleId)
                    .delete();
                Navigator.pop(context);
                _showSnackBar('Schedule deleted successfully');
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  // 🔥 UPDATE SCHEDULE STATUS
  Future<void> _updateScheduleStatus(String scheduleId, String status) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Status updated to $status');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // 🔥 RESCHEDULE CLASS
  Future<void> _rescheduleClass(Schedule schedule) async {
    List<TeacherDropdown> teachers = await getTeachersList();
    List<StudentDropdown> students = await getStudentsList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AddEditScheduleDialog(
        schedule: schedule,
        availableTeachers: teachers,
        availableStudents: students,
        onPackageUpdate: _updatePackageSessions,
        isReschedule: true,
      ),
    );
  }

  void _showAddEditDialog({Schedule? schedule}) async {
    List<TeacherDropdown> teachers = await getTeachersList();
    List<StudentDropdown> students = await getStudentsList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AddEditScheduleDialog(
        schedule: schedule,
        availableTeachers: teachers,
        availableStudents: students,
        onPackageUpdate: _updatePackageSessions,
      ),
    );
  }

  // 🔥 UPDATE PACKAGE SESSIONS WHEN SCHEDULE IS CREATED
  Future<void> _updatePackageSessions(String packageId) async {
    try {
      DocumentSnapshot packageDoc = await _firestore
          .collection('packageAssignments')
          .doc(packageId)
          .get();

      if (packageDoc.exists) {
        Map<String, dynamic> data = packageDoc.data() as Map<String, dynamic>;
        int currentRemaining = (data['remainingClasses'] ?? 0).toInt();

        if (currentRemaining > 0) {
          await _firestore
              .collection('packageAssignments')
              .doc(packageId)
              .update({
                'remainingClasses': currentRemaining - 1,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        }
      }
    } catch (e) {
      print('Error updating package sessions: $e');
    }
  }

  List<Schedule> filterSchedules(List<Schedule> schedules) {
    List<Schedule> filtered = schedules
        .where((schedule) => schedule.status == _selectedTab)
        .toList();

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        return schedule.teacherName.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            schedule.studentName.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
      }).toList();
    }

    if (_selectedCalendarDate != null) {
      filtered = filtered.where((schedule) {
        try {
          final scheduleDate = DateFormat('yyyy-MM-dd').parse(schedule.date);
          return scheduleDate.year == _selectedCalendarDate!.year &&
              scheduleDate.month == _selectedCalendarDate!.month &&
              scheduleDate.day == _selectedCalendarDate!.day;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    return filtered;
  }

  // 🔥 GET TIMEZONE OFFSET
  String _getTimezoneOffset(String timezone) {
    switch (timezone) {
      case 'PKT (UTC+5)':
        return '+5';
      case 'GST (UTC+4)':
        return '+4';
      case 'EST (UTC-5)':
        return '-5';
      case 'PST (UTC-8)':
        return '-8';
      case 'GMT (UTC+0)':
        return '+0';
      default:
        return '+5';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HEADER
            _buildHeader(),
            const SizedBox(height: 28),

            // ✅ TABS FOR DIFFERENT STATUS
            _buildStatusTabs(),
            const SizedBox(height: 24),

            // ✅ SEARCH AND FILTERS
            _buildSearchAndFilter(),
            const SizedBox(height: 24),

            // 🔥 CONTENT WITH OPTIMIZED STREAM BUILDER
            Expanded(
              child: StreamBuilder<List<Schedule>>(
                stream: getSchedulesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  final schedules = snapshot.data ?? [];
                  final filteredSchedules = filterSchedules(schedules);

                  return _buildSchedulesContent(filteredSchedules);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading schedules...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading schedules',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _teacherCache.clear();
              _studentCache.clear();
              setState(() {});
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ✅ HEADER
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Management',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.text,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage class schedules and sessions',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.subtitle,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (_showCalendar) ...[
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _selectedCalendarDate = null;
                  _showCalendar = false;
                }),
                icon: Icon(Icons.list, size: 18),
                label: Text('List View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.text,
                ),
              ),
              const SizedBox(width: 12),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => setState(() => _showCalendar = true),
                icon: Icon(Icons.calendar_today, size: 18),
                label: Text('Calendar View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.text,
                ),
              ),
              const SizedBox(width: 12),
            ],
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Schedule Class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ STATUS TABS
  Widget _buildStatusTabs() {
    final List<String> tabs = ['Upcoming', 'Completed', 'Missed', 'Cancelled'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = tab),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.text,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ✅ SEARCH AND FILTER
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
                hintText: 'Search by teacher or student...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.subtitle,
                ),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: AppColors.subtitle),
              ),
            ),
          ),
        ),
        if (_showCalendar) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  _selectedCalendarDate != null
                      ? DateFormat(
                          'MMM dd, yyyy',
                        ).format(_selectedCalendarDate!)
                      : 'Select Date',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _selectedCalendarDate != null
                        ? AppColors.text
                        : AppColors.subtitle,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.clear, size: 18),
                  onPressed: _selectedCalendarDate != null
                      ? () => setState(() => _selectedCalendarDate = null)
                      : null,
                  color: AppColors.subtitle,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSchedulesContent(List<Schedule> filteredSchedules) {
    if (_showCalendar) {
      return _buildCalendarView(filteredSchedules);
    } else {
      return _buildListView(filteredSchedules);
    }
  }

  // ✅ SCHEDULES LIST - GRID VIEW
  Widget _buildListView(List<Schedule> filteredSchedules) {
    if (filteredSchedules.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.15,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: filteredSchedules.length,
      itemBuilder: (context, index) {
        final schedule = filteredSchedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  // ✅ CALENDAR VIEW
  Widget _buildCalendarView(List<Schedule> filteredSchedules) {
    return Column(
      children: [
        // Calendar Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCalendarDate != null
                    ? DateFormat('MMMM yyyy').format(_selectedCalendarDate!)
                    : DateFormat('MMMM yyyy').format(DateTime.now()),
                style: AppTextStyles.heading5,
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      if (_selectedCalendarDate != null) {
                        _selectedCalendarDate = DateTime(
                          _selectedCalendarDate!.year,
                          _selectedCalendarDate!.month - 1,
                          1,
                        );
                      }
                    }),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedCalendarDate = DateTime.now()),
                    child: Text('Today'),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: () => setState(() {
                      if (_selectedCalendarDate != null) {
                        _selectedCalendarDate = DateTime(
                          _selectedCalendarDate!.year,
                          _selectedCalendarDate!.month + 1,
                          1,
                        );
                      }
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildCalendarGrid(filteredSchedules)),
      ],
    );
  }

  Widget _buildCalendarGrid(List<Schedule> schedules) {
    final now = _selectedCalendarDate ?? DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    List<Widget> calendarDays = [];

    // Add day headers
    for (int i = 0; i < 7; i++) {
      calendarDays.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Text(
            DateFormat('E').format(DateTime(2023, 1, i + 1)),
            style: AppTextStyles.labelText.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Add empty days for the first week
    for (int i = 0; i < firstDay.weekday - 1; i++) {
      calendarDays.add(Container());
    }

    // Add days of the month
    for (int day = 1; day <= lastDay.day; day++) {
      final currentDate = DateTime(now.year, now.month, day);
      final daySchedules = schedules.where((schedule) {
        try {
          final scheduleDate = DateFormat('yyyy-MM-dd').parse(schedule.date);
          return scheduleDate.year == currentDate.year &&
              scheduleDate.month == currentDate.month &&
              scheduleDate.day == currentDate.day;
        } catch (e) {
          return false;
        }
      }).toList();

      calendarDays.add(
        InkWell(
          onTap: () => setState(() => _selectedCalendarDate = currentDate),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    _selectedCalendarDate?.day == day &&
                        _selectedCalendarDate?.month == now.month
                    ? AppColors.primary
                    : AppColors.border,
                width:
                    _selectedCalendarDate?.day == day &&
                        _selectedCalendarDate?.month == now.month
                    ? 2
                    : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color:
                  day == DateTime.now().day && now.month == DateTime.now().month
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (daySchedules.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...daySchedules
                      .take(2)
                      .map(
                        (schedule) => Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              schedule.status,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${schedule.time} - ${schedule.studentName.split(' ').first}',
                            style: AppTextStyles.captionText.copyWith(
                              color: _getStatusColor(schedule.status),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  if (daySchedules.length > 2)
                    Text(
                      '+${daySchedules.length - 2} more',
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.subtitle,
                        fontSize: 8,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
      ),
      itemCount: calendarDays.length,
      itemBuilder: (context, index) => calendarDays[index],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: AppColors.subtitle),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedTab.toLowerCase()} classes found',
            style: AppTextStyles.heading5.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTab == 'Upcoming'
                ? 'Schedule your first class to get started'
                : 'No ${_selectedTab.toLowerCase()} classes available',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.subtitle),
          ),
          if (_selectedCalendarDate != null || searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCalendarDate = null;
                  searchQuery = '';
                });
              },
              child: Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ SCHEDULE CARD
  Widget _buildScheduleCard(Schedule schedule) {
    Color statusColor = _getStatusColor(schedule.status);
    IconData statusIcon = _getStatusIcon(schedule.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: schedule.status == 'Upcoming'
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border.withOpacity(0.5),
          width: schedule.status == 'Upcoming' ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ HEADER WITH STATUS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
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
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.status.toUpperCase(),
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

          // ✅ CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Teacher → Student
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              schedule.teacherName,
                              style: AppTextStyles.labelText.copyWith(
                                color: AppColors.text,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: AppColors.subtitle,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              schedule.studentName,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.subtitle,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Date, Time & Package Info
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppColors.subtitle,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.date,
                            style: AppTextStyles.captionText.copyWith(
                              color: AppColors.subtitle,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.subtitle,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${schedule.time} (${schedule.duration})',
                            style: AppTextStyles.captionText.copyWith(
                              color: AppColors.subtitle,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (schedule.packageName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                schedule.packageName!,
                                style: AppTextStyles.captionText.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
                      //   const SizedBox(height: 4),
                      //   Row(
                      //     children: [
                      //       Icon(Icons.note, size: 12, color: AppColors.opposite),
                      //       const SizedBox(width: 4),
                      //       Expanded(
                      //         child: Text(
                      //           schedule.notes!,
                      //           style: AppTextStyles.captionText.copyWith(
                      //             color: AppColors.opposite,
                      //             fontSize: 10,
                      //           ),
                      //           maxLines: 1,
                      //           overflow: TextOverflow.ellipsis,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ✅ ACTION BUTTONS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                if (schedule.status == 'Upcoming')
                  // Expanded(
                  //   child: SizedBox(
                  //     height: 36,
                  //     child: OutlinedButton.icon(
                  //       // onPressed: () {
                  //       //   _showSnackBar('Opening Zoom meeting...');
                  //       // },
                  //       icon: const Icon(Icons.videocam, size: 14),
                  //       label: const Text('Join'),
                  //       style: OutlinedButton.styleFrom(
                  //         foregroundColor: AppColors.primary,
                  //         side: BorderSide(color: AppColors.primary),
                  //         padding: const EdgeInsets.symmetric(vertical: 4),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  if (schedule.status == 'Upcoming') const SizedBox(width: 6),
                SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                    onPressed: () => _showScheduleDetails(schedule),
                    icon: Icon(Icons.visibility_outlined, size: 16),
                    color: AppColors.primary,
                    tooltip: 'View',
                    padding: EdgeInsets.zero,
                  ),
                ),
                if (schedule.status == 'Upcoming')
                  SizedBox(
                    height: 36,
                    width: 36,
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: AppColors.subtitle,
                      ),
                      padding: EdgeInsets.zero,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'reschedule',
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reschedule',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'completed',
                          child: Row(
                            children: [
                              Icon(Icons.check, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Mark Completed',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'missed',
                          child: Row(
                            children: [
                              Icon(Icons.close, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Mark Missed',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cancelled',
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cancel Class',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'reschedule') {
                          _rescheduleClass(schedule);
                        } else if (value == 'completed') {
                          _updateScheduleStatus(schedule.id, 'Completed');
                        } else if (value == 'missed') {
                          _updateScheduleStatus(schedule.id, 'Missed');
                        } else if (value == 'cancelled') {
                          _updateScheduleStatus(schedule.id, 'Cancelled');
                        }
                      },
                    ),
                  ),
                SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                    onPressed: () => _deleteSchedule(schedule.id),
                    icon: Icon(Icons.delete_outline, size: 16),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Missed':
        return Colors.red;
      case 'Cancelled':
        return Colors.orange;
      default:
        return AppColors.subtitle;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Upcoming':
        return Icons.schedule;
      case 'Completed':
        return Icons.check_circle;
      case 'Missed':
        return Icons.cancel;
      case 'Cancelled':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  void _showScheduleDetails(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event_note, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text('Class Details', style: AppTextStyles.heading5),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Teacher', schedule.teacherName),
              _buildDetailRow('Student', schedule.studentName),
              _buildDetailRow('Date', schedule.date),
              _buildDetailRow(
                'Time',
                '${schedule.time} (${schedule.duration})',
              ),
              _buildDetailRow('Timezone', schedule.timezone),
              _buildDetailRow('Status', schedule.status),
              if (schedule.packageName != null)
                _buildDetailRow('Package', schedule.packageName!),
              // if (schedule.zoomLink != null)
              //   _buildDetailRow('Zoom Link', schedule.zoomLink!),
              // if (schedule.notes != null && schedule.notes!.isNotEmpty)
              //   _buildDetailRow('Notes', schedule.notes!),
            ],
          ),
        ),
        actions: [
          if (schedule.status == 'Upcoming') ...[
            TextButton(
              onPressed: () => _rescheduleClass(schedule),
              child: Text(
                'Reschedule',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.subtitle)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.labelText.copyWith(
              color: AppColors.text,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
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
