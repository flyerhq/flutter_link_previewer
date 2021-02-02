import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Example'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
                color: Color(0xFFf7f7f8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.all(
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
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
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
            )
          ],
        ),
      ),
    );
  }

  void _onPreviewDataFetched(PreviewData previewData) {
    print(previewData.link);
  }
}
