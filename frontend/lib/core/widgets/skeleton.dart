import 'package:flutter/material.dart';

/// A single grey placeholder block, used while a `FutureProvider` is
/// loading (`AsyncValue.loading`).
class SkeletonBox extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;

  const SkeletonBox({
    super.key,
    required this.height,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

/// A stack of [SkeletonBox]es, one per entry in [heights].
class SkeletonColumn extends StatelessWidget {
  final List<double> heights;

  const SkeletonColumn({super.key, required this.heights});

  @override
  Widget build(BuildContext context) {
    return Column(children: heights.map((h) => SkeletonBox(height: h)).toList());
  }
}
