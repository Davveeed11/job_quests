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
  // Define your E-S Skill Rank options for job difficulty
  final List<String> _difficultyRanks = [
    'E Rank',
    'D Rank',
    'C Rank',
    'B Rank',
    'A Rank',
    'S Rank',
  ];

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Temporary',
    'Internship',
  ];

  String? _selectedDifficultyRank; // Holds the selected difficulty for the job
  String? _selectedJobType; // Holds the selected job type

  // Controllers for job posting fields
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing provider state if available
    final provider = Provider.of<MyAuthProvider>(context, listen: false);
    _jobTitleController.text = provider.state.jobTitle;
    _jobDescriptionController.text = provider.state.jobDescription;
    _companyController.text = provider.state.company;
    _locationController.text = provider.state.location;
    _salaryController.text = provider.state.salary;

    _selectedDifficultyRank = provider.state.jobDifficultyRank.isNotEmpty
        ? provider.state.jobDifficultyRank
        : null;
    _selectedJobType = provider.state.jobType.isNotEmpty
        ? provider.state.jobType
        : null;
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Post a New Job',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(); // Go back to the previous screen (Home)
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
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),

                  // Job Title
                  Text(
                    'Job Title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
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

                  // Company Name
                  Text(
                    'Company Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldWidget(
                    hint: 'e.g., Tech Solutions Inc.',
                    onchange: provider.setCompany,
                    controller: _companyController,
                    isPassword: false,
                  ),
                  const SizedBox(height: 24),

                  // Location
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
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

                  // Salary
                  Text(
                    'Salary (e.g., \$100K - \$120K, Negotiable)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldWidget(
                    hint: 'e.g., \$100,000 - \$120,000',
                    onchange: provider.setSalary,
                    controller: _salaryController,
                    isPassword: false,
                    keyboardType: TextInputType
                        .text, // Could be text for ranges/negotiable
                  ),
                  const SizedBox(height: 24),

                  // Job Type Dropdown
                  Text(
                    'Job Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedJobType,
                        hint: Text(
                          'Select job type',
                          style: TextStyle(color: Colors.grey.shade500),
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
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Job Difficulty Rank Dropdown
                  Text(
                    'Job Difficulty Rank (E-S Scale)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDifficultyRank,
                        hint: Text(
                          'Select job difficulty',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDifficultyRank = newValue;
                            // Store only the rank part (e.g., "E", "D") in the provider
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
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Job Description
                  Text(
                    'Job Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
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

                  if (provider.state.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        provider.state.errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  Button(
                    ontap: () async {
                      await provider.postJob();
                      if (!provider.state.isLoading &&
                          provider.state.errorMessage.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Job posted successfully!'),
                          ),
                        );
                        // Optionally navigate back after posting
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
                        provider.state.jobType.isNotEmpty,
                  ),
                  const SizedBox(height: 20), // Spacing at the bottom
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
