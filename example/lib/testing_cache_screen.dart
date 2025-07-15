import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';

class TestingCacheScreen extends StatefulWidget {
  const TestingCacheScreen({super.key});

  @override
  State<TestingCacheScreen> createState() => _TestingCacheScreenState();
}

class _TestingCacheScreenState extends State<TestingCacheScreen> {
  Map<String, PreviewData> datas = {};

  List<String> get urls => const [
        'github.com/flyerhq',
        'https://u24.gov.ua',
        'https://twitter.com/SpaceX/status/1564975288655630338',
      ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: ListView.builder(
          itemCount: urls.length,
          itemBuilder: (context, index) => Align(
            alignment: Alignment.centerLeft,
            child: Container(
              key: ValueKey(urls[index]),
              margin: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(20),
                ),
                color: Color(0xfff7f7f8),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(20),
                ),
                child: LinkPreview(
                  enableAnimation: true,
                  // enableCaching: false,
                  onPreviewDataFetched: (data) {
                    setState(() {
                      datas = {
                        ...datas,
                        urls[index]: data,
                      };
                    });
                  },
                  previewData: datas[urls[index]],
                  text: urls[index],
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
          ),
        ),
      );
}
