import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
import 'package:my_job_quest/feature/home/presentation/widget/button.dart';
import 'package:my_job_quest/feature/home/presentation/home_screen.dart'; // Import HomeScreen for navigation
import 'package:provider/provider.dart';

class SkillRankSelectionScreen extends StatefulWidget {
  const SkillRankSelectionScreen({super.key});

  @override
  State<SkillRankSelectionScreen> createState() =>
      _SkillRankSelectionScreenState();
}

class _SkillRankSelectionScreenState extends State<SkillRankSelectionScreen> {
  // Define your E-SSS (Skill Rank) options and their general mapping
  final List<String> _skillRanks = [
    'E (Beginner)',
    'D (Junior Developer)',
    'C (Mid-level Developer)',
    'B (Senior Developer)',
    'A (Lead/Tech Lead)',
    'S (Principal Developer)',
    'SS (Staff Developer)',
    'SSS (Architect/Distinguished Engineer)',
  ];

  // Define common preferred locations
  final List<String> _locationOptions = [
    'Remote',
    'Hybrid',
    'On-site',
    'New York',
    'San Francisco',
    'London',
    'Berlin',
    'Tokyo',
    'Anywhere', // Added for broader search
  ];

  // Define common preferred job types
  final List<String> _jobTypeOptions = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Temporary',
  ];

  String? _selectedRank; // Holds the currently selected value in the dropdown
  List<String> _selectedLocations = []; // Holds selected preferred locations
  List<String> _selectedJobTypes = []; // Holds selected preferred job types

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

    // Initialize _selectedRank from provider state
    final currentRankInProvider = authProvider.state.skillRank;
    if (currentRankInProvider.isNotEmpty) {
      _selectedRank = _skillRanks.firstWhere(
        (rank) => rank.startsWith(currentRankInProvider.split(' ')[0]),
        orElse: () => _skillRanks.first, // Default if no match
      );
    } else {
      _selectedRank = _skillRanks.first; // Default to the first rank
    }

    // Initialize _selectedLocations from provider state
    _selectedLocations = List.from(authProvider.state.preferredLocations);

    // Initialize _selectedJobTypes from provider state
    _selectedJobTypes = List.from(authProvider.state.preferredJobTypes);

    // Defer setting provider state to avoid issues during initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only update provider if the current value determined for _selectedRank
      // is different from what's already in the provider.
      if (_selectedRank != null &&
          authProvider.state.skillRank != _selectedRank!.split(' ')[0]) {
        authProvider.setSkillRank(_selectedRank!.split(' ')[0]);
      }
      // Set initial locations and job types in provider
      authProvider.setPreferredLocations(_selectedLocations);
      authProvider.setPreferredJobTypes(_selectedJobTypes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: SingleChildScrollView(
              // Added SingleChildScrollView
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24), // Adjusted top spacing
                  Text(
                    'Tell Us About Your Skills!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your current skill level and job preferences to get personalized job recommendations.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Skill Rank Selection
                  Text(
                    'Your Skill Rank (E-SSS)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.9),
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
                        value: _selectedRank,
                        hint: Text(
                          'Select your rank',
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
                            _selectedRank = newValue;
                            provider.setSkillRank(
                              newValue?.split(' ')[0] ?? '',
                            );
                          });
                        },
                        items: _skillRanks.map<DropdownMenuItem<String>>((
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
                  const SizedBox(height: 16),
                  Text(
                    'E-SSS ranks represent skill levels from Beginner to Architect. For example, a "D" rank developer can handle tasks typically done by three "E" rank developers.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Preferred Locations Section
                  Text(
                    'Preferred Locations (Select all that apply)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0, // gap between adjacent chips
                    runSpacing: 8.0, // gap between lines
                    children: _locationOptions.map((location) {
                      bool isSelected = _selectedLocations.contains(location);
                      return FilterChip(
                        label: Text(location),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              // If "Anywhere" is selected, deselect others and vice versa
                              if (location == 'Anywhere') {
                                _selectedLocations.clear();
                                _selectedLocations.add('Anywhere');
                              } else {
                                _selectedLocations.remove(
                                  'Anywhere',
                                ); // If specific location selected, deselect "Anywhere"
                                _selectedLocations.add(location);
                              }
                            } else {
                              _selectedLocations.remove(location);
                            }
                            provider.setPreferredLocations(
                              _selectedLocations,
                            ); // Update provider
                          });
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Preferred Job Types Section
                  Text(
                    'Preferred Job Types (Select all that apply)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _jobTypeOptions.map((jobType) {
                      bool isSelected = _selectedJobTypes.contains(jobType);
                      return FilterChip(
                        label: Text(jobType),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedJobTypes.add(jobType);
                            } else {
                              _selectedJobTypes.remove(jobType);
                            }
                            provider.setPreferredJobTypes(
                              _selectedJobTypes,
                            ); // Update provider
                          });
                        },
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

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
                      await provider.saveUserPreferences();
                      if (!provider.state.isLoading &&
                          provider.state.errorMessage.isEmpty) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      }
                    },
                    title: 'Save & Continue',
                    isloading: provider.state.isLoading,
                    isEnabled:
                        !provider.state.isLoading &&
                        provider.state.skillRank.isNotEmpty,
                  ),
                  const SizedBox(height: 20), // Added bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
