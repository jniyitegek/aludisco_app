import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _goalController;
  late TextEditingController _skillsController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  late TextEditingController _portfolioController;
  
  int _selectedAvatarIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppState>(context, listen: false).currentUser!;
    
    _nameController = TextEditingController(text: user.name);
    _bioController = TextEditingController(text: user.bio);
    _goalController = TextEditingController(text: user.goal);
    _skillsController = TextEditingController(text: user.skills.join(', '));
    _githubController = TextEditingController(text: user.github);
    _linkedinController = TextEditingController(text: user.linkedin);
    _portfolioController = TextEditingController(text: user.portfolio);
    _selectedAvatarIndex = user.avatarIndex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _goalController.dispose();
    _skillsController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final state = Provider.of<AppState>(context, listen: false);

    final skillsList = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await state.updateProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      skills: skillsList,
      goal: _goalController.text.trim(),
      github: _githubController.text.trim(),
      linkedin: _linkedinController.text.trim(),
      portfolio: _portfolioController.text.trim(),
      avatarIndex: _selectedAvatarIndex,
    );

    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: AppTheme.aluNavy)),
        actions: [
          _isSaving 
              ? const Center(child: Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.aluNavy))))
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.aluRed)),
                )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar selector
              Center(
                child: Column(
                  children: [
                    AppTheme.buildAvatar(_nameController.text.isNotEmpty ? _nameController.text : '?', _selectedAvatarIndex, radius: 40),
                    const SizedBox(height: 12),
                    const Text('Change Avatar Accent Color', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: 8,
                        itemBuilder: (context, idx) {
                          return InkWell(
                            onTap: () => setState(() => _selectedAvatarIndex = idx),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.getAvatarColor(idx),
                                border: Border.all(
                                  color: _selectedAvatarIndex == idx ? Colors.black : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter your name';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLength: 140,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Short Bio (max 140 characters)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a bio';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Goal
              TextFormField(
                controller: _goalController,
                decoration: InputDecoration(
                  labelText: 'Current Goal / Focus',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a goal';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Skills
              TextFormField(
                controller: _skillsController,
                decoration: InputDecoration(
                  labelText: 'Skills tags (comma separated)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter skills tags';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              
              const Text('Professional Directory Links', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.aluNavy)),
              const SizedBox(height: 12),

              // Github
              TextFormField(
                controller: _githubController,
                decoration: InputDecoration(
                  labelText: 'GitHub Profile Link',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 20),

              // Linkedin
              TextFormField(
                controller: _linkedinController,
                decoration: InputDecoration(
                  labelText: 'LinkedIn Profile Link',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 20),

              // Portfolio
              TextFormField(
                controller: _portfolioController,
                decoration: InputDecoration(
                  labelText: 'Portfolio Website Link',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
