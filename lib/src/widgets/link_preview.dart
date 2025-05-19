import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' show LinkPreviewData;
import 'package:flutter_linkify/flutter_linkify.dart' hide UrlLinkifier;
import 'package:url_launcher/url_launcher.dart';

import '../url_linkifier.dart' show UrlLinkifier;
import '../utils.dart' show getLinkPreviewData;

/// A widget that renders text with highlighted links.
/// Eventually unwraps to the full preview of the first found link
/// if the parsing was successful.
@immutable
class LinkPreview extends StatefulWidget {
  /// Creates [LinkPreview].
  const LinkPreview({
    super.key,
    this.animationDuration,
    this.corsProxy,
    this.enableAnimation = false,
    this.header,
    this.headerStyle,
    this.hideImage,
    this.imageBuilder,
    this.linkStyle,
    this.metadataTextStyle,
    this.metadataTitleStyle,
    this.onLinkPressed,
    required this.onLinkPreviewDataFetched,
    this.openOnPreviewImageTap = false,
    this.openOnPreviewTitleTap = false,
    this.padding,
    this.previewBuilder,
    this.linkPreviewData,
    this.requestTimeout,
    required this.text,
    this.textStyle,
    this.textWidget,
    this.userAgent,
    required this.width,
  });

  /// Expand animation duration.
  final Duration? animationDuration;

  /// CORS proxy to make more previews work on web. Not tested.
  final String? corsProxy;

  /// Enables expand animation. Default value is false.
  final bool? enableAnimation;

  /// Custom header above provided text.
  final String? header;

  /// Style of the custom header.
  final TextStyle? headerStyle;

  /// Hides image data from the preview.
  final bool? hideImage;

  /// Function that allows you to build a custom image.
  final Widget Function(String)? imageBuilder;

  /// Style of highlighted links in the text.
  final TextStyle? linkStyle;

  /// Style of preview's description.
  final TextStyle? metadataTextStyle;

  /// Style of preview's title.
  final TextStyle? metadataTitleStyle;

  /// Custom link press handler.
  final void Function(String)? onLinkPressed;

  /// Callback which is called when [LinkPreviewData] was successfully parsed.
  /// Use it to save [LinkPreviewData] to the state and pass it back
  /// to the [LinkPreview.LinkPreviewData] so the [LinkPreview] would not fetch
  /// preview data again.
  final void Function(LinkPreviewData?) onLinkPreviewDataFetched;

  /// Open the link when the link preview image is tapped. Defaults to false.
  final bool openOnPreviewImageTap;

  /// Open the link when the link preview title/description is tapped. Defaults to false.
  final bool openOnPreviewTitleTap;

  /// Padding around initial text widget.
  final EdgeInsets? padding;

  /// Function that allows you to build a custom link preview.
  final Widget Function(BuildContext, LinkPreviewData)? previewBuilder;

  /// Pass saved [LinkPreviewData] here so [LinkPreview] would not fetch preview
  /// data again.
  final LinkPreviewData? linkPreviewData;

  /// Request timeout after which the request will be cancelled. Defaults to 5 seconds.
  final Duration? requestTimeout;

  /// Text used for parsing.
  final String text;

  /// Style of the provided text.
  final TextStyle? textStyle;

  /// Widget to display above the preview. If null, defaults to a linkified [text].
  final Widget? textWidget;

  /// User agent to send as GET header when requesting link preview url.
  final String? userAgent;

  /// Width of the [LinkPreview] widget.
  final double width;

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview>
    with SingleTickerProviderStateMixin {
  bool isFetchingLinkPreviewData = false;
  bool shouldAnimate = false;

  late final Animation<double> _animation;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    );

    didUpdateWidget(widget);
  }

  Widget _animated(Widget child) => SizeTransition(
        axis: Axis.vertical,
        axisAlignment: -1,
        sizeFactor: _animation,
        child: child,
      );

  Widget _bodyWidget(LinkPreviewData data, double width) {
    final padding = widget.padding ??
        const EdgeInsets.only(
          bottom: 16,
          left: 24,
          right: 24,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: widget.openOnPreviewTitleTap ? () => _onOpen(data.link) : null,
          child: Container(
            padding: EdgeInsets.only(
              bottom: padding.bottom,
              left: padding.left,
              right: padding.right,
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
        ),
        if (data.image?.url != null && widget.hideImage != true)
          _imageWidget(data.image!.url, data.link!, width),
      ],
    );
  }

  Widget _containerWidget({
    required bool animate,
    bool withPadding = false,
    Widget? child,
  }) {
    final padding = widget.padding ??
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        );

    final shouldAnimate = widget.enableAnimation == true && animate;

    return Container(
      constraints: BoxConstraints(maxWidth: widget.width),
      padding: withPadding ? padding : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: withPadding
                ? EdgeInsets.zero
                : EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                    top: padding.top,
                    bottom: _hasOnlyImage() ? 0 : 16,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.header != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      widget.header!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.headerStyle,
                    ),
                  ),
                widget.textWidget ?? _linkify(),
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

  Widget _descriptionWidget(String description) => Container(
        margin: const EdgeInsets.only(top: 8),
        child: Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: widget.metadataTextStyle,
        ),
      );

  Future<LinkPreviewData?> _fetchData(String text) async {
    setState(() {
      isFetchingLinkPreviewData = true;
    });

    final linkPreviewData = await getLinkPreviewData(
      text,
      proxy: widget.corsProxy,
      requestTimeout: widget.requestTimeout,
      userAgent: widget.userAgent,
    );
    await _handleLinkPreviewDataFetched(linkPreviewData);
    return linkPreviewData;
  }

  Future<void> _handleLinkPreviewDataFetched(
    LinkPreviewData? linkPreviewData,
  ) async {
    await Future.delayed(
      widget.animationDuration ?? const Duration(milliseconds: 300),
    );

    if (mounted) {
      widget.onLinkPreviewDataFetched(linkPreviewData);
      setState(() {
        isFetchingLinkPreviewData = false;
      });
    }
  }

  bool _hasData(LinkPreviewData? linkPreviewData) =>
      linkPreviewData?.title != null ||
      linkPreviewData?.description != null ||
      linkPreviewData?.image != null;

  bool _hasOnlyImage() =>
      widget.linkPreviewData?.title == null &&
      widget.linkPreviewData?.description == null &&
      widget.linkPreviewData?.image != null;

  Widget _imageWidget(String imageUrl, String linkUrl, double width) =>
      GestureDetector(
        onTap: widget.openOnPreviewImageTap ? () => _onOpen(linkUrl) : null,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: width,
          ),
          width: width,
          child: widget.imageBuilder != null
              ? widget.imageBuilder!(imageUrl)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
        ),
      );

  Widget _linkify() => SelectableLinkify(
        linkifiers: const [EmailLinkifier(), UrlLinkifier()],
        linkStyle: widget.linkStyle,
        maxLines: 100,
        minLines: 1,
        onOpen: (link) => _onOpen(link.url),
        options: const LinkifyOptions(
          defaultToHttps: true,
          humanize: false,
          looseUrl: true,
        ),
        text: widget.text,
        style: widget.textStyle,
      );

  Widget _minimizedBodyWidget(LinkPreviewData data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title != null || data.description != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.openOnPreviewTitleTap
                          ? () => _onOpen(data.link)
                          : null,
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
                  ),
                  if (data.image?.url != null && widget.hideImage != true)
                    _minimizedImageWidget(data.image!.url, data.link),
                ],
              ),
            ),
        ],
      );

  Widget _minimizedImageWidget(String imageUrl, String linkUrl) => ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
        child: GestureDetector(
          onTap: widget.openOnPreviewImageTap ? () => _onOpen(linkUrl) : null,
          child: SizedBox(
            height: 48,
            width: 48,
            child: widget.imageBuilder != null
                ? widget.imageBuilder!(imageUrl)
                : Image.network(imageUrl),
          ),
        ),
      );

  Future<void> _onOpen(String url) async {
    if (widget.onLinkPressed != null) {
      widget.onLinkPressed!(url);
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _titleWidget(String title) {
    final style = widget.metadataTitleStyle ??
        const TextStyle(
          fontWeight: FontWeight.bold,
        );

    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  @override
  void didUpdateWidget(covariant LinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!isFetchingLinkPreviewData && widget.linkPreviewData == null) {
      _fetchData(widget.text);
    }

    if (widget.linkPreviewData != null && oldWidget.linkPreviewData == null) {
      setState(() {
        shouldAnimate = true;
      });
      _controller.reset();
      _controller.forward();
    } else if (widget.linkPreviewData != null) {
      setState(() {
        shouldAnimate = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkPreviewData = widget.linkPreviewData;

    if (linkPreviewData != null && _hasData(linkPreviewData)) {
      if (widget.previewBuilder != null) {
        return widget.previewBuilder!(context, linkPreviewData);
      } else {
        final aspectRatio = widget.linkPreviewData!.image == null
            ? null
            : widget.linkPreviewData!.image!.width /
                widget.linkPreviewData!.image!.height;

        final width = aspectRatio == 1 ? widget.width : widget.width - 32;

        return _containerWidget(
          animate: shouldAnimate,
          child: aspectRatio == 1
              ? _minimizedBodyWidget(linkPreviewData)
              : _bodyWidget(linkPreviewData, width),
          withPadding: aspectRatio == 1,
        );
      }
    } else {
      return _containerWidget(animate: false);
    }
  }
}
