library wallhaven;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class Meta {
  int currentPage;
  int lastPage;
  int perPage;
  int total;
  dynamic query;
  String? seed;

  Meta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.query,
    this.seed,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currentPage: json["current_page"],
      lastPage: json["last_page"],
      perPage: json["per_page"],
      total: json["total"],
      query: json["query"],
      seed: json["seed"],
    );
  }
}

class Settings {
  String purity;
  String categories;
  String resolutions;
  String toplistRange;

  Settings({
    required this.purity,
    required this.categories,
    required this.resolutions,
    required this.toplistRange,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      purity: json['purity'],
      categories: json['categories'],
      resolutions: json['resolutions'],
      toplistRange: json['toplist_range'],
    );
  }
}

class Tag {
  int id;
  String name;
  String alias;
  int categoryId;
  String category;
  String purity;
  String createdAt;

  Tag({
    required this.id,
    required this.name,
    required this.alias,
    required this.categoryId,
    required this.category,
    required this.purity,
    required this.createdAt,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      alias: json['alias'],
      categoryId: json['category_id'],
      category: json['category'],
      purity: json['purity'],
      createdAt: json['created_at'],
    );
  }
}

class Thumbs {
  String large;
  String original;
  String small;

  Thumbs({
    required this.large,
    required this.original,
    required this.small,
  });

  factory Thumbs.fromJson(Map<String, dynamic> json) => Thumbs(large: json["large"], original: json["original"], small: json["small"]);
}

class WallhavenClient {
  // The base URL for the API
  static const String _domain = 'wallhaven.cc';
  static const String _apiPath = "/api/v1";

  // The API key for authentication
  static String apiKey = "";

  WallhavenClient._();

  /// Download the wallpaper with the given ID
  static Future<Uint8List> download(String id) async {
    var wallpaper = await getWallpaper(id);
    return await wallpaper.download();
  }

  // A method that returns a list of collections for the user
  static Future<List<WallpaperCollection>> getCollections() async {
    if (apiKey.trim().isEmpty) {
      throw Exception('API key is required for this method');
    }
    var url = Uri.https(_domain, '$_apiPath/collections', _addApiKey({}));
    var client = http.Client();
    var response = await client.get(url);
    var data = _parseResponse(response);
    client.close();
    return (data as List).map((item) => WallpaperCollection.fromJson(item)).toList();
  }

  /// Returns a list of wallpapers in a collection by its ID and the username of the owner
  static Future<WallpaperSearch> getCollectionWallpapers(String username, int id, {String purity = "100", int page = 1}) async {
    var params = _addApiKey({'purity': purity, 'page': page.toString()});
    var client = http.Client();
    var url = Uri.https(_domain, '$_apiPath/collections/$username/$id', params);
    var response = await client.get(url);
    var data = _parseResponse(response);
    client.close();
    return data;
  }

  /// Returns the user's settings
  static Future<Settings> getSettings() async {
    if (apiKey.trim().isEmpty) {
      throw Exception('API key is required for this method');
    }
    var client = http.Client();
    var url = Uri.https(_domain, '$_apiPath/settings', _addApiKey({}));
    var response = await client.get(url);
    var data = _parseResponse(response);
    client.close();
    return Settings.fromJson(data);
  }

  /// Returns the details of a tag by its ID
  static Future<Tag> getTag(int id) async {
    var client = http.Client();
    var url = Uri.https(_domain, '$_apiPath/tag/$id', _addApiKey({}));
    var response = await client.get(url);
    var data = _parseResponse(response);
    client.close();
    return Tag.fromJson(data);
  }

  // A method that returns the details of a wallpaper by its ID
  static Future<Wallpaper> getWallpaper(String id) async {
    var client = http.Client();
    var url = Uri.https(_domain, '$_apiPath/w/$id', _addApiKey({}));
    var response = await client.get(url);
    var data = _parseResponse(response);
    client.close();

    return Wallpaper.fromJson(data);
  }

  static Future<WallpaperSearch> searchWallpapers(
    String query, {
    String categories = "111",
    String purity = "100",
    String sorting = "date_added",
    String order = "desc",
    String topRange = "",
    String atLeast = "",
    String resolutions = "",
    String ratios = "",
    String colors = "",
    int page = 1,
    String seed = "",
  }) async {
    var params = _addApiKey({
      'q': query,
      'categories': categories,
      'purity': purity,
      'sorting': sorting,
      'order': order,
      'topRange': topRange,
      'atleast': atLeast,
      'resolutions': resolutions,
      'ratios': ratios,
      'colors': colors,
      'page': page.toString(),
      'seed': seed,
    }..removeWhere((key, value) => value.trim().isEmpty));
    var client = http.Client();
    var url = Uri.https(_domain, '$_apiPath/search', params);
    var response = await client.get(url);
    var data = _parseResponse(response);
    client.close();
    return WallpaperSearch.fromJson(data);
  }

  // A method that returns a list of wallpapers based on the search parameters
  static Future<WallpaperSearch> searchWallpapersWith(WallpaperSearchParameters params) async => await searchWallpapers(
        params.query,
        categories: params.categoryString,
        purity: params.purityString,
        sorting: params.sorting.toString(),
        order: params.order.toString(),
        topRange: params.toprange,
        atLeast: params.atLeast,
        resolutions: params.resolutions,
        ratios: params.ratios,
        colors: params.colors,
        page: params.page,
        seed: params.seed,
      );

  // A helper method that adds the API key to the query parameters if present
  static Map<String, String> _addApiKey(Map<String, String> params) {
    if (apiKey.trim().isNotEmpty) {
      params['apikey'] = apiKey;
    }
    return params;
  }

  // A helper method that parses the JSON response and throws an exception if there is an error
  static dynamic _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }
}

class Wallpaper {
  String id;
  String url;
  String shortUrl;
  int views;
  int favorites;
  String source;
  String purity;
  String category;
  int dimensionX;
  int dimensionY;
  String resolution;
  String ratio;
  int fileSize;
  String fileType;
  String createdAt;
  List<String> colors;
  String path;
  Thumbs thumbs;

  Wallpaper({
    required this.id,
    required this.url,
    required this.shortUrl,
    required this.views,
    required this.favorites,
    required this.source,
    required this.purity,
    required this.category,
    required this.dimensionX,
    required this.dimensionY,
    required this.resolution,
    required this.ratio,
    required this.fileSize,
    required this.fileType,
    required this.createdAt,
    required this.colors,
    required this.path,
    required this.thumbs,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'],
      url: json['url'],
      shortUrl: json['short_url'],
      views: json['views'],
      favorites: json['favorites'],
      source: json['source'],
      purity: json['purity'],
      category: json['category'],
      dimensionX: json['dimension_x'],
      dimensionY: json['dimension_y'],
      resolution: json['resolution'],
      ratio: json['ratio'],
      fileSize: json['file_size'],
      fileType: json['file_type'],
      createdAt: json['created_at'],
      colors: List<String>.from(json['colors']),
      path: json['path'],
      thumbs: Thumbs.fromJson(json['thumbs']),
    );
  }

  Future<Uint8List> download() async {
    final response = await http.get(Uri.parse(path));
    return response.bodyBytes;
  }
}

enum WallpaperCategory {
  general,
  anime,
  people,
}

class WallpaperCollection {
  String id;
  String label;
  int count;
  String public;
  String url;

  WallpaperCollection({
    required this.id,
    required this.label,
    required this.count,
    required this.public,
    required this.url,
  });

  factory WallpaperCollection.fromJson(Map<String, dynamic> json) {
    return WallpaperCollection(
      id: json['id'],
      label: json['label'],
      count: json['count'],
      public: json['public'],
      url: json['url'],
    );
  }
}

enum WallpaperOrder {
  asc,
  desc;

  @override
  String toString() {
    switch (this) {
      case WallpaperOrder.asc:
        return 'asc';
      case WallpaperOrder.desc:
        return 'desc';
    }
  }
}

enum WallpaperPurity {
  sfw,
  sketchy,
  nsfw,
}

class WallpaperSearch {
  List<Wallpaper> data;
  Meta meta;

  WallpaperSearch({required this.data, required this.meta});

  factory WallpaperSearch.fromJson(Map<String, dynamic> json) {
    return WallpaperSearch(
      data: (json["data"] as List).map((item) => Wallpaper.fromJson(item)).toList(),
      meta: Meta.fromJson(json["meta"]),
    );
  }
}

class WallpaperSearchParameters {
  String query = '';
  WallpaperSorting sorting = WallpaperSorting.dateAdded;
  WallpaperOrder order = WallpaperOrder.desc;
  String toprange = '1M';
  int page = 1;
  String atLeast = "";
  String resolutions = "";
  String ratios = "";
  String colors = "";

  String seed = '';

  List<WallpaperCategory> categories = [WallpaperCategory.general, WallpaperCategory.anime, WallpaperCategory.people];

  List<WallpaperPurity> purities = [WallpaperPurity.sfw];

  String get categoryString {
    return [
      categories.contains(WallpaperCategory.general) ? '1' : '0',
      categories.contains(WallpaperCategory.anime) ? '1' : '0',
      categories.contains(WallpaperCategory.people) ? '1' : '0',
    ].join('');
  }

  String get purityString {
    return [
      purities.contains(WallpaperPurity.sfw) ? '1' : '0',
      purities.contains(WallpaperPurity.sketchy) ? '1' : '0',
      purities.contains(WallpaperPurity.nsfw) ? '1' : '0',
    ].join('');
  }
}

enum WallpaperSorting {
  dateAdded,
  relevance,
  random,
  views,
  favorites,
  toplist;

  @override
  String toString() {
    switch (this) {
      case WallpaperSorting.dateAdded:
        return 'date_added';
      case WallpaperSorting.relevance:
        return 'relevance';
      case WallpaperSorting.random:
        return 'random';
      case WallpaperSorting.views:
        return 'views';
      case WallpaperSorting.favorites:
        return 'favorites';
      case WallpaperSorting.toplist:
        return 'toplist';
    }
  }
}
