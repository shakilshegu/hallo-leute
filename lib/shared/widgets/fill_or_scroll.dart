import 'package:flutter/material.dart';

/// A column that fills the screen (so Spacers centre content on big
/// phones) but scrolls instead of overflowing on small phones or with
/// large text.
class FillOrScroll extends StatelessWidget {
  const FillOrScroll({
    super.key,
    required this.padding,
    required this.children,
  });

  final EdgeInsets padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - padding.vertical).clamp(
              0,
              double.infinity,
            ),
          ),
          child: IntrinsicHeight(child: Column(children: children)),
        ),
      ),
    );
  }
}
