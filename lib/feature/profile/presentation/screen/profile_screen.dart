// import 'package:flutter/material.dart';
// import 'package:my_job_quest/feature/auth/presentation/manager/my_auth_provider.dart';
// import 'package:my_job_quest/feature/home/presentation/widget/button.dart';
// import 'package:my_job_quest/feature/home/presentation/home_screen.dart'; // For navigation back to Home
// import 'package:provider/provider.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   // Define your E-SSS (Skill Rank) options
//   final List<String> _skillRanks = [
//     'E (Beginner)',
//     'D (Junior Developer)',
//     'C (Mid-level Developer)',
//     'B (Senior Developer)',
//     'A (Lead/Tech Lead)',
//     'S (Principal Developer)',
//     'SS (Staff Developer)',
//     'SSS (Architect/Distinguished Engineer)',
//   ];

//   // Define comprehensive lists for locations and job types
//   final List<String> _allLocations = [
//     'Remote',
//     'New York, NY',
//     'San Francisco, CA',
//     'Seattle, WA',
//     'Austin, TX',
//     'Boston, MA',
//     'Chicago, IL',
//     'London, UK',
//     'Berlin, DE',
//     'Singapore',
//     'Sydney, AU',
//   ];

//   final List<String> _allJobTypes = [
//     'Full-time',
//     'Part-time',
//     'Contract',
//     'Temporary',
//     'Internship',
//     'Hybrid',
//   ];

//   String? _selectedSkillRank;
//   List<String> _selectedPreferredLocations = [];
//   List<String> _selectedPreferredJobTypes = [];

//   final TextEditingController _nameController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

//       // Initialize Name
//       _nameController.text = authProvider.state.name;
//       authProvider.setName(_nameController.text); // Ensure provider is synced

//       // Initialize Skill Rank
//       final currentRankInProvider = authProvider.state.skillRank;
//       if (currentRankInProvider.isNotEmpty) {
//         _selectedSkillRank = _skillRanks.firstWhere(
//           (rank) => rank.startsWith(currentRankInProvider),
//           orElse: () => _skillRanks.first, // Fallback if no exact match
//         );
//       } else {
//         _selectedSkillRank = _skillRanks.first; // Default if empty
//       }
//       // Ensure provider state matches default if it was empty
//       if (authProvider.state.skillRank.isEmpty ||
//           _selectedSkillRank != null &&
//               authProvider.state.skillRank !=
//                   _selectedSkillRank!.split(' ')[0]) {
//         authProvider.setSkillRank(_selectedSkillRank!.split(' ')[0]);
//       }

//       // Initialize Preferred Locations
//       _selectedPreferredLocations = List.from(
//         authProvider.state.preferredLocations,
//       );
//       authProvider.setPreferredLocations(
//         _selectedPreferredLocations,
//       ); // Sync provider

//       // Initialize Preferred Job Types
//       _selectedPreferredJobTypes = List.from(
//         authProvider.state.preferredJobTypes,
//       );
//       authProvider.setPreferredJobTypes(
//         _selectedPreferredJobTypes,
//       ); // Sync provider

//       if (mounted) {
//         setState(() {}); // Refresh UI after setting initial values
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }

//   // Generic method to show a multi-select dialog
//   Future<void> _showMultiSelectDialog({
//     required String title,
//     required List<String> options,
//     required List<String> currentSelected,
//     required Function(List<String>) onSelectionChanged,
//   }) async {
//     List<String> tempSelected = List.from(currentSelected);

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           // Use StatefulBuilder to update the dialog's state
//           builder: (dialogContext, setInnerState) {
//             return AlertDialog(
//               title: Text(title),
//               content: SingleChildScrollView(
//                 child: ListBody(
//                   children: options.map((item) {
//                     return CheckboxListTile(
//                       value: tempSelected.contains(item),
//                       title: Text(item),
//                       onChanged: (isChecked) {
//                         setInnerState(() {
//                           if (isChecked!) {
//                             tempSelected.add(item);
//                           } else {
//                             tempSelected.remove(item);
//                           }
//                         });
//                       },
//                     );
//                   }).toList(),
//                 ),
//               ),
//               actions: <Widget>[
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(dialogContext).pop();
//                   },
//                   child: const Text('Cancel'),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     onSelectionChanged(tempSelected);
//                     Navigator.of(dialogContext).pop();
//                   },
//                   child: const Text('Done'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<MyAuthProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           backgroundColor: Theme.of(context).colorScheme.background,
//           appBar: AppBar(
//             title: Text(
//               'Your Profile',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).colorScheme.onPrimary,
//               ),
//             ),
//             backgroundColor: Theme.of(context).colorScheme.primary,
//             elevation: 0,
//             leading: IconButton(
//               icon: Icon(
//                 Icons.arrow_back,
//                 color: Theme.of(context).colorScheme.onPrimary,
//               ),
//               onPressed: () {
//                 Navigator.of(
//                   context,
//                 ).pop(); // Go back to the previous screen (Home)
//               },
//             ),
//           ),
//           body: SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 24.0,
//                 vertical: 20.0,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Manage your personal details and job preferences.',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.onBackground.withOpacity(0.7),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Name Field
//                   Text(
//                     'Your Name',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.onBackground.withOpacity(0.9),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   TextFormField(
//                     controller: _nameController,
//                     onChanged: provider.setName,
//                     decoration: InputDecoration(
//                       hintText: 'Enter your name',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       filled: true,
//                       fillColor: Theme.of(context).colorScheme.surface,
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Skill Rank Dropdown
//                   Text(
//                     'Your Skill Rank (E-SSS)',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.onBackground.withOpacity(0.9),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).colorScheme.surface,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: Theme.of(
//                           context,
//                         ).colorScheme.onSurface.withOpacity(0.2),
//                       ),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         isExpanded: true,
//                         value: _selectedSkillRank,
//                         hint: Text(
//                           'Select your rank',
//                           style: TextStyle(
//                             color: Theme.of(
//                               context,
//                             ).colorScheme.onSurface.withOpacity(0.5),
//                           ),
//                         ),
//                         icon: Icon(
//                           Icons.arrow_drop_down,
//                           color: Theme.of(context).colorScheme.primary,
//                         ),
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             _selectedSkillRank = newValue;
//                             provider.setSkillRank(
//                               newValue?.split(' ')[0] ?? '',
//                             );
//                           });
//                         },
//                         items: _skillRanks.map<DropdownMenuItem<String>>((
//                           String value,
//                         ) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Text(
//                               value,
//                               style: TextStyle(
//                                 color: Theme.of(context).colorScheme.onSurface,
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Preferred Locations Multi-Select
//                   Text(
//                     'Preferred Job Locations',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.onBackground.withOpacity(0.9),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   GestureDetector(
//                     onTap: () async {
//                       await _showMultiSelectDialog(
//                         title: 'Select Preferred Locations',
//                         options: _allLocations,
//                         currentSelected: _selectedPreferredLocations,
//                         onSelectionChanged: (newSelection) {
//                           setState(() {
//                             _selectedPreferredLocations = newSelection;
//                             provider.setPreferredLocations(newSelection);
//                           });
//                         },
//                       );
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context).colorScheme.surface,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Theme.of(
//                             context,
//                           ).colorScheme.onSurface.withOpacity(0.2),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               _selectedPreferredLocations.isEmpty
//                                   ? 'Select locations'
//                                   : _selectedPreferredLocations.join(', '),
//                               style: TextStyle(
//                                 color: _selectedPreferredLocations.isEmpty
//                                     ? Theme.of(
//                                         context,
//                                       ).colorScheme.onSurface.withOpacity(0.5)
//                                     : Theme.of(context).colorScheme.onSurface,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Icon(
//                             Icons.arrow_drop_down,
//                             color: Theme.of(context).colorScheme.primary,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Preferred Job Types Multi-Select
//                   Text(
//                     'Preferred Job Types',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.onBackground.withOpacity(0.9),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   GestureDetector(
//                     onTap: () async {
//                       await _showMultiSelectDialog(
//                         title: 'Select Preferred Job Types',
//                         options: _allJobTypes,
//                         currentSelected: _selectedPreferredJobTypes,
//                         onSelectionChanged: (newSelection) {
//                           setState(() {
//                             _selectedPreferredJobTypes = newSelection;
//                             provider.setPreferredJobTypes(newSelection);
//                           });
//                         },
//                       );
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context).colorScheme.surface,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Theme.of(
//                             context,
//                           ).colorScheme.onSurface.withOpacity(0.2),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               _selectedPreferredJobTypes.isEmpty
//                                   ? 'Select job types'
//                                   : _selectedPreferredJobTypes.join(', '),
//                               style: TextStyle(
//                                 color: _selectedPreferredJobTypes.isEmpty
//                                     ? Theme.of(
//                                         context,
//                                       ).colorScheme.onSurface.withOpacity(0.5)
//                                     : Theme.of(context).colorScheme.onSurface,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Icon(
//                             Icons.arrow_drop_down,
//                             color: Theme.of(context).colorScheme.primary,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // Error Message Display
//                   if (provider.state.errorMessage.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 16.0),
//                       child: Text(
//                         provider.state.errorMessage,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.error,
//                           fontSize: 14,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),

//                   // Save Profile Button
//                   Button(
//                     ontap: () async {
//                       provider.setName(
//                         _nameController.text,
//                       ); // Ensure name is synced before saving
//                       await provider
//                           .saveUserPreferences(); // Call the new combined save method
//                       if (!provider.state.isLoading &&
//                           provider.state.errorMessage.isEmpty) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Profile updated successfully!',
//                               style: TextStyle(
//                                 color: Theme.of(
//                                   context,
//                                 ).colorScheme.onSecondary,
//                               ),
//                             ),
//                             backgroundColor: Theme.of(
//                               context,
//                             ).colorScheme.secondary,
//                             behavior: SnackBarBehavior.floating,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             margin: const EdgeInsets.all(16),
//                           ),
//                         );
//                         // No need to navigate back to HomeScreen directly, AuthChanges handles it.
//                         // For a profile screen, usually you'd pop back or stay.
//                         Navigator.of(context).pop();
//                       }
//                     },
//                     title: 'Save Profile',
//                     isloading: provider.state.isLoading,
//                     isEnabled:
//                         !provider.state.isLoading &&
//                         _nameController.text.isNotEmpty &&
//                         _selectedSkillRank != null &&
//                         _selectedSkillRank!
//                             .isNotEmpty, // Skill rank must be selected
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
