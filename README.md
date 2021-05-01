# Flutter Link Previewer

[![Pub](https://img.shields.io/pub/v/flutter_link_previewer)](https://pub.dartlang.org/packages/flutter_link_previewer)
[![build](https://github.com/flyerhq/flutter_link_previewer/workflows/build/badge.svg)](https://github.com/flyerhq/flutter_link_previewer/actions?query=workflow%3Abuild)
[![CodeFactor](https://www.codefactor.io/repository/github/flyerhq/flutter_link_previewer/badge)](https://www.codefactor.io/repository/github/flyerhq/flutter_link_previewer)

Preview of the link extracted from the provided text with basic customization and ability to render from cached data.

<img src="https://user-images.githubusercontent.com/14123304/116777066-81743a80-aa6c-11eb-89bc-d4166c418878.png" width="428" height="926">

## Getting Started

```dart
LinkPreview(
  onPreviewDataFetched: _onPreviewDataFetched,
  text: 'https://github.com/flyerhq',
  width: MediaQuery.of(context).size.width,
)
```

## Customization

```dart
final style = TextStyle(
  color: Colors.red,
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.375,
);


LinkPreview(
  linkStyle: style,
  metadataTextStyle: style.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  ),
  metadataTitleStyle: style.copyWith(
    fontWeight: FontWeight.w800,
  ),
  padding: EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  ),
  onPreviewDataFetched: _onPreviewDataFetched,
  text: 'https://github.com/flyerhq',
  textStyle: style,
  width: width,
);
```

## Render from cached data

Store the data you receive from `onPreviewDataFetched` callback, then

```dart
LinkPreview(
  previewData: _cachedData,
  text: 'https://github.com/flyerhq',
  width: MediaQuery.of(context).size.width,
)
```

## License

[MIT](LICENSE)
