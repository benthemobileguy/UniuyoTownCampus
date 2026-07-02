import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Issue categories for reporting
enum IssueCategory {
  facilityDamage('Facility Damage', Icons.construction, Color(0xFFE65100)),
  securityThreat('Security Threat', Icons.security, Color(0xFFC62828)),
  academicIssue('Academic Issue', Icons.school, Color(0xFF1565C0));

  final String label;
  final IconData icon;
  final Color color;

  const IssueCategory(this.label, this.icon, this.color);
}

/// Report Issue Page - allows users to report campus issues
class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  IssueCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _selectedCategory == null
          ? _buildCategorySelection()
          : _ReportForm(
              category: _selectedCategory!,
              onBack: () => setState(() => _selectedCategory = null),
              onSubmit: _submitReport,
            ),
    );
  }

  Widget _buildCategorySelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to report?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a category to continue',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ...IssueCategory.values.map((category) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CategoryCard(
                  category: category,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedCategory = category);
                  },
                ),
              )),
        ],
      ),
    );
  }

  void _submitReport(IssueCategory category, String title, String description, String? location) {
    // For demo: just show success message
    // In production: send to backend API
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Colors.green[600],
          size: 48,
        ),
        title: const Text('Report Submitted'),
        content: Text(
          'Your ${category.label.toLowerCase()} report has been submitted successfully. '
          'The relevant department will review it shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Category selection card
class _CategoryCard extends StatelessWidget {
  final IssueCategory category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryDescription(category),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryDescription(IssueCategory category) {
    switch (category) {
      case IssueCategory.facilityDamage:
        return 'Report broken equipment, damaged buildings, or infrastructure issues';
      case IssueCategory.securityThreat:
        return 'Report suspicious activity, safety concerns, or security incidents';
      case IssueCategory.academicIssue:
        return 'Report academic concerns, course issues, or administrative problems';
    }
  }
}

/// Report form for entering issue details
class _ReportForm extends StatefulWidget {
  final IssueCategory category;
  final VoidCallback onBack;
  final Function(IssueCategory, String, String, String?) onSubmit;

  const _ReportForm({
    required this.category,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: widget.category.color.withOpacity(0.1),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                color: widget.category.color,
              ),
              Icon(widget.category.icon, color: widget.category.color),
              const SizedBox(width: 12),
              Text(
                widget.category.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.category.color,
                ),
              ),
            ],
          ),
        ),
        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Describe the Issue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide as much detail as possible',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Brief summary of the issue',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Provide detailed information about the issue...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Location field (optional)
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location (optional)',
                      hintText: 'e.g., Science Building, Room 101',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.category.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your report will be reviewed by the appropriate department. '
                            'You may be contacted for additional information.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Simulate network delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _isSubmitting = false);
          widget.onSubmit(
            widget.category,
            _titleController.text.trim(),
            _descriptionController.text.trim(),
            _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
          );
        }
      });
    }
  }
}
