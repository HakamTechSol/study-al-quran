import 'package:flutter/material.dart';
import 'package:studyalquran/utils/app_text_styles.dart';
import 'package:studyalquran/utils/color_constants.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today Section
          _buildDateHeader('Today'),
          const SizedBox(height: 12),
          
          _buildNotificationCard(
            icon: Icons.videocam,
            iconColor: AppColors.primary,
            title: 'Class Reminder',
            message: 'Your Quran class with Ustadh Ahmed starts in 15 minutes',
            time: '10:45 AM',
            isUnread: true,
          ),
          
          _buildNotificationCard(
            icon: Icons.assignment_turned_in,
            iconColor: Colors.green,
            title: 'Assignment Completed',
            message: 'Your Tajweed assignment has been marked complete',
            time: '9:30 AM',
            isUnread: true,
          ),

          const SizedBox(height: 24),
          
          // Yesterday Section
          _buildDateHeader('Yesterday'),
          const SizedBox(height: 12),
          
          _buildNotificationCard(
            icon: Icons.update,
            iconColor: AppColors.opposite,
            title: 'Class Rescheduled',
            message: 'Your session with Ustadh Ahmed has been rescheduled to tomorrow at 11:00 AM',
            time: '6:20 PM',
            isUnread: false,
          ),
          
          _buildNotificationCard(
            icon: Icons.star,
            iconColor: Colors.amber,
            title: 'Progress Update',
            message: 'Great job! You completed 5 lessons this week',
            time: '2:15 PM',
            isUnread: false,
          ),

          const SizedBox(height: 24),
          
          // Earlier Section
          _buildDateHeader('Earlier'),
          const SizedBox(height: 12),
          
          _buildNotificationCard(
            icon: Icons.cancel_outlined,
            iconColor: AppColors.redPrimary,
            title: 'Class Cancelled',
            message: 'Your class on Nov 20 has been cancelled. Makeup session available',
            time: 'Nov 20',
            isUnread: false,
          ),
          
          _buildNotificationCard(
            icon: Icons.book,
            iconColor: AppColors.primary,
            title: 'New Assignment',
            message: 'New Tajweed assignment has been added for you',
            time: 'Nov 18',
            isUnread: false,
          ),
          
          _buildNotificationCard(
            icon: Icons.notifications_active,
            iconColor: Colors.blue,
            title: 'Welcome to StudyAlQuran',
            message: 'Your account has been successfully created. Start your Quran learning journey today!',
            time: 'Nov 15',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  // Date Header
  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        date,
        style: AppTextStyles.heading4.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Notification Card
  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.primary.withOpacity(0.05) : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.subtitle,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.subtitle.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}