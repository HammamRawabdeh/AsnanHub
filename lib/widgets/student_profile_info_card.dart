import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/widgets/profile_info_row.dart';
import 'package:flutter/material.dart';

class StudentProfileInfoCard extends StatelessWidget {
  final StudentUser user;

  const StudentProfileInfoCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var scheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: user.name,
            ),
            const Divider(),
            ProfileInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            const Divider(),
            ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              value: user.phone,
            ),
            const Divider(),
            ProfileInfoRow(
              icon: Icons.school_outlined,
              label: 'University ID',
              value: user.universityId.isNotEmpty
                  ? user.universityId
                  : 'Not provided',
            ),
            const Divider(),
            ProfileInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Year',
              value: '${user.year}th Year',
            ),
            const Divider(),
            ProfileInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Cases Completed',
              value: user.casesCompleted.toString(),
            ),
            const Divider(),
            ProfileInfoRow(
              icon: Icons.wc_outlined,
              label: 'Gender',
              value: user.gender.isEmpty
                  ? 'Not specified'
                  : user.gender[0].toUpperCase() + user.gender.substring(1),
            ),
          ],
        ),
      ),
    );
  }
}


