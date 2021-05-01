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
class LinkPreview extends StatefulWidget {
  /// Creates [LinkPreview]
  const LinkPreview({
    Key? key,
    this.animationDuration,
    this.enableAnimation = false,
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

  /// Expand animation duration
  final Duration? animationDuration;

  /// Enables expand animation. Default value is false.
  final bool? enableAnimation;

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

  @override
  _LinkPreviewState createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: widget.animationDuration ?? const Duration(milliseconds: 300),
    vsync: this,
  )..forward();

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutQuad,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<PreviewData> _fetchData(String text) async {
    final previewData = await getPreviewData(text);
    _handlePreviewDataFetched(previewData);
    return previewData;
  }

  void _handlePreviewDataFetched(PreviewData previewData) {
    Future.delayed(
      widget.animationDuration ?? const Duration(milliseconds: 300),
    ).then((_) {
      if (mounted) {
        widget.onPreviewDataFetched?.call(previewData);
      }
    });
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  Widget _animated(Widget child) {
    return SizeTransition(
      axis: Axis.vertical,
      axisAlignment: -1,
      sizeFactor: _animation,
      child: child,
    );
  }

  Widget _bodyWidget(PreviewData data, String text, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(
            bottom: 16,
            left: 24,
            right: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
    required bool animate,
    bool withPadding = false,
    Widget? child,
  }) {
    final _padding = widget.padding ??
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        );

    final shouldAnimate = widget.enableAnimation == true && animate;

    return Container(
      constraints: BoxConstraints(maxWidth: widget.width),
      padding: withPadding ? _padding : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: withPadding
                ? const EdgeInsets.all(0)
                : const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linkify(),
                if (withPadding && child != null)
                  shouldAnimate ? _animated(child) : child,
              ],
            ),
          ),
          if (!withPadding && child != null)
            shouldAnimate ? _animated(child) : child,
        ],
      ),
    );
  }

  Widget _descriptionWidget(String description) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Text(
        description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: widget.metadataTextStyle,
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

  Widget _linkify() {
    return Linkify(
      linkifiers: [UrlLinkifier()],
      linkStyle: widget.linkStyle,
      maxLines: 100,
      onOpen: _onOpen,
      options: const LinkifyOptions(
        defaultToHttps: true,
        humanize: false,
        looseUrl: true,
      ),
      text: widget.text,
      style: widget.textStyle,
    );
  }

  Widget _minimizedBodyWidget(PreviewData data, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title != null || data.description != null)
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (data.title != null)
                        _titleWidget(data.title!, withMargin: true),
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

  Widget _titleWidget(String title, {bool withMargin = false}) {
    final style = widget.metadataTitleStyle ??
        const TextStyle(
          fontWeight: FontWeight.bold,
        );

    return Container(
      margin: withMargin ? const EdgeInsets.only(top: 16) : null,
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
    final _previewData = widget.previewData != null
        ? Future<PreviewData>.value(widget.previewData!)
        : _fetchData(widget.text);

    return FutureBuilder<PreviewData>(
      initialData: widget.previewData,
      future: _previewData,
      builder: (BuildContext context, AsyncSnapshot<PreviewData> snapshot) {
        if (snapshot.data == null) return _containerWidget(animate: false);

        final aspectRatio = snapshot.data!.image == null
            ? null
            : snapshot.data!.image!.width / snapshot.data!.image!.height;

        final _width = aspectRatio == 1 ? widget.width : widget.width - 32;

        return _containerWidget(
          animate: widget.previewData == null,
          child: aspectRatio == 1
              ? _minimizedBodyWidget(snapshot.data!, widget.text)
              : _bodyWidget(snapshot.data!, widget.text, _width),
          withPadding: aspectRatio == 1,
        );
      },
    );
  }
}
