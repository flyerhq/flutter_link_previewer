import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/src/types.dart';
import 'package:flutter_link_previewer/src/utils.dart';
import 'package:flutter_link_previewer/src/url_linkifier.dart';
import 'package:flutter_linkify/flutter_linkify.dart' hide UrlLinkifier;
import 'package:url_launcher/url_launcher.dart';

class LinkPreview extends StatefulWidget {
  const LinkPreview({
    Key key,
    this.onPreviewDataFetched,
    @required this.text,
    @required this.width,
  })  : assert(text != null),
        assert(width != null),
        super(key: key);

  final void Function(PreviewData) onPreviewDataFetched;
  final String text;
  final double width;

  @override
  _LinkPreviewState createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  Future<PreviewData> _data;

  @override
  void initState() {
    super.initState();
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

  Widget _containerWidget(double width, Widget child,
      {bool withPadding = false}) {
    return Container(
        constraints: BoxConstraints(maxWidth: width),
        padding: withPadding
            ? EdgeInsets.symmetric(vertical: 16, horizontal: 24)
            : null,
        child: child);
  }

  Widget _bodyWidget(
      AsyncSnapshot<PreviewData> snapshot, String text, double width) {
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
                maxLines: 100,
                onOpen: _onOpen,
                options: LinkifyOptions(
                  defaultToHttps: true,
                  humanize: false,
                  looseUrl: true,
                ),
                text: text,
              ),
              if (snapshot.data.title != null)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: _titleWidget(
                    snapshot.data.title,
                  ),
                ),
              if (snapshot.data.description != null)
                _descriptionWidget(
                  snapshot.data.description,
                ),
            ],
          ),
        ),
        if (snapshot.data.image?.url != null)
          _imageWidget(
            snapshot.data.image.url,
            width: width,
          ),
      ],
    );
  }

  Widget _minimizedBodyWidget(
      AsyncSnapshot<PreviewData> snapshot, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Linkify(
          linkifiers: [UrlLinkifier()],
          maxLines: 100,
          onOpen: _onOpen,
          options: LinkifyOptions(
            defaultToHttps: true,
            humanize: false,
            looseUrl: true,
          ),
          text: text,
        ),
        if (snapshot.data.title != null || snapshot.data.description != null)
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
                      if (snapshot.data.title != null)
                        _titleWidget(
                          snapshot.data.title,
                        ),
                      if (snapshot.data.description != null)
                        _descriptionWidget(
                          snapshot.data.description,
                        ),
                    ],
                  ),
                ),
              ),
              if (snapshot.data.image?.url != null)
                _minimizedImageWidget(snapshot.data.image.url),
            ],
          ),
      ],
    );
  }

  Widget _titleWidget(String title) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _descriptionWidget(String description) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: Text(
        description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _imageWidget(String url, {double width}) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: width,
        ),
        width: width,
        margin: EdgeInsets.only(top: 8),
        color: Color(0xfff7f7f8),
        child: Image.network(
          url,
          fit: BoxFit.fitWidth,
        ),
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
        color: Color(0xfff7f7f8),
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
              ? _minimizedBodyWidget(snapshot, widget.text)
              : _bodyWidget(snapshot, widget.text, width),
          withPadding: aspectRatio == 1,
        );
      },
    );
  }
}
