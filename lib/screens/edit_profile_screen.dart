import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:poppylo/models/profile_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/profile_api.dart';
import 'package:poppylo/state/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const _fill = Color(0xFFE6EBE6);
  static const _green = Color(0xFF1B3B2B);
  static const _bioMax = 150;
  static const _purposes = <String, IconData>{
    'Make friends': Icons.people_outline,
    'Networking': Icons.work_outline,
    'Shared interests': Icons.extension_outlined,
    'Dating': Icons.favorite_border,
    'Good conversation': Icons.chat_bubble_outline,
  };

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _jobController = TextEditingController();
  final _bioController = TextEditingController();
  final _imagePicker = ImagePicker();

  final Set<String> _interests = {};
  String? _purposeLabel;
  String? _remotePhotoUrl; // existing hosted photo
  String? _localPhotoPath; // newly picked, not yet uploaded

  bool _prefilled = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _ageController,
      _jobController,
      _bioController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _ageController,
      _jobController,
      _bioController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(UserMe me) {
    if (_prefilled) return;
    _prefilled = true;
    final p = me.profile;
    _nameController.text = p?.firstName ?? '';
    _ageController.text = p?.age != null && p!.age > 0 ? '${p.age}' : '';
    _jobController.text = p?.job ?? '';
    _bioController.text = p?.bio ?? '';
    _remotePhotoUrl = p?.photoUrl;
    _interests
      ..clear()
      ..addAll(me.interests.map((i) => i.label));
    _purposeLabel = purposeLabelFromApi(me.purpose);
    if (_purposeLabel!.isEmpty) _purposeLabel = null;
  }

  String? get _nameError =>
      _nameController.text.trim().isEmpty ? 'Add your name' : null;

  String? get _ageError {
    final raw = _ageController.text.trim();
    if (raw.isEmpty) return 'Add your age';
    final n = int.tryParse(raw);
    if (n == null || n < 18 || n > 99) return 'Enter a valid age (18–99)';
    return null;
  }

  bool get _canSave => _nameError == null && _ageError == null && !_saving;

  Future<void> _pickPhoto() async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFFF3F1EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _green),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _green),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _localPhotoPath = picked.path);
      }
    } catch (_) {
      if (mounted) _snack("Couldn't open the camera or gallery.");
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _save() async {
    if (!_canSave) {
      setState(() {}); // surface validation
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    final api = ref.read(profileApiProvider);
    try {
      await api.updateProfile(
        firstName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        job: _jobController.text.trim(),
        bio: _bioController.text.trim(),
      );
      if (_localPhotoPath != null) {
        try {
          await api.uploadPhoto(_localPhotoPath!);
        } on ApiException catch (e) {
          if (mounted) _snack('Photo didn\'t upload (${e.message}).');
        }
      }
      if (_interests.isNotEmpty) {
        await api.setInterests(_interests.map((l) => l.toLowerCase()).toList());
      }
      if (_purposeLabel != null) {
        await api.setPurpose(kPurposeLabelToApi[_purposeLabel]!);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _saving = false;
        _error = e.message;
      });
      return;
    }

    ref.invalidate(meProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final me = ref.watch(meProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: SafeArea(
        child: me.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _green)),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Couldn't load your profile"),
                TextButton(
                  onPressed: () => ref.invalidate(meProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (data) {
            _prefill(data);
            return Column(
              children: [
                _header(context, textTheme, colorScheme),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const SizedBox(height: 24),
                      _avatar(textTheme),
                      const SizedBox(height: 32),
                      _label('NAME', textTheme),
                      _field(_nameController, error: _nameError),
                      const SizedBox(height: 20),
                      _label('AGE', textTheme),
                      _field(_ageController,
                          keyboardType: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          error: _ageError),
                      const SizedBox(height: 20),
                      _label('WHAT YOU DO', textTheme),
                      _field(_jobController),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _label('BIO', textTheme),
                          Text(
                            '${_bioController.text.characters.length}/$_bioMax',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      _field(_bioController, maxLines: 4, maxLength: _bioMax),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _label('INTERESTS', textTheme),
                          Text(
                            '${_interests.length}/7',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          for (final label in kInterestCatalog)
                            _chip(
                              label,
                              selected: _interests.contains(label),
                              onTap: () => _toggleInterest(label),
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _label('PRIMARY PURPOSE', textTheme),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.4,
                        children: [
                          for (final entry in _purposes.entries)
                            _purposeCard(
                                entry.key, entry.value, colorScheme, textTheme),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_error!,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: Colors.red.shade400)),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _green.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
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
            );
          },
        ),
      ),
    );
  }

  void _toggleInterest(String label) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_interests.contains(label)) {
        _interests.remove(label);
      } else if (_interests.length < 7) {
        _interests.add(label);
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  Widget _header(
      BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            color: colorScheme.primary,
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          Text(
            'Edit Profile',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _avatar(TextTheme textTheme) {
    ImageProvider? img;
    if (_localPhotoPath != null) {
      img = FileImage(File(_localPhotoPath!));
    } else if ((_remotePhotoUrl ?? '').isNotEmpty) {
      img = NetworkImage(_remotePhotoUrl!);
    }
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: _green.withOpacity(0.08),
                  backgroundImage: img,
                  child: img == null
                      ? const Icon(Icons.camera_alt, color: _green, size: 28)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFF3F1EB), width: 3),
                    ),
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'TAP TO CHANGE',
            style: textTheme.labelSmall?.copyWith(
              color: _green.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t, TextTheme textTheme) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: textTheme.labelSmall?.copyWith(
            color: _green.withOpacity(0.5),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller, {
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? error,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: textTheme.bodyMedium
              ?.copyWith(color: _green, height: maxLines > 1 ? 1.5 : 1.0),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _fill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null
                  ? BorderSide(color: Colors.red.shade400, width: 1.5)
                  : BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error,
                style:
                    textTheme.bodySmall?.copyWith(color: Colors.red.shade400)),
          ),
      ],
    );
  }

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _green : _fill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : _green.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 5),
              const Icon(Icons.check, size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _purposeCard(String label, IconData icon, ColorScheme colorScheme,
      TextTheme textTheme) {
    final selected = _purposeLabel == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _purposeLabel = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _fill : Colors.transparent,
          border: Border.all(
            color: selected ? _green : _green.withOpacity(0.15),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: selected ? _green : _green.withOpacity(0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: selected ? _green : _green.withOpacity(0.6),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
