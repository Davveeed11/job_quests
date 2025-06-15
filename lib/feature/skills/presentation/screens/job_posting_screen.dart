import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/button.dart';
import 'package:my_job_quest/feature/home/presentation/widget/text_field.dart'; // Make sure this path is correct
import 'package:provider/provider.dart';

class JobPostingScreen extends StatefulWidget {
  const JobPostingScreen({super.key});

  @override
  State<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<JobPostingScreen> {
  // Define your E-S Skill Rank options for job difficulty
  final List<String> _difficultyRanks = [
    'S Rank',
    'A Rank',
    'B Rank',
    'C Rank',
    'D Rank',
    'E Rank',
  ];

  // Define options for Job Type
  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Temporary',
    'Remote',
    'Hybrid',
  ];

  String? _selectedDifficultyRank; // Holds the selected difficulty for the job
  String? _selectedJobType; // Holds the selected job type

  // Controllers for job title and description
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _requiredSkillsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MyAuthProvider>(context, listen: false);

    // Initialize controllers with current provider state (if any)
    _jobTitleController.text = provider.state.jobTitle;
    _jobDescriptionController.text = provider.state.jobDescription;
    _companyController.text = provider.state.company;
    _locationController.text = provider.state.location;
    _salaryController.text = provider.state.salary;
    _requiredSkillsController.text = provider.state.requiredSkills;

    // Initialize selected difficulty rank
    if (provider.state.jobDifficultyRank.isNotEmpty) {
      _selectedDifficultyRank = _difficultyRanks.firstWhere(
        (rank) => rank.startsWith(provider.state.jobDifficultyRank),
        orElse: () => _difficultyRanks.first, // Default if no match
      );
    } else {
      _selectedDifficultyRank = _difficultyRanks.first; // Default to first rank
    }
    // Ensure provider state matches default if it was empty or not recognized
    provider.setJobDifficultyRank(_selectedDifficultyRank!.split(' ')[0]);

    // Initialize selected job type
    if (provider.state.jobType.isNotEmpty) {
      _selectedJobType = _jobTypes.firstWhere(
        (type) => type == provider.state.jobType,
        orElse: () => _jobTypes.first, // Default to first job type if no match
      );
    } else {
      _selectedJobType = _jobTypes.first; // Default to first job type if empty
    }
    // Ensure provider state matches default if it was empty or not recognized
    provider.setJobType(_selectedJobType!);

    // Call setState to ensure UI updates with initial values
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _requiredSkillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: Text(
              'Post a New Job',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share a job opportunity with the community.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Job Title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldWidget(
                    hint: 'e.g., Senior Software Engineer',
                    onchange: provider.setJobTitle,
                    controller: _jobTitleController,
                    isPassword: false,
                  ),
                  const SizedBox(height: 24),

                  // Company Field
                  Text(
                    'Company Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldWidget(
                    hint: 'e.g., Google, Inc.',
                    onchange: provider.setCompany,
                    controller: _companyController,
                    isPassword: false,
                  ),
                  const SizedBox(height: 24),

                  // Location Field
                  Text(
                    'Job Location (comma-separated if multiple)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldWidget(
                    hint: 'e.g., Remote, New York, NY',
                    onchange: provider.setLocation,
                    controller: _locationController,
                    isPassword: false,
                  ),
                  const SizedBox(height: 24),

                  // Salary Field
                  Text(
                    'Salary Range (e.g., \$50K - \$70K)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldWidget(
                    hint: 'e.g., \$120K - \$150K',
                    onchange: provider.setSalary,
                    controller: _salaryController,
                    isPassword: false,
                    keyboardType:
                        TextInputType.text, // Keep as text to allow '$' and 'K'
                  ),
                  const SizedBox(height: 24),

                  // Job Type Dropdown
                  Text(
                    'Job Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedJobType,
                        hint: Text(
                          'Select job type',
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
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedJobType = newValue;
                            provider.setJobType(newValue ?? '');
                          });
                        },
                        items: _jobTypes.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Job Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldWidget(
                    hint: 'Provide detailed description of the job...',
                    onchange: provider.setJobDescription,
                    controller: _jobDescriptionController,
                    maxLines: 5, // Allow multiple lines for description
                    isPassword: false,
                  ),
                  const SizedBox(height: 24),

                  // Required Skills Field
                  Text(
                    'Required Skills (comma-separated)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldWidget(
                    hint: 'e.g., Flutter, Dart, Firebase, UI/UX',
                    onchange: (value) {
                      provider.setRequiredSkills(value);
                      print(
                        'Required Skills Live Value: ${provider.state.requiredSkills}',
                      ); // DEBUG PRINT
                    },
                    controller: _requiredSkillsController,
                    isPassword: false,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Job Difficulty Rank (E-S Scale)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDifficultyRank,
                        hint: Text(
                          'Select job difficulty',
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
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDifficultyRank = newValue;
                            provider.setJobDifficultyRank(
                              newValue?.split(' ')[0] ?? '',
                            );
                          });
                        },
                        items: _difficultyRanks.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  if (provider.state.errorMessage.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 16.0),
                        Text(
                          provider.state.errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),

                  const SizedBox(height: 32),

                  Button(
                    ontap: () async {
                      // DEBUG PRINT: Check the value of requiredSkills before posting
                      print(
                        'Attempting to post. Required Skills: "${provider.state.requiredSkills}"',
                      );
                      await provider.postJob();
                      if (!provider.state.isLoading &&
                          provider.state.errorMessage.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Job posted successfully!',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondary,
                              ),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                        // Clear all controllers after successful post
                        _jobTitleController.clear();
                        _jobDescriptionController.clear();
                        _companyController.clear();
                        _locationController.clear();
                        _salaryController.clear();
                        _requiredSkillsController.clear();
                        setState(() {
                          _selectedDifficultyRank = null;
                          _selectedJobType = null;
                        });
                        Navigator.of(context).pop();
                      }
                    },
                    title: 'Post Job',
                    isloading: provider.state.isLoading,
                    isEnabled:
                        !provider.state.isLoading &&
                        provider.state.jobTitle.isNotEmpty &&
                        provider.state.jobDescription.isNotEmpty &&
                        provider.state.jobDifficultyRank.isNotEmpty &&
                        provider.state.company.isNotEmpty &&
                        provider.state.location.isNotEmpty &&
                        provider.state.salary.isNotEmpty &&
                        provider.state.jobType.isNotEmpty &&
                        provider
                            .state
                            .requiredSkills
                            .isNotEmpty, // Ensure skills are not empty
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
