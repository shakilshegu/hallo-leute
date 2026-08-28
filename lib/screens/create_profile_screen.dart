import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/screens/interests_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _jobFocus = FocusNode();
  final FocusNode _bioFocus = FocusNode();
  
  bool _canProceed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    void updateState() {
      setState(() {
        _canProceed = _firstNameController.text.trim().isNotEmpty &&
            _ageController.text.trim().isNotEmpty &&
            _jobController.text.trim().isNotEmpty;
      });
    }

    _firstNameController.addListener(updateState);
    _ageController.addListener(updateState);
    _jobController.addListener(updateState);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _ageController.dispose();
    _jobController.dispose();
    _bioController.dispose();
    
    _firstNameFocus.dispose();
    _ageFocus.dispose();
    _jobFocus.dispose();
    _bioFocus.dispose();
    
    super.dispose();
  }

  void _handleContinue() async {
    if (!_canProceed || _isLoading) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const InterestsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.primary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        ),
        title: Text(
          '2 OF 3',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.5),
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    Text(
                      'Tell us a little about you',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'PROFILE SETUP · PUBLIC DETAILS',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.5),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Avatar Picker
                    Center(
                      child: Semantics(
                        button: true,
                        label: 'Upload profile picture',
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: colorScheme.primary,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildInputField(
                      context,
                      label: 'FIRST NAME',
                      hint: 'Your given name',
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      nextFocusNode: _ageFocus,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                    ),
                    
                    _buildInputField(
                      context,
                      label: 'AGE',
                      hint: 'Years',
                      controller: _ageController,
                      focusNode: _ageFocus,
                      nextFocusNode: _jobFocus,
                      keyboardType: TextInputType.number,
                    ),
                    
                    _buildInputField(
                      context,
                      label: 'WHAT YOU DO',
                      hint: 'e.g. Barista, Designer, Student',
                      controller: _jobController,
                      focusNode: _jobFocus,
                      nextFocusNode: _bioFocus,
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    _buildInputField(
                      context,
                      label: 'SHORT BIO',
                      hint: 'A little about you...',
                      controller: _bioController,
                      focusNode: _bioFocus,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                      showCounter: true,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
            
            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                opacity: _canProceed || _isLoading ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_canProceed && !_isLoading) ? _handleContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
                      disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                    child: _isLoading 
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
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

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    int maxLines = 1,
    bool showCounter = false,
    TextInputAction? textInputAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.5),
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !_isLoading,
              keyboardType: keyboardType,
              textInputAction: textInputAction ?? (nextFocusNode != null ? TextInputAction.next : TextInputAction.done),
              textCapitalization: textCapitalization,
              autofillHints: autofillHints,
              maxLines: maxLines,
              maxLength: showCounter ? 150 : null,
              onSubmitted: (_) {
                if (nextFocusNode != null) {
                  FocusScope.of(context).requestFocus(nextFocusNode);
                } else {
                  focusNode.unfocus();
                  if (_canProceed) {
                    _handleContinue();
                  }
                }
              },
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary.withOpacity(0.3),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterText: '', // Hide default counter, we can build custom if needed, but for now simple
              ),
              onChanged: (text) {
                if (showCounter) setState(() {});
              },
            ),
          ),
          if (showCounter) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${controller.text.length} / 150',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
