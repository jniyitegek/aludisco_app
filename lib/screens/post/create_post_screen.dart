import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class CreatePostScreen extends StatefulWidget {
  final String initialType; // 'achievement' or 'opportunity'

  const CreatePostScreen({super.key, this.initialType = 'achievement'});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _postType; // 'achievement' or 'opportunity'
  
  // Common Fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedSpaceId;

  // Achievement Fields
  String _achievementCategory = 'Career Win';
  final List<String> _achievementCategories = [
    'Career Win',
    'Project Launch',
    'Skill Unlocked',
    'Leadership',
    'Community'
  ];

  // Opportunity Fields
  String _opportunityType = 'Event';
  final List<String> _opportunityTypes = [
    'Event',
    'Hackathon',
    'Workshop',
    'Internship',
    'Announcement'
  ];
  DateTime? _eventDateTime;
  final _locationController = TextEditingController();
  final _registrationLinkController = TextEditingController();
  bool _inAppRsvp = true;
  final _targetAudienceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _postType = widget.initialType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _registrationLinkController.dispose();
    _targetAudienceController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime == null) return;

    setState(() {
      _eventDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_postType == 'opportunity' && _eventDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event date & time.')),
      );
      return;
    }

    final state = Provider.of<AppState>(context, listen: false);

    await state.createPost(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      type: _postType,
      category: _postType == 'achievement' ? _achievementCategory : _opportunityType,
      spaceId: _selectedSpaceId,
      eventDate: _eventDateTime,
      eventLocation: _postType == 'opportunity' ? _locationController.text.trim() : null,
      registrationLink: _postType == 'opportunity' ? _registrationLinkController.text.trim() : null,
      inAppRsvp: _postType == 'opportunity' ? _inAppRsvp : false,
      targetAudience: _postType == 'opportunity' 
          ? _targetAudienceController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : [],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_postType == 'achievement' ? 'Milestone shared!' : 'Opportunity posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isOrganizer = state.currentUser?.role == 'organizer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post', style: TextStyle(color: AppTheme.aluNavy)),
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.aluRed)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Selector Tab (Only if user is organizer)
              if (isOrganizer) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton('Achievement', 'achievement'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton('Opportunity', 'opportunity'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
              // 2. Common title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _postType == 'achievement' ? 'Milestone Title' : 'Opportunity Title',
                  hintText: _postType == 'achievement' ? 'e.g. Got accepted to Google Summer of Code' : 'e.g. UI/UX Design Workshop',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a title';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 3. Category drop-downs
              if (_postType == 'achievement') ...[
                DropdownButtonFormField<String>(
                  value: _achievementCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _achievementCategories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _achievementCategory = val);
                  },
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: _opportunityType,
                  decoration: InputDecoration(
                    labelText: 'Opportunity Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _opportunityTypes.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _opportunityType = val);
                  },
                ),
              ],
              const SizedBox(height: 20),

              // 4. Space Selector (cross-posting)
              DropdownButtonFormField<int?>(
                value: _selectedSpaceId,
                decoration: InputDecoration(
                  labelText: 'Post in Space (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.tag),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Global Feed Only')),
                  ...state.spaces.map((s) {
                    return DropdownMenuItem<int?>(value: s.id, child: Text(s.name));
                  }),
                ],
                onChanged: (val) => setState(() => _selectedSpaceId = val),
              ),
              const SizedBox(height: 20),

              // 5. Description field
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description / Details',
                  hintText: 'Share more details about this...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a description';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 6. Opportunity Specific Form Fields
              if (_postType == 'opportunity') ...[
                // Event DateTime selector
                InkWell(
                  onTap: _selectDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _eventDateTime == null
                              ? 'Select Event Date & Time'
                              : DateFormat('yyyy-MM-dd hh:mm a').format(_eventDateTime!),
                          style: TextStyle(
                            color: _eventDateTime == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: AppTheme.aluNavy),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Event Location',
                    hintText: 'e.g. Innovation Hub / Zoom link',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter a location';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Target Audience Tags
                TextFormField(
                  controller: _targetAudienceController,
                  decoration: InputDecoration(
                    labelText: 'Target Audience Tags (comma separated)',
                    hintText: 'e.g. Python, Product Design, Class of 2024',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.people_outline),
                  ),
                ),
                const SizedBox(height: 20),

                // In-App RSVP Toggle vs External registration link
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Enable In-App RSVP', style: TextStyle(fontWeight: FontWeight.bold)),
                          Switch(
                            value: _inAppRsvp,
                            onChanged: (val) => setState(() => _inAppRsvp = val),
                            activeColor: AppTheme.aluNavy,
                          ),
                        ],
                      ),
                      if (!_inAppRsvp) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _registrationLinkController,
                          decoration: InputDecoration(
                            labelText: 'External Registration Link',
                            hintText: 'https://...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) {
                            if (!_inAppRsvp && (val == null || val.trim().isEmpty)) {
                              return 'Please enter a registration link';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final isSelected = _postType == type;
    return ElevatedButton(
      onPressed: () => setState(() => _postType = type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.aluNavy : AppTheme.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.borderLight),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
