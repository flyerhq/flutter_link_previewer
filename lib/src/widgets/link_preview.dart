import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:flutter_link_previewer/src/utils.dart';
import 'package:flutter_link_previewer/src/url_linkifier.dart';
import 'package:flutter_linkify/flutter_linkify.dart' hide UrlLinkifier;
import 'package:url_launcher/url_launcher.dart';

@immutable
class LinkPreview extends StatelessWidget {
  const LinkPreview({
    Key key,
    this.linkStyle,
    this.metadataTextStyle,
    this.metadataTitleStyle,
    this.onPreviewDataFetched,
    this.padding,
    this.previewData,
    @required this.text,
    this.textStyle,
    @required this.width,
  })  : assert(text != null),
        assert(width != null),
        super(key: key);

  final TextStyle linkStyle;
  final TextStyle metadataTextStyle;
  final TextStyle metadataTitleStyle;
  final void Function(PreviewData) onPreviewDataFetched;
  final EdgeInsets padding;
  final PreviewData previewData;
  final String text;
  final TextStyle textStyle;
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

  Widget _containerWidget(
    double width,
    Widget child, {
    bool withPadding = false,
  }) {
    final _padding =
        padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24);

    return Container(
      constraints: BoxConstraints(maxWidth: width),
      padding: withPadding ? _padding : null,
      child: child,
    );
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
                options: LinkifyOptions(
                  defaultToHttps: true,
                  humanize: false,
                  looseUrl: true,
                ),
                text: text,
                style: textStyle,
              ),
              if (data.title != null)
                _titleWidget(
                  data.title,
                ),
              if (data.description != null)
                _descriptionWidget(
                  data.description,
                ),
            ],
          ),
        ),
        if (data.image?.url != null)
          _imageWidget(
            data.image.url,
            width: width,
          ),
      ],
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
          options: LinkifyOptions(
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
                      if (data.title != null)
                        _titleWidget(
                          data.title,
                        ),
                      if (data.description != null)
                        _descriptionWidget(
                          data.description,
                        ),
                    ],
                  ),
                ),
              ),
              if (data.image?.url != null)
                _minimizedImageWidget(data.image.url),
            ],
          ),
      ],
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

  Widget _imageWidget(String url, {double width}) {
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

  Widget _minimizedImageWidget(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(4),
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
      width,
      Linkify(
        linkifiers: [UrlLinkifier()],
        linkStyle: linkStyle,
        maxLines: 100,
        onOpen: _onOpen,
        options: LinkifyOptions(
          defaultToHttps: true,
          humanize: false,
          looseUrl: true,
        ),
        text: text,
        style: textStyle,
      ),
      withPadding: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _previewData = previewData != null
        ? Future<PreviewData>.value(previewData)
        : _fetchData(text);

    return FutureBuilder<PreviewData>(
      initialData: null,
      future: _previewData,
      builder: (BuildContext context, AsyncSnapshot<PreviewData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) return _plainTextWidget();

        if (onPreviewDataFetched != null) onPreviewDataFetched(snapshot.data);

        final aspectRatio = snapshot.data.image == null
            ? null
            : snapshot.data.image.width / snapshot.data.image.height;

        final _width = aspectRatio == 1 ? width : width - 32;

        return _containerWidget(
          width,
          aspectRatio == 1
              ? _minimizedBodyWidget(snapshot.data, text)
              : _bodyWidget(snapshot.data, text, _width),
          withPadding: aspectRatio == 1,
        );
      },
    );
  }
}
