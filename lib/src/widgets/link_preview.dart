import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' show LinkPreviewData;
import 'package:flutter_linkify/flutter_linkify.dart' hide UrlLinkifier;
import 'package:url_launcher/url_launcher.dart';

import '../url_linkifier.dart' show UrlLinkifier;
import '../utils.dart' show getLinkPreviewData;
import 'shrinkable_column.dart';

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
    this.hideImage = false,
    this.hideTitle = false,
    this.hideDescription = false,
    this.hideText = false,
    this.imageBuilder,
    this.linkStyle,
    this.metadataTextStyle,
    this.metadataTitleStyle,
    this.onLinkPressed,
    required this.onLinkPreviewDataFetched,
    this.openOnPreviewImageTap = false,
    this.openOnPreviewTitleTap = false,
    this.padding = const EdgeInsets.all(16),
    this.previewBuilder,
    this.linkPreviewData,
    this.requestTimeout,
    required this.text,
    this.textStyle,
    this.textWidget,
    this.userAgent,
    this.width = double.infinity,
    this.spaceBetweenTopWidgetsAndPreview = 16,
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
  final bool hideImage;

  /// Hides title data from the preview.
  final bool hideTitle;

  /// Hides description data from the preview.
  final bool hideDescription;

  /// Hides the linkified text.
  final bool hideText;

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

  /// Padding around the link preview widget.
  final EdgeInsets padding;

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

  /// Space between the Text and the link preview.
  final double spaceBetweenTopWidgetsAndPreview;

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

  Widget _bodyWidget(
    LinkPreviewData data,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap:
                widget.openOnPreviewTitleTap ? () => _onOpen(data.link) : null,
            child: ShrinkableColumn(
              padding: widget.padding.copyWith(top: 0),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (data.title != null && !widget.hideTitle)
                  _titleWidget(data.title!),
                if (data.description != null && !widget.hideDescription)
                  _descriptionWidget(data.description!),
              ],
            ),
          ),
          if (data.image != null && !widget.hideImage)
            _imageWidget(data.image!.url, data.link),
        ],
      );

  /// This widget encapsulates the top widgets and the preview body.
  Widget _containerWidget({
    required bool animate,
    bool applyPaddingToChild = false,
    Widget? child,
  }) {
    final padding = widget.padding;
    final shouldAnimate = widget.enableAnimation == true && animate;
    final topWidgets = _topWidgets();

    return Container(
      constraints: BoxConstraints(maxWidth: widget.width),
      padding: applyPaddingToChild ? padding : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: applyPaddingToChild
                ? EdgeInsets.zero
                : padding.copyWith(
                    bottom: topWidgets.isNotEmpty
                        ? widget.spaceBetweenTopWidgetsAndPreview
                        : 0,

                    /// Don't add padding to the top for images only
                    top: (_hasOnlyImage() && topWidgets.isEmpty)
                        ? 0
                        : padding.top,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._topWidgets(),
                if (applyPaddingToChild && child != null)
                  Padding(
                    padding: topWidgets.isNotEmpty
                        ? EdgeInsets.only(
                            top: widget.spaceBetweenTopWidgetsAndPreview,
                          )
                        : EdgeInsets.zero,
                    child: shouldAnimate ? _animated(child) : child,
                  ),
              ],
            ),
          ),
          if (!applyPaddingToChild && child != null)
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
      (widget.linkPreviewData?.title == null || widget.hideTitle) &&
      (widget.linkPreviewData?.description == null || widget.hideDescription) &&
      widget.linkPreviewData?.image != null;

  Widget _imageWidget(String imageUrl, String linkUrl) => GestureDetector(
        onTap: widget.openOnPreviewImageTap ? () => _onOpen(linkUrl) : null,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) => Container(
              constraints: BoxConstraints(
                maxHeight: math.min(widget.width, constraints.maxWidth),
              ),
              child: widget.imageBuilder != null
                  ? widget.imageBuilder!(imageUrl)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
            ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        if (data.title != null && !widget.hideTitle)
                          _titleWidget(data.title!),
                        if (data.description != null && !widget.hideDescription)
                          _descriptionWidget(data.description!),
                      ],
                    ),
                  ),
                ),
              ),
              if (data.image != null && !widget.hideImage)
                _minimizedImageWidget(data.image!.url, data.link),
            ],
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

  List<Widget> _topWidgets() => [
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
        if (widget.textWidget != null)
          widget.textWidget!
        else if (!widget.hideText)
          _linkify(),
      ];

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

        final useRowBodyWidget =
            aspectRatio == 1 && !(widget.hideTitle && widget.hideDescription);

        return _containerWidget(
          animate: shouldAnimate,
          child: useRowBodyWidget
              ? _minimizedBodyWidget(linkPreviewData)
              : _bodyWidget(linkPreviewData),
          applyPaddingToChild: useRowBodyWidget,
        );
      }
    } else {
      return _containerWidget(animate: false);
    }
  }
}
