import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:flutter_linkify/flutter_linkify.dart' hide UrlLinkifier;
import 'package:url_launcher/url_launcher.dart';
import '../url_linkifier.dart' show UrlLinkifier;
import '../utils.dart' show getPreviewData;

/// A widget that renders text with highlighted links.
/// Eventually unwraps to the full preview of the first found link
/// if the parsing was successful.
@immutable
class LinkPreview extends StatelessWidget {
  /// Creates [LinkPreview]
  const LinkPreview({
    Key? key,
    this.linkStyle,
    this.metadataTextStyle,
    this.metadataTitleStyle,
    this.onPreviewDataFetched,
    this.padding,
    this.previewData,
    required this.text,
    this.textStyle,
    required this.width,
  }) : super(key: key);

  /// Style of highlighted links in the text
  final TextStyle? linkStyle;

  /// Style of preview's description
  final TextStyle? metadataTextStyle;

  /// Style of preview's title
  final TextStyle? metadataTitleStyle;

  /// Callback which is called when [PreviewData] was successfully parsed.
  /// Use it to save [PreviewData] to the state and pass it back
  /// to the [LinkPreview.previewData] so the [LinkPreview] would not fetch
  /// preview data again.
  final void Function(PreviewData)? onPreviewDataFetched;

  /// Padding around initial text widget
  final EdgeInsets? padding;

  /// Pass saved [PreviewData] here so [LinkPreview] would not fetch preview
  /// data again
  final PreviewData? previewData;

  /// Text used for parsing
  final String text;

  /// Style of the provided text
  final TextStyle? textStyle;

  /// Width of the [LinkPreview] widget
  final double width;

  Future<PreviewData> _fetchData(String text) async {
    return await getPreviewData(text);
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  Widget _bodyWidget(PreviewData data, String text, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Linkify(
                linkifiers: [UrlLinkifier()],
                linkStyle: linkStyle,
                maxLines: 100,
                onOpen: _onOpen,
                options: const LinkifyOptions(
                  defaultToHttps: true,
                  humanize: false,
                  looseUrl: true,
                ),
                text: text,
                style: textStyle,
              ),
              if (data.title != null) _titleWidget(data.title!),
              if (data.description != null)
                _descriptionWidget(data.description!),
            ],
          ),
        ),
        if (data.image?.url != null) _imageWidget(data.image!.url, width),
      ],
    );
  }

  Widget _containerWidget({
    required double width,
    bool withPadding = false,
    required Widget child,
  }) {
    final _padding = padding ??
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        );

    return Container(
      constraints: BoxConstraints(maxWidth: width),
      padding: withPadding ? _padding : null,
      child: child,
    );
  }

  Widget _descriptionWidget(String description) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Text(
        description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: metadataTextStyle,
      ),
    );
  }

  Widget _imageWidget(String url, double width) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: width,
      ),
      width: width,
      margin: const EdgeInsets.only(top: 8),
      child: Image.network(
        url,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _minimizedBodyWidget(PreviewData data, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Linkify(
          linkifiers: [UrlLinkifier()],
          linkStyle: linkStyle,
          maxLines: 100,
          onOpen: _onOpen,
          options: const LinkifyOptions(
            defaultToHttps: true,
            humanize: false,
            looseUrl: true,
          ),
          text: text,
          style: textStyle,
        ),
        if (data.title != null || data.description != null)
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (data.title != null) _titleWidget(data.title!),
                      if (data.description != null)
                        _descriptionWidget(data.description!),
                    ],
                  ),
                ),
              ),
              if (data.image?.url != null)
                _minimizedImageWidget(data.image!.url),
            ],
          ),
      ],
    );
  }

  Widget _minimizedImageWidget(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(12),
      ),
      child: SizedBox(
        height: 48,
        width: 48,
        child: Image.network(url),
      ),
    );
  }

  Widget _plainTextWidget() {
    return _containerWidget(
      width: width,
      withPadding: true,
      child: Linkify(
        linkifiers: [UrlLinkifier()],
        linkStyle: linkStyle,
        maxLines: 100,
        onOpen: _onOpen,
        options: const LinkifyOptions(
          defaultToHttps: true,
          humanize: false,
          looseUrl: true,
        ),
        text: text,
        style: textStyle,
      ),
    );
  }

  Widget _titleWidget(String title) {
    final style = metadataTitleStyle ??
        const TextStyle(
          fontWeight: FontWeight.bold,
        );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _previewData = previewData != null
        ? Future<PreviewData>.value(previewData!)
        : _fetchData(text);

    return FutureBuilder<PreviewData>(
      initialData: null,
      future: _previewData,
      builder: (BuildContext context, AsyncSnapshot<PreviewData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            snapshot.data == null) return _plainTextWidget();

        onPreviewDataFetched?.call(snapshot.data!);

        final aspectRatio = snapshot.data!.image == null
            ? null
            : snapshot.data!.image!.width / snapshot.data!.image!.height;

        final _width = aspectRatio == 1 ? width : width - 32;

        return _containerWidget(
          width: width,
          withPadding: aspectRatio == 1,
          child: aspectRatio == 1
              ? _minimizedBodyWidget(snapshot.data!, text)
              : _bodyWidget(snapshot.data!, text, _width),
        );
      },
    );
  }
}
