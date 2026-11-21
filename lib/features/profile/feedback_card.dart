import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/remote/feedback_remote.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

const _maxChars = 1000;
final _playApp = Uri.parse('market://details?id=com.halloleute.app');
final _playWeb = Uri.parse(
  'https://play.google.com/store/apps/details?id=com.halloleute.app',
);

Future<bool> _launchExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}

/// Profile card: rate the app and send suggestions (private, to the owner),
/// and a "Rate on Google Play" button. The Play button is shown to everyone
/// and is never tied to the stars: Google Play forbids "review gating".
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.remote,
    this.openUrl,
    this.showPlayButton,
  });

  final FeedbackRemote remote;

  /// Opens a link outside the app; defaults to url_launcher.
  final Future<bool> Function(Uri)? openUrl;

  /// Defaults to Android only.
  final bool? showPlayButton;

  Future<void> _openPlay() async {
    final open = openUrl ?? _launchExternal;
    if (!await open(_playApp)) await open(_playWeb);
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FeedbackSheet(remote: remote),
    );
  }

  @override
  Widget build(BuildContext context) {
    final play =
        showPlayButton ?? defaultTargetPlatform == TargetPlatform.android;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.mustard,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Enjoying Hallo Leute?',
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
            'Rate the app and tell us what to improve.',
            style: AppText.body(14, color: AppColors.creamMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          _Button(
            label: 'Send feedback',
            icon: Icons.chat_bubble_outline_rounded,
            filled: true,
            onPressed: () => _openSheet(context),
          ),
          if (play) ...[
            const SizedBox(height: 10),
            _Button(
              label: 'Rate on Google Play',
              icon: Icons.shop_outlined,
              onPressed: _openPlay,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({required this.remote});

  final FeedbackRemote remote;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _improve = TextEditingController();
  final _likes = TextEditingController();
  int _rating = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _improve.dispose();
    _likes.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_rating == 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.remote.send(
        FeedbackEntry(
          rating: _rating,
          improve: _improve.text,
          likes: _likes.text,
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Danke! We read every message.')),
        );
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              "Couldn't send. Check your internet connection and try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + inset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                'How do you like Hallo Leute?',
                style: AppText.display(24, color: AppColors.cream),
              ),
              const SizedBox(height: 14),
              _Stars(
                rating: _rating,
                onChanged: _busy ? null : (r) => setState(() => _rating = r),
              ),
              const SizedBox(height: 18),
              _TextBox(controller: _improve, label: 'What could be better?'),
              const SizedBox(height: 12),
              _TextBox(controller: _likes, label: 'What do you like?'),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: AppText.body(13.5, color: AppColors.coral),
                ),
              ],
              const SizedBox(height: 18),
              _Button(
                label: _busy ? 'Sending…' : 'Send',
                icon: Icons.send_rounded,
                filled: true,
                onPressed: _rating == 0 || _busy ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i <= rating,
            label: i == 1 ? '1 star' : '$i stars',
            excludeSemantics: true,
            child: InkResponse(
              onTap: onChanged == null ? null : () => onChanged!(i),
              radius: 26,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 40,
                  color: i <= rating
                      ? AppColors.mustard
                      : AppColors.cream.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.navyLine.withValues(alpha: 0.6)),
    );
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 5,
      maxLength: _maxChars,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: AppColors.mustard,
      style: AppText.body(15.5, color: AppColors.cream),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.body(15, color: AppColors.creamMuted),
        floatingLabelStyle: AppText.body(14, color: AppColors.mustard),
        counterStyle: AppText.body(11.5, color: AppColors.creamMuted),
        filled: true,
        fillColor: AppColors.navy800.withValues(alpha: 0.6),
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.mustard, width: 1.5),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
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
    final color = filled ? AppColors.navy : AppColors.cream;
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
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      15.5,
                      weight: FontWeight.w800,
                      color: color,
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
