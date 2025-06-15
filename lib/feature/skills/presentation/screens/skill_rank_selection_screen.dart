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

  String? _selectedRank; // Holds the currently selected value in the dropdown

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final currentRankInProvider = authProvider.state.skillRank;
    print(
      'SkillRankSelectionScreen: Initializing with currentRankInProvider: "$currentRankInProvider"',
    ); // Debug print

    if (currentRankInProvider.isNotEmpty) {
      _selectedRank = _skillRanks.firstWhere(
        (rank) => rank.startsWith(currentRankInProvider.split(' ')[0]),
        orElse: () {
          print(
            'SkillRankSelectionScreen: No match found for "$currentRankInProvider", defaulting to first rank.',
          ); // Debug print
          return _skillRanks.first; // Default to the first rank if no match
        },
      );
    } else {
      _selectedRank =
          _skillRanks.first; // If empty, directly set to the first rank
      print(
        'SkillRankSelectionScreen: currentRankInProvider is empty, defaulting to first rank.',
      ); // Debug print
    }

    // *** FIX: Defer the setSkillRank call using addPostFrameCallback ***
    // This ensures the state update happens after the initial build completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only update the provider if the current value in the provider is
      // different from what we've determined _selectedRank should be
      // based on the initial loading or defaulting.
      if (_selectedRank != null &&
          authProvider.state.skillRank != _selectedRank!.split(' ')[0]) {
        authProvider.setSkillRank(_selectedRank!.split(' ')[0]);
      }
      print(
        'SkillRankSelectionScreen: _selectedRank set to: "${_selectedRank}" (after post-frame callback)',
      ); // Debug print
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.background, // Use theme background
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
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
                    'Select your current skill level to get more personalized job recommendations.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground
                          .withOpacity(0.8), // Use onBackground
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Your Skill Rank (E-SSS)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.9),
                    ), // Use onBackground
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface, // Use theme surface for dropdown background
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.2),
                      ), // Themed border
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value:
                            _selectedRank, // This value should now always be non-null after initState
                        hint: Text(
                          'Select your rank',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ), // Themed hint
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
                              ), // Themed text color
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
                      ).colorScheme.onBackground.withOpacity(0.7),
                    ), // Use onBackground
                  ),
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
                      await provider.saveSkillRank();
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
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
