import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/models/onboarding_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart';
import 'package:poppylo/state/auth_controller.dart';
import 'package:poppylo/state/onboarding_controller.dart';
import 'package:poppylo/widgets/onboarding_widgets.dart';

/// Onboarding screen 1 of 3 — the public profile people see before a coffee.
class BuildProfileScreen extends ConsumerStatefulWidget {
  const BuildProfileScreen({super.key});

  @override
  ConsumerState<BuildProfileScreen> createState() => _BuildProfileScreenState();
}

class _BuildProfileScreenState extends ConsumerState<BuildProfileScreen> {
  final _firstNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _workController = TextEditingController();
  final _bioController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _workFocus = FocusNode();
  final _bioFocus = FocusNode();

  // A field only shows an error once it's been visited and left.
  final _touched = <String>{};

  bool _isLoading = false;
  bool _photoPromptShown = false;
  String? _errorMessage;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    for (final c in [
      _firstNameController,
      _ageController,
      _workController,
      _bioController,
    ]) {
      c.addListener(() => setState(() {}));
    }
    for (final entry in {
      'firstName': _firstNameFocus,
      'age': _ageFocus,
      'work': _workFocus,
      'bio': _bioFocus,
    }.entries) {
      entry.value.addListener(() {
        if (!entry.value.hasFocus) {
          setState(() => _touched.add(entry.key));
        }
      });
    }

    // Restore anything already entered (e.g. user tapped back from screen 2).
    final saved = ref.read(onboardingControllerProvider);
    _firstNameController.text = saved.firstName;
    _ageController.text = saved.age;
    _workController.text = saved.work;
    _bioController.text = saved.bio;
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameController,
      _ageController,
      _workController,
      _bioController,
    ]) {
      c.dispose();
    }
    for (final f in [_firstNameFocus, _ageFocus, _workFocus, _bioFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  String? get _nameError {
    if (_firstNameController.text.trim().isEmpty) return 'Add your first name';
    return null;
  }

  String? get _ageError {
    final raw = _ageController.text.trim();
    if (raw.isEmpty) return 'Add your age';
    final n = int.tryParse(raw);
    if (n == null) return 'Numbers only';
    if (n < 18) return 'You must be 18 or older';
    if (n > 99) return 'Enter a valid age';
    return null;
  }

  String? get _workError {
    if (_workController.text.trim().isEmpty) return 'Add what you do';
    return null;
  }

  bool get _canProceed =>
      _nameError == null && _ageError == null && _workError == null;

  Future<void> _pickPhoto() async {
    HapticFeedback.selectionClick();
    final source = await _choosePhotoSource();
    if (source == null) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      // Held as a local file path until it's uploaded on "Continue".
      ref.read(onboardingControllerProvider.notifier).setPhoto(picked.path);
    } catch (_) {
      if (!mounted) return;
      _showSnack("Couldn't open the camera or gallery.");
    }
  }

  Future<ImageSource?> _choosePhotoSource() {
    final colorScheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFFF3F1EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading:
                  Icon(Icons.photo_camera_outlined, color: colorScheme.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: colorScheme.primary),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleContinue() async {
    if (_isLoading) return;

    if (!_canProceed) {
      setState(() => _touched.addAll(['firstName', 'age', 'work']));
      HapticFeedback.heavyImpact();
      return;
    }

    final hasPhoto = ref.read(onboardingControllerProvider).hasPhoto;
    if (!hasPhoto && !_photoPromptShown) {
      _photoPromptShown = true;
      final added = await _showPhotoPrompt();
      if (added == true || !mounted) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    final onboarding = ref.read(onboardingControllerProvider.notifier);
    onboarding.saveProfile(
      firstName: _firstNameController.text,
      age: _ageController.text,
      work: _workController.text,
      bio: _bioController.text,
    );
    final data = ref.read(onboardingControllerProvider);

    final api = ref.read(onboardingApiProvider);
    try {
      await api.saveProfile(
        firstName: data.firstName,
        age: data.ageValue!,
        job: data.work,
        bio: data.bio,
        photoUrl: data.photoUrlForApi,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      return;
    }

    // The profile now exists, so a locally-picked photo can be uploaded.
    // A failure here is non-blocking — the photo is optional and can be
    // added later from the profile screen.
    if (data.hasPendingLocalPhoto) {
      try {
        final url = await api.uploadPhoto(data.photoPath!);
        ref.read(onboardingControllerProvider.notifier).setPhoto(url);
      } on ApiException catch (e) {
        if (mounted) {
          _showSnack('Photo didn\'t upload (${e.message}) — add it later.');
        }
      }
    }
    if (!mounted) return;

    ref
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.conversation);
    context.push(AppRoutes.onboardConversation);

    setState(() => _isLoading = false);
  }

  Future<bool?> _showPhotoPrompt() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFFF3F1EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.photo_camera_outlined,
                  color: colorScheme.primary, size: 32),
              const SizedBox(height: 16),
              Text(
                'Add a photo?',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Profiles with a photo get far more coffee matches. You can '
                'still add one later from your profile.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext, true);
                    await _pickPhoto();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text('Add photo'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(
                  'Continue without',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final photoPath = ref.watch(
      onboardingControllerProvider.select((s) => s.photoPath),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      resizeToAvoidBottomInset: true,
      appBar: const OnboardingAppBar(step: 1),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OnboardingHeader(
                      title: 'Tell us a little about you',
                      subtitle:
                          "Help people know who they're meeting for coffee.",
                    ),
                    const SizedBox(height: 28),

                    // --- Photo (encouraged, not required) ---
                    Center(
                      child: Column(
                        children: [
                          Semantics(
                            button: true,
                            label: photoPath == null
                                ? 'Add profile photo'
                                : 'Change profile photo',
                            child: GestureDetector(
                              onTap: _pickPhoto,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      image: photoPath != null
                                          ? DecorationImage(
                                              image: photoPath
                                                      .startsWith('http')
                                                  ? NetworkImage(photoPath)
                                                  : FileImage(File(photoPath))
                                                      as ImageProvider,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: photoPath == null
                                        ? Icon(Icons.camera_alt,
                                            color: colorScheme.primary,
                                            size: 30)
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFF3F1EB),
                                          width: 3,
                                        ),
                                      ),
                                      child: Icon(
                                        photoPath == null
                                            ? Icons.add
                                            : Icons.edit,
                                        color: colorScheme.onPrimary,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            photoPath == null
                                ? 'ADD A PHOTO · RECOMMENDED'
                                : 'LOOKING GOOD',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.5),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _Field(
                      label: 'FIRST NAME',
                      hint: 'Your given name',
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      nextFocusNode: _ageFocus,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                      enabled: !_isLoading,
                      error: _touched.contains('firstName') ? _nameError : null,
                    ),
                    _Field(
                      label: 'AGE',
                      hint: 'Years',
                      controller: _ageController,
                      focusNode: _ageFocus,
                      nextFocusNode: _workFocus,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      enabled: !_isLoading,
                      error: _touched.contains('age') ? _ageError : null,
                    ),
                    _Field(
                      label: 'WHAT DO YOU DO?',
                      hint: 'e.g. Barista, Designer, Student',
                      controller: _workController,
                      focusNode: _workFocus,
                      nextFocusNode: _bioFocus,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_isLoading,
                      error: _touched.contains('work') ? _workError : null,
                    ),
                    _Field(
                      label: 'SHORT BIO',
                      hint: 'A line or two about you…',
                      controller: _bioController,
                      focusNode: _bioFocus,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      maxLength: OnboardingProfile.bioMaxLength,
                      showCounter: true,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _handleContinue(),
                    ),
                  ],
                ),
              ),
            ),
            OnboardingErrorBanner(message: _errorMessage),
            OnboardingPrimaryButton(
              label: 'Continue',
              enabled: _canProceed,
              loading: _isLoading,
              onPressed: _handleContinue,
              trailingIcon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.textInputAction,
    this.enabled = true,
    this.error,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final TextInputAction? textInputAction;
  final bool enabled;
  final String? error;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasError = error != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingSectionLabel(label),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError ? Colors.red.shade400 : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              autofillHints: autofillHints,
              inputFormatters: inputFormatters,
              maxLines: maxLines,
              maxLength: maxLength,
              textInputAction: textInputAction ??
                  (nextFocusNode != null
                      ? TextInputAction.next
                      : TextInputAction.done),
              onSubmitted: (value) {
                if (nextFocusNode != null) {
                  FocusScope.of(context).requestFocus(nextFocusNode);
                } else {
                  focusNode.unfocus();
                  onSubmitted?.call(value);
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
                counterText: '',
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                const SizedBox(width: 4),
                Text(
                  error!,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ] else if (showCounter) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${controller.text.characters.length} / ${maxLength ?? 0}',
                style: textTheme.labelSmall?.copyWith(
                  color: controller.text.characters.length == (maxLength ?? 0)
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.5),
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
