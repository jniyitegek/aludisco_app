import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../data/models/user_model.dart';
import '../main_navigation.dart';

class SetupProfileScreen extends StatefulWidget {
  final String email;

  const SetupProfileScreen({super.key, required this.email});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  int _currentStep = 0;

  // Step 1: Role & Info
  String _role = 'student'; // 'student' or 'alumni'
  final _cohortController = TextEditingController();
  final _gradYearController = TextEditingController();
  final _currentYearController = TextEditingController();
  final _majorController = TextEditingController();

  // Step 2: Bio, Goal, Avatar
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _goalController = TextEditingController();
  int _selectedAvatarIndex = 0;

  // Step 3: Skills & Links
  final _skillsController = TextEditingController(); // Comma-separated or chips list
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _portfolioController = TextEditingController();

  final _formKeyRole = GlobalKey<FormState>();
  final _formKeyBio = GlobalKey<FormState>();
  final _formKeySkills = GlobalKey<FormState>();

  @override
  void dispose() {
    _cohortController.dispose();
    _gradYearController.dispose();
    _currentYearController.dispose();
    _majorController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _goalController.dispose();
    _skillsController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKeyRole.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      if (_formKeyBio.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKeySkills.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);

    final user = UserModel(
      email: widget.email,
      name: _nameController.text.trim(),
      role: _role,
      bio: _bioController.text.trim(),
      skills: _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      goal: _goalController.text.trim(),
      github: _githubController.text.trim(),
      linkedin: _linkedinController.text.trim(),
      portfolio: _portfolioController.text.trim(),
      avatarIndex: _selectedAvatarIndex,
      graduationYear: _role == 'alumni' ? int.tryParse(_gradYearController.text) : null,
      cohort: _role == 'alumni' ? _cohortController.text.trim() : null,
      currentYear: _role == 'student' ? int.tryParse(_currentYearController.text) : null,
      major: _role == 'student' ? _majorController.text.trim() : null,
      isVerified: true,
    );

    await appState.signup(user);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Up Profile',
          style: TextStyle(color: AppTheme.aluNavy, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.aluNavy),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            _buildStepIndicator(),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildStepContent(),
                ),
              ),
            ),
            
            // Bottom Action buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: AppTheme.aluNavy),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Back', style: TextStyle(color: AppTheme.aluNavy)),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep < 2 ? _nextStep : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppTheme.aluNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _currentStep < 2 ? 'Continue' : 'Complete Setup',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          return Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isCompleted
                    ? Colors.green
                    : (isActive ? AppTheme.aluNavy : AppTheme.borderLight),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (index < 2)
                Container(
                  width: 50,
                  height: 3,
                  color: isCompleted ? Colors.green : AppTheme.borderLight,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepRoleSelection();
      case 1:
        return _buildStepBioAvatar();
      case 2:
        return _buildStepSkillsLinks();
      default:
        return Container();
    }
  }

  // STEP 1 CONTENT: Role Selection & details
  Widget _buildStepRoleSelection() {
    return Form(
      key: _formKeyRole,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What is your role at ALU?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.aluNavy),
          ),
          const SizedBox(height: 16),
          
          // Role Selection Radio Cards
          Row(
            children: [
              Expanded(
                child: _buildRoleCard('Student', 'student', Icons.school),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard('Alumni', 'alumni', Icons.workspace_premium),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          if (_role == 'student') ...[
            TextFormField(
              controller: _currentYearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Current Study Year (e.g., 1, 2, 3)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter current year';
                final year = int.tryParse(val.trim());
                if (year == null || year < 1 || year > 5) return 'Enter a valid year (1-5)';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _majorController,
              decoration: InputDecoration(
                labelText: 'Major / Study Track',
                hintText: 'e.g. Software Engineering',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter your major';
                return null;
              },
            ),
          ] else ...[
            TextFormField(
              controller: _gradYearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Graduation Year',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter graduation year';
                final year = int.tryParse(val.trim());
                if (year == null || year < 2015 || year > 2030) return 'Enter a valid graduation year';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _cohortController,
              decoration: InputDecoration(
                labelText: 'Cohort (e.g., Cohort 4, Rwanda)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter cohort details';
                return null;
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRoleCard(String title, String val, IconData icon) {
    final isSelected = _role == val;
    return InkWell(
      onTap: () => setState(() => _role = val),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.aluNavy.withOpacity(0.06) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.aluNavy : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? AppTheme.aluNavy : AppTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.aluNavy : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2 CONTENT: Profile Bio, Goal, Avatar selector
  Widget _buildStepBioAvatar() {
    return Form(
      key: _formKeyBio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who are you?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.aluNavy),
          ),
          const SizedBox(height: 20),
          
          // Avatar selector
          Center(
            child: Column(
              children: [
                AppTheme.buildAvatar(_nameController.text.isNotEmpty ? _nameController.text : '?', _selectedAvatarIndex, radius: 40),
                const SizedBox(height: 12),
                const Text('Choose Avatar Color', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
          const SizedBox(height: 24),
          
          // Full name input
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
          
          // Bio input (140 chars constraint)
          TextFormField(
            controller: _bioController,
            maxLength: 140,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Short Bio (max 140 characters)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please tell us a bit about yourself';
              return null;
            },
          ),
          const SizedBox(height: 8),
          
          // Goal input
          TextFormField(
            controller: _goalController,
            decoration: InputDecoration(
              labelText: 'Current Goal / Focus',
              hintText: 'e.g. Looking for fintech internships',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter a goal';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // STEP 3 CONTENT: Skills tags & Links
  Widget _buildStepSkillsLinks() {
    return Form(
      key: _formKeySkills,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills & Professional Links',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.aluNavy),
          ),
          const SizedBox(height: 20),
          
          // Skills input
          TextFormField(
            controller: _skillsController,
            decoration: InputDecoration(
              labelText: 'Skills tags (comma separated)',
              hintText: 'e.g. Flutter, Figma, Leadership, Python',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.tag_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter at least one skill tag';
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Links Inputs
          TextFormField(
            controller: _githubController,
            decoration: InputDecoration(
              labelText: 'GitHub Profile Link (Optional)',
              hintText: 'github.com/username',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.code),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _linkedinController,
            decoration: InputDecoration(
              labelText: 'LinkedIn Profile Link (Optional)',
              hintText: 'linkedin.com/in/username',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _portfolioController,
            decoration: InputDecoration(
              labelText: 'Portfolio Website Link (Optional)',
              hintText: 'myportfolio.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.language),
            ),
          ),
        ],
      ),
    );
  }
}
