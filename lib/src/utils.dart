import 'dart:async';
import 'package:flutter/material.dart' hide Element;
import 'package:http/http.dart' as http show get;
import 'package:html/parser.dart' as parser show parse;
import 'package:html/dom.dart' show Document, Element;
import 'package:flutter_link_previewer/src/types.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart'
    show PreviewData, PreviewDataImage;

extension FileNameExtention on String {
  String get fileExtension {
    return this?.split('/')?.last?.split('.')?.last;
  }
}

String _getMetaContent(Document document, String propertyValue) {
  final meta = document.getElementsByTagName('meta');
  Element element = meta.firstWhere(
      (e) => e.attributes['property'] == propertyValue,
      orElse: () => null);
  element ??= meta.firstWhere((e) => e.attributes['name'] == propertyValue,
      orElse: () => null);
  if (element != null) return element.attributes['content']?.trim();
  return null;
}

bool _hasUTF8Charset(Document document) {
  final meta = document.getElementsByTagName('meta');
  final element = meta.firstWhere((e) => e.attributes.containsKey('charset'),
      orElse: () => null);
  if (element == null) return true;
  return element.attributes['charset'].toLowerCase() == 'utf-8';
}

String _getTitle(Document document) {
  final titleElements = document.getElementsByTagName('title');
  if (titleElements.isNotEmpty) return titleElements.first.text;

  return _getMetaContent(document, 'og:title') ??
      _getMetaContent(document, 'twitter:title') ??
      _getMetaContent(document, 'og:site_name');
}

String _getDescription(Document document) {
  return _getMetaContent(document, 'og:description') ??
      _getMetaContent(document, 'description') ??
      _getMetaContent(document, 'twitter:description');
}

List<String> _getImageUrls(Document document, String baseUrl) {
  final meta = document.getElementsByTagName('meta');
  String attribute = 'content';
  List<Element> elements = meta
      .where((e) =>
          e.attributes['property'] == 'og:image' ||
          e.attributes['property'] == 'twitter:image')
      .toList();
  if (elements.isEmpty) {
    elements = document.getElementsByTagName('img');
    attribute = 'src';
  }
  final urlList = elements
      .map(
        (e) => _getActualImageUrl(baseUrl,
            imageUrl: e.attributes[attribute]?.trim()),
      )
      .toList();
  return urlList.where((element) => element != null).toList();
}

String _getActualImageUrl(String baseUrl, {String imageUrl}) {
  if (imageUrl == null || imageUrl.isEmpty || imageUrl.startsWith('data'))
    return null;

  if (['svg', 'gif'].contains(imageUrl.fileExtension)) return null;

  if (imageUrl.startsWith('//')) imageUrl = 'https:$imageUrl';

  if (!imageUrl.startsWith('http')) {
    if (baseUrl.endsWith('/') && imageUrl.startsWith('/')) {
      imageUrl = '${baseUrl.substring(0, baseUrl.length - 1)}$imageUrl';
    } else if (!baseUrl.endsWith('/') && !imageUrl.startsWith('/')) {
      imageUrl = '$baseUrl/$imageUrl';
    } else {
      imageUrl = '$baseUrl$imageUrl';
    }
  }

  return imageUrl;
}

Future<Size> _getImageSize(String url) {
  final image = Image.network(url);
  final completer = Completer<Size>();
  final listener = ImageStreamListener(
    (ImageInfo info, bool _) => completer.complete(
      Size(
          height: info.image.height.toDouble(),
          width: info.image.width.toDouble()),
    ),
  );
  image.image.resolve(ImageConfiguration.empty).addListener(listener);
  return completer.future;
}

Future<String> _getBiggestImageUrl(List<String> imageUrls) async {
  String currentUrl;
  double currentArea = 0.0;

  await Future.forEach(imageUrls, (String url) async {
    final size = await _getImageSize(url);
    final area = size.width * size.height;
    if (area > currentArea) {
      currentArea = area;
      currentUrl = url;
    }
  });

  return currentUrl;
}

Future<PreviewData> getPreviewData(String text) async {
  final previewData = PreviewData();

  String previewDataUrl;
  String previewDataTitle;
  String previewDataDescription;
  PreviewDataImage previewDataImage;

  try {
    final urlRegexp = RegExp(REGEX_LINK);
    final matches = urlRegexp.allMatches(text.toLowerCase());
    if (matches.isEmpty) return previewData;

    String url = text.substring(matches.first.start, matches.first.end);
    if (!url.startsWith('http')) {
      url = 'https://' + url;
    }
    previewDataUrl = url;
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    final document = parser.parse(response.body);

    if (!_hasUTF8Charset(document)) {
      return previewData;
    }

    final title = _getTitle(document);
    if (title != null) {
      previewDataTitle = title.trim();
    }

    final description = _getDescription(document);
    if (description != null) {
      previewDataDescription = description.trim();
    }

    final imageUrls = _getImageUrls(document, url);

    Size imageSize;
    String imageUrl;

    if (imageUrls.isNotEmpty) {
      imageUrl = imageUrls.length == 1
          ? imageUrls[0]
          : await _getBiggestImageUrl(imageUrls);

      imageSize = await _getImageSize(imageUrl);
      previewDataImage = PreviewDataImage(
        height: imageSize.height,
        url: imageUrl,
        width: imageSize.width,
      );
    }
    return PreviewData(
      description: previewDataDescription,
      image: previewDataImage,
      link: previewDataUrl,
      title: previewDataTitle,
    );
  } catch (e) {
    print(e);
    return PreviewData(
      description: previewDataDescription,
      image: previewDataImage,
      link: previewDataUrl,
      title: previewDataTitle,
    );
  }
}

const REGEX_LINK = r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+';
