import 'package:meta/meta.dart';

class PreviewData {
  PreviewData({
    this.description,
    this.image,
    this.link,
    this.title,
  });

  String description;
  PreviewDataImage image;
  String link;
  String title;
}

@immutable
class PreviewDataImage {
  const PreviewDataImage({
    @required this.height,
    @required this.url,
    @required this.width,
  });

  final double height;
  final String url;
  final double width;
}

@immutable
class Size {
  const Size({
    @required this.height,
    @required this.width,
  });

  final double height;
  final double width;
}
