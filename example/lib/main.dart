import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key key,
  }) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Example'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
                color: Color(0xFFf7f7f8),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
                child: LinkPreview(
                  onPreviewDataFetched: _onPreviewDataFetched,
                  text:
                      'https://dev.to/demchenkoalex/making-a-right-keyboard-accessory-view-in-react-native-4n3p',
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFf7f7f8),
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: LinkPreview(
                onPreviewDataFetched: _onPreviewDataFetched,
                text: 'instagram.com',
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPreviewDataFetched(PreviewData previewData) {
    print(previewData.link);
  }
}
