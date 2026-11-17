import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../landing/landing_screen.dart';

/// Guest → "Save your progress" (Google / email). Signed in → email,
/// sign out and delete account (required by Google Play).
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: auth.isGuest
              ? AppColors.mustard.withValues(alpha: 0.45)
              : AppColors.navyLine.withValues(alpha: 0.5),
        ),
      ),
      child: auth.isGuest ? _Guest(auth: auth) : _SignedIn(auth: auth),
    );
  }
}

class _Guest extends StatelessWidget {
  const _Guest({required this.auth});

  final AuthService auth;

  Future<void> _google(BuildContext context) async {
    try {
      final outcome = await auth.continueWithGoogle();
      if (!context.mounted || outcome == SignInOutcome.cancelled) return;
      _toast(context, _successText(outcome));
    } on Object catch (e) {
      if (context.mounted) _toast(context, _friendly(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              color: AppColors.mustard,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Save your progress',
              style: AppText.body(
                16,
                weight: FontWeight.w800,
                color: AppColors.cream,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to keep your words safe and continue on any phone.',
          style: AppText.body(14, color: AppColors.creamMuted, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (auth.canUseGoogle) ...[
          _AccountButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata_rounded,
            filled: true,
            onPressed: () => _google(context),
          ),
          const SizedBox(height: 10),
        ],
        _AccountButton(
          label: 'Continue with email',
          icon: Icons.mail_outline_rounded,
          filled: !auth.canUseGoogle,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.navy,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            builder: (_) => _EmailSheet(auth: auth),
          ),
        ),
      ],
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.auth});

  final AuthService auth;

  void _restart(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Sign out?',
      body:
          'Your progress is saved in your account. Sign in again any time '
          'to get it back.',
      action: 'Sign out',
    );
    if (!ok || !context.mounted) return;
    try {
      await auth.signOut();
      if (context.mounted) _restart(context);
    } on Object catch (e) {
      if (context.mounted) _toast(context, _friendly(e));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Delete account?',
      body:
          'This permanently deletes your account and all your progress. '
          'It cannot be undone.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await auth.deleteAccount();
      if (context.mounted) _restart(context);
    } on Object catch (e) {
      if (context.mounted) _toast(context, _friendly(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.cloud_done_outlined,
              color: AppColors.mustard,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress saved',
                    style: AppText.body(
                      16,
                      weight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                  Text(
                    auth.email ?? 'Signed in',
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13.5, color: AppColors.creamMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            TextButton(
              onPressed: () => _signOut(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.cream),
              child: const Text('Sign out'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _delete(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              child: const Text('Delete account'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Email → 6-digit code → done.
class _EmailSheet extends StatefulWidget {
  const _EmailSheet({required this.auth});

  final AuthService auth;

  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Object catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
    await widget.auth.sendEmailCode(_email.text);
    if (mounted) setState(() => _codeSent = true);
  });

  Future<void> _verify() => _run(() async {
    final outcome = await widget.auth.verifyEmailCode(_code.text);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(_successText(outcome))));
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + inset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _codeSent ? 'Check your email' : 'Continue with email',
              style: AppText.display(24, color: AppColors.cream),
            ),
            const SizedBox(height: 6),
            Text(
              _codeSent
                  ? 'We sent a 6-digit code to ${_email.text.trim()}.'
                  : "We'll email you a 6-digit code. No password needed.",
              style: AppText.body(14.5, color: AppColors.creamMuted),
            ),
            const SizedBox(height: 20),
            if (!_codeSent)
              _Field(
                controller: _email,
                hint: 'you@example.com',
                keyboard: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                onSubmitted: _emailValid && !_busy ? _send : null,
              )
            else
              _Field(
                controller: _code,
                hint: '123456',
                keyboard: TextInputType.number,
                maxLength: 6,
                big: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: _code.text.trim().length == 6 && !_busy
                    ? _verify
                    : null,
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: AppText.body(13.5, color: AppColors.coral)),
            ],
            const SizedBox(height: 18),
            _AccountButton(
              label: _busy
                  ? 'Please wait…'
                  : _codeSent
                  ? 'Confirm'
                  : 'Send code',
              icon: _codeSent ? Icons.check_rounded : Icons.send_rounded,
              filled: true,
              onPressed: _busy
                  ? null
                  : _codeSent
                  ? (_code.text.trim().length == 6 ? _verify : null)
                  : (_emailValid ? _send : null),
            ),
            if (_codeSent)
              Center(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _codeSent = false;
                          _code.clear();
                          _error = null;
                        }),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.creamMuted,
                  ),
                  child: const Text('Use a different email'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.keyboard,
    required this.onChanged,
    required this.onSubmitted,
    this.maxLength,
    this.big = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboard;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
  final int? maxLength;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.navyLine.withValues(alpha: 0.6)),
    );
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: keyboard,
      maxLength: maxLength,
      autocorrect: false,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      cursorColor: AppColors.mustard,
      textAlign: big ? TextAlign.center : TextAlign.start,
      style: big
          ? AppText.display(28, color: AppColors.cream, letterSpacing: 8)
          : AppText.body(17, weight: FontWeight.w700, color: AppColors.cream),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(
          big ? 24 : 16,
          color: AppColors.cream.withValues(alpha: 0.3),
        ),
        counterText: '',
        filled: true,
        fillColor: AppColors.navy800.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.mustard, width: 1.5),
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: filled ? AppColors.cream : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: filled
              ? BorderSide.none
              : BorderSide(color: AppColors.cream.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: filled ? AppColors.navy : AppColors.cream,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      15.5,
                      weight: FontWeight.w800,
                      color: filled ? AppColors.navy : AppColors.cream,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.navy800,
      title: Text(title, style: AppText.display(22, color: AppColors.cream)),
      content: Text(
        body,
        style: AppText.body(15, color: AppColors.creamMuted, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.creamMuted),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? AppColors.coral : AppColors.mustard,
          ),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

String _successText(SignInOutcome outcome) => switch (outcome) {
  SignInOutcome.linked => 'Done! Your progress is now saved to your account.',
  SignInOutcome.switchedAccount =>
    'Welcome back! Your progress from this phone was added to your account.',
  SignInOutcome.cancelled => '',
};

String _friendly(Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('token') &&
        (m.contains('expired') || m.contains('invalid'))) {
      return 'That code is wrong or has expired. Please try again.';
    }
    if (m.contains('rate limit') || e.statusCode == '429') {
      return 'Too many tries. Please wait a minute and try again.';
    }
    return e.message;
  }
  if (e is GoogleSignInException) {
    return 'Google sign-in failed. Please try again.';
  }
  return 'Something went wrong. Check your internet connection and try again.';
}
