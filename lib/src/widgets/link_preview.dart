import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/src/types.dart';
import 'package:flutter_link_previewer/src/utils.dart';
import 'package:flutter_link_previewer/src/url_linkifier.dart';
import 'package:flutter_linkify/flutter_linkify.dart' hide UrlLinkifier;
import 'package:url_launcher/url_launcher.dart';

class LinkPreview extends StatefulWidget {
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

  @override
  _LinkPreviewState createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  Future<PreviewData> _data;

  @override
  void initState() {
    super.initState();

    if (widget.previewData != null) {
      _data = Future<PreviewData>.value(widget.previewData);
      return;
    }

    _data = _fetchData(widget.text);
  }

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
    final padding =
        widget.padding ?? EdgeInsets.symmetric(vertical: 16, horizontal: 24);

    return Container(
      constraints: BoxConstraints(maxWidth: width),
      padding: withPadding ? padding : null,
      child: child,
    );
  }

  Widget _bodyWidget(PreviewData data, String text, double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Linkify(
                linkifiers: [UrlLinkifier()],
                linkStyle: widget.linkStyle,
                maxLines: 100,
                onOpen: _onOpen,
                options: LinkifyOptions(
                  defaultToHttps: true,
                  humanize: false,
                  looseUrl: true,
                ),
                text: text,
                style: widget.textStyle,
              ),
              if (data.title != null)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: _titleWidget(
                    data.title,
                  ),
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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Linkify(
          linkifiers: [UrlLinkifier()],
          linkStyle: widget.linkStyle,
          maxLines: 100,
          onOpen: _onOpen,
          options: LinkifyOptions(
            defaultToHttps: true,
            humanize: false,
            looseUrl: true,
          ),
          text: text,
          style: widget.textStyle,
        ),
        if (data.title != null || data.description != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
    final style =
        widget.metadataTitleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Widget _descriptionWidget(String description) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: Text(
        description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: widget.metadataTextStyle,
      ),
    );
  }

  Widget _imageWidget(String url, {double width}) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: width,
      ),
      width: width,
      margin: EdgeInsets.only(top: 8),
      child: Image.network(
        url,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _minimizedImageWidget(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.all(
        Radius.circular(4),
      ),
      child: Container(
        height: 48,
        width: 48,
        child: Image.network(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PreviewData>(
      initialData: PreviewData(),
      future: _data,
      builder: (BuildContext context, AsyncSnapshot<PreviewData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Container();

        if (widget.onPreviewDataFetched != null)
          widget.onPreviewDataFetched(snapshot.data);

        final aspectRatio = snapshot.data.image == null
            ? null
            : snapshot.data.image.width / snapshot.data.image.height;

        final width = aspectRatio == 1 ? widget.width : widget.width - 32;

        return _containerWidget(
          widget.width,
          aspectRatio == 1
              ? _minimizedBodyWidget(snapshot.data, widget.text)
              : _bodyWidget(snapshot.data, widget.text, width),
          withPadding: aspectRatio == 1,
        );
      },
    );
  }
}
