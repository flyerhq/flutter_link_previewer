import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static Future<Map<String, dynamic>?> getCachedPreviewData({
    required String key,
  }) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final result = sharedPreferences.getString(key);
    if (result == null) {
      return null;
    }
    //
    final previewDataWithDateOfCaching = jsonDecode(result);
    final dateOfCachingSinceEpoch =
        previewDataWithDateOfCaching['dateSinceEpoch'];
    if (DateTime.now().millisecondsSinceEpoch > dateOfCachingSinceEpoch) {
      deleteKey(key);
      debugPrint('############# Cached link is deleted successfully');
      return null;
    }
    debugPrint('############# Cached link is retrieved successfully');
    return previewDataWithDateOfCaching;
  }

  static Future deleteKey(String key, [dynamic takeAction]) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove(key).whenComplete(() => takeAction);
  }

  static Future cacheLink({
    required String key,
    required Map<String, dynamic> value,
    required Duration cachingDuration,
  }) async {
    //
    final sharedPreferences = await SharedPreferences.getInstance();
    final previewDataWithDateOfCaching = value;
    final expirationDate =
        DateTime.now().add(cachingDuration).millisecondsSinceEpoch;
    previewDataWithDateOfCaching['dateSinceEpoch'] = expirationDate;
    await sharedPreferences.setString(
      key,
      jsonEncode(previewDataWithDateOfCaching),
    );
    debugPrint('############# Link is cached successfully');
  }
}
