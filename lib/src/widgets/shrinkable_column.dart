import 'package:flutter/material.dart';

/// A widget that renders a padded Column if children is not empty, otherwise renders a SizedBox.shrink
///
/// This is useful when you want to conditionally render a Column only when there are children,
/// avoiding unnecessary space taken up by an empty Column.
class ShrinkableColumn extends StatelessWidget {
  /// The widgets below this widget in the tree.
  final List<Widget> children;

  /// How the children should be placed along the main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How the children should be placed along the cross axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// The padding around the column.
  final EdgeInsetsGeometry? padding;

  const ShrinkableColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final Widget column = Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: column,
    );
  }
}
