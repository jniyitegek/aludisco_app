import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/space_model.dart';
import 'space_detail_screen.dart';

class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'work':
        return Icons.work_outline;
      case 'code':
        return Icons.code;
      case 'school':
        return Icons.school_outlined;
      case 'people':
        return Icons.people_outline;
      default:
        return Icons.group_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Spaces',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.aluNavy,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Join lightweight Reddit-style discussions in specialized ALU sub-communities.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              itemCount: state.spaces.length,
              itemBuilder: (context, index) {
                final space = state.spaces[index];
                return _buildSpaceCard(context, space, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceCard(BuildContext context, SpaceModel space, AppState state) {
    final isAlumniSpace = space.name == '#alumni-connect';
    final userRole = state.currentUser?.role ?? 'student';
    final hasAccess = !isAlumniSpace || userRole == 'alumni' || userRole == 'organizer';

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAlumniSpace ? AppTheme.aluRed.withOpacity(0.08) : AppTheme.aluNavy.withOpacity(0.08),
          child: Icon(
            _getIconData(space.iconName), 
            color: isAlumniSpace ? AppTheme.aluRed : AppTheme.aluNavy,
          ),
        ),
        title: Row(
          children: [
            Text(
              space.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.aluNavy),
            ),
            if (isAlumniSpace) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.aluRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ALUMNI ONLY',
                  style: TextStyle(color: AppTheme.aluRed, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            space.description,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
        onTap: () {
          if (hasAccess) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SpaceDetailScreen(space: space),
              ),
            );
          } else {
            _showAccessDeniedDialog(context);
          }
        },
      ),
    );
  }

  void _showAccessDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppTheme.aluRed),
            SizedBox(width: 10),
            Text('Restricted Access'),
          ],
        ),
        content: const Text(
          'The #alumni-connect space is reserved exclusively for ALU alumni. '
          'This helps maintain a dedicated network for mentorship, resume checks, and direct alumni referrals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
