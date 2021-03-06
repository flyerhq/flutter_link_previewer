import 'package:meta/meta.dart';

@immutable
class Size {
  const Size({
    required this.height,
    required this.width,
  });

  final double height;
  final double width;
}
