import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/button.dart';
import 'package:my_job_quest/feature/home/presentation/widget/text_field.dart';
import 'package:provider/provider.dart';

class JobPostingScreen extends StatefulWidget {
  const JobPostingScreen({super.key});

  @override
  State<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<JobPostingScreen> {
  // Constants moved to top for better organization
  static const List<String> _difficultyRanks = [
    'S Rank',
    'A Rank',
    'B Rank',
    'C Rank',
    'D Rank',
    'E Rank',
  ];

  static const List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Temporary',
    'Remote',
    'Hybrid',
  ];

  // Form state
  late final Map<String, TextEditingController> _controllers;
  String? _selectedDifficultyRank;
  String? _selectedJobType;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback(_initializeProviderData);
  }

  void _initializeControllers() {
    _controllers = {
      'jobTitle': TextEditingController(),
      'jobDescription': TextEditingController(),
      'company': TextEditingController(),
      'location': TextEditingController(),
      'salary': TextEditingController(),
      'requiredSkills': TextEditingController(),
    };
  }

  void _initializeProviderData(_) {
    if (!mounted) return;

    final provider = context.read<MyAuthProvider>();
    final state = provider.state;

    // Batch controller updates
    _controllers['jobTitle']!.text = state.jobTitle;
    _controllers['jobDescription']!.text = state.jobDescription;
    _controllers['company']!.text = state.company;
    _controllers['location']!.text = state.location;
    _controllers['salary']!.text = state.salary;
    _controllers['requiredSkills']!.text = state.requiredSkills;

    // Initialize dropdowns
    _selectedDifficultyRank = _getInitialDifficultyRank(
      state.jobDifficultyRank,
    );
    _selectedJobType = _getInitialJobType(state.jobType);

    if (mounted) setState(() {});

    // Update provider with initial values
    provider.setJobDifficultyRank(_selectedDifficultyRank?.split(' ')[0] ?? '');
    provider.setJobType(_selectedJobType ?? '');
  }

  String _getInitialDifficultyRank(String currentRank) {
    if (currentRank.isEmpty) return _difficultyRanks.first;
    return _difficultyRanks.firstWhere(
      (rank) => rank.startsWith(currentRank),
      orElse: () => _difficultyRanks.first,
    );
  }

  String _getInitialJobType(String currentType) {
    if (currentType.isEmpty) return _jobTypes.first;
    return _jobTypes.firstWhere(
      (type) => type == currentType,
      orElse: () => _jobTypes.first,
    );
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: _buildAppBar(context),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        'Post a New Job',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
      ),
      backgroundColor: theme.colorScheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyAuthProvider provider) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            ..._buildFormFields(context, provider),
            _buildErrorMessage(context, provider),
            const SizedBox(height: 32),
            _buildSubmitButton(context, provider),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Share a job opportunity with the community.',
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
      ),
    );
  }

  List<Widget> _buildFormFields(BuildContext context, MyAuthProvider provider) {
    return [
      _buildTextField(
        context,
        'Job Title',
        'e.g., Senior Software Engineer',
        'jobTitle',
        provider.setJobTitle,
      ),
      _buildTextField(
        context,
        'Company Name',
        'e.g., Google, Inc.',
        'company',
        provider.setCompany,
      ),
      _buildTextField(
        context,
        'Job Location (comma-separated if multiple)',
        'e.g., Remote, New York, NY',
        'location',
        provider.setLocation,
      ),
      _buildTextField(
        context,
        'Salary Range (e.g., \$50K - \$70K)',
        'e.g., \$120K - \$150K',
        'salary',
        provider.setSalary,
      ),
      _buildDropdown(
        context,
        'Job Type',
        _jobTypes,
        _selectedJobType,
        'Select job type',
        (value) {
          setState(() => _selectedJobType = value);
          provider.setJobType(value ?? '');
        },
      ),
      _buildTextField(
        context,
        'Job Description',
        'Provide detailed description of the job...',
        'jobDescription',
        provider.setJobDescription,
        maxLines: 5,
      ),
      _buildTextField(
        context,
        'Required Skills (comma-separated)',
        'e.g., Flutter, Dart, Firebase, UI/UX',
        'requiredSkills',
        provider.setRequiredSkills,
      ),
      _buildDropdown(
        context,
        'Job Difficulty Rank (E-S Scale)',
        _difficultyRanks,
        _selectedDifficultyRank,
        'Select job difficulty',
        (value) {
          setState(() => _selectedDifficultyRank = value);
          provider.setJobDifficultyRank(value?.split(' ')[0] ?? '');
        },
      ),
    ];
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    String hint,
    String controllerKey,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        const SizedBox(height: 8),
        TextFieldWidget(
          hint: hint,
          onchange: onChanged,
          controller: _controllers[controllerKey]!,
          maxLines: maxLines,
          isPassword: false,
          // keyboardType: controllerKey == 'salary' ? TextInputType.text : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String label,
    List<String> items,
    String? selectedValue,
    String hint,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              hint: Text(
                hint,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary,
              ),
              onChanged: onChanged,
              items: items
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.9),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, MyAuthProvider provider) {
    if (provider.state.errorMessage.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          provider.state.errorMessage,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, MyAuthProvider provider) {
    return Button(
      ontap: () => _handleSubmit(context, provider),
      title: 'Post Job',
      isloading: provider.state.isLoading,
      isEnabled: _isFormValid(provider),
    );
  }

  bool _isFormValid(MyAuthProvider provider) {
    final state = provider.state;
    return !state.isLoading &&
        state.jobTitle.isNotEmpty &&
        state.jobDescription.isNotEmpty &&
        state.jobDifficultyRank.isNotEmpty &&
        state.company.isNotEmpty &&
        state.location.isNotEmpty &&
        state.salary.isNotEmpty &&
        state.jobType.isNotEmpty &&
        state.requiredSkills.isNotEmpty;
  }

  Future<void> _handleSubmit(
    BuildContext context,
    MyAuthProvider provider,
  ) async {
    await provider.postJob();

    if (!provider.state.isLoading && provider.state.errorMessage.isEmpty) {
      _showSuccessMessage(context);
      _clearForm();
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Job posted successfully!',
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _clearForm() {
    _controllers.values.forEach((controller) => controller.clear());
    setState(() {
      _selectedDifficultyRank = null;
      _selectedJobType = null;
    });
  }
}
