import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Jane Doe');
  final TextEditingController _whatYouDoController = TextEditingController(text: 'Independent Designer');
  final TextEditingController _bioController = TextEditingController(text: 'Crafting digital experiences by day, brewing specialty coffee by night. Always looking for meaningful conversations over a good pour-over.');
  
  final List<String> _interests = ['Espresso', 'Design Systems', 'Quiet Cafes'];
  String _primaryPurpose = 'Networking'; // or 'Social'

  @override
  void dispose() {
    _nameController.dispose();
    _whatYouDoController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB), // Warm beige background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: colorScheme.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Edit Profile',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for centering
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  const SizedBox(height: 24),
                  
                  // Avatar Section
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop'), // User avatar mock
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'IMAGE • AVATAR • PUBLIC',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Name Field
                  _buildLabel('NAME', textTheme, colorScheme),
                  const SizedBox(height: 8),
                  _buildTextField(_nameController, colorScheme, textTheme),
                  const SizedBox(height: 24),
                  
                  // What You Do Field
                  _buildLabel('WHAT YOU DO', textTheme, colorScheme),
                  const SizedBox(height: 8),
                  _buildTextField(_whatYouDoController, colorScheme, textTheme),
                  const SizedBox(height: 24),
                  
                  // Bio Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('BIO', textTheme, colorScheme),
                      Text(
                        '120/150',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(_bioController, colorScheme, textTheme, maxLines: 4),
                  const SizedBox(height: 24),
                  
                  // Interests
                  _buildLabel('INTERESTS', textTheme, colorScheme),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._interests.map((interest) => _buildInterestPill(interest, colorScheme, textTheme)),
                      _buildAddInterestPill(colorScheme, textTheme),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Primary Purpose
                  _buildLabel('PRIMARY PURPOSE', textTheme, colorScheme),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPurposeOption(
                          label: 'Networking',
                          icon: Icons.work_outline,
                          isSelected: _primaryPurpose == 'Networking',
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _primaryPurpose = 'Networking');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPurposeOption(
                          label: 'Social',
                          icon: Icons.people_outline,
                          isSelected: _primaryPurpose == 'Social',
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _primaryPurpose = 'Social');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
            
            // Save Changes Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context); // Save and go back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B2B), // Dark green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save changes',
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, TextTheme textTheme, ColorScheme colorScheme) {
    return Text(
      text,
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.primary.withOpacity(0.5),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, ColorScheme colorScheme, TextTheme textTheme, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
        height: maxLines > 1 ? 1.5 : 1.0,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE6EBE6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildInterestPill(String label, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EBE6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.close, size: 14, color: colorScheme.primary.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildAddInterestPill(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        // Use a simple dashed border approach or just a solid one for simplicity if needed
        // For a dashed border, we'd need a custom painter or package, so we use a faint solid border here.
        border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1, style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 14, color: colorScheme.primary.withOpacity(0.5)),
          const SizedBox(width: 4),
          Text(
            'Add interest',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6EBE6) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF1B3B2B) : colorScheme.primary.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1B3B2B) : colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
