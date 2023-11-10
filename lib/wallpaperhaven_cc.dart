import 'dart:convert';
import 'package:http/http.dart' as http;

class WallhavenClient {
  // The base URL for the API
  static const String _baseUrl = 'https://wallhaven.cc/api/v1';

  // The API key for authentication
  static String apiKey = "";

  // The HTTP client for making requests
  late http.Client _client = _client = http.Client();

  // A helper method that adds the API key to the query parameters if present
  Map<String, String> _addApiKey(Map<String, String> params) {
    if (apiKey.trim().isNotEmpty) {
      params['apikey'] = apiKey;
    }
    return params;
  }

  // A helper method that parses the JSON response and throws an exception if there is an error
  dynamic _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  // A method that returns the details of a wallpaper by its ID
  Future<Wallpaper> getWallpaper(String id) async {
    var url = Uri.https(_baseUrl, '/w/$id', _addApiKey({}));
    var response = await _client.get(url);
    var data = _parseResponse(response);
    return Wallpaper.fromJson(data);
  }

  // A method that returns a list of wallpapers based on the search parameters
  Future<List<Wallpaper>> searchWallpapers(
    String query, {
    String categories,
    String purity,
    String sorting,
    String order,
    String topRange,
    String atLeast,
    String resolutions,
    String ratios,
    String colors,
    int page = 1,
    String seed,
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
    });
    var url = Uri.https(_baseUrl, '/search', params);
    var response = await _client.get(url);
    var data = _parseResponse(response);
    return (data as List).map((item) => Wallpaper.fromJson(item)).toList();
  }

  // A method that returns the details of a tag by its ID
  Future<Tag> getTag(int id) async {
    var url = Uri.https(_baseUrl, '/tag/$id', _addApiKey({}));
    var response = await _client.get(url);
    var data = _parseResponse(response);
    return Tag.fromJson(data);
  }

  // A method that returns the user's settings
  Future<Settings> getSettings() async {
    if (apiKey == null) {
      throw Exception('API key is required for this method');
    }
    var url = Uri.https(_baseUrl, '/settings', _addApiKey({}));
    var response = await _client.get(url);
    var data = _parseResponse(response);
    return Settings.fromJson(data);
  }

  // A method that returns a list of collections for the user
  Future<List<Collection>> getCollections() async {
    if (apiKey == null) {
      throw Exception('API key is required for this method');
    }
    var url = Uri.https(_baseUrl, '/collections', _addApiKey({}));
    var response = await _client.get(url);
    var data = _parseResponse(response);
    return (data as List).map((item) => Collection.fromJson(item)).toList();
  }

  // A method that returns a list of wallpapers in a collection by its ID and the username of the owner
  Future<List<Wallpaper>> getCollectionWallpapers(String username, int id, {String purity, int page}) async {
    var params = _addApiKey({'purity': purity, 'page': page?.toString()});
    var url = Uri.https(_baseUrl, '/collections/$username/$id', params);
    var response = await _client.get(url);
    var data = _parseResponse(response);
    return (data as List).map((item) => Wallpaper.fromJson(item)).toList();
  }

  // A method that closes the HTTP client
  void close() {
    _client.close();
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
  Map<String, String> thumbs;
  List<Tag> tags;

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
    required this.tags,
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
      colors: List<String>.from(json['colors'].map((x) => x)),
      path: json['path'],
      thumbs: Map<String, String>.from(json['thumbs']),
      tags: List<Tag>.from(json['tags'].map((x) => Tag.fromJson(x))),
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

class Collection {
  String id;
  String label;
  int count;
  String public;
  String url;

  Collection({
    required this.id,
    required this.label,
    required this.count,
    required this.public,
    required this.url,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'],
      label: json['label'],
      count: json['count'],
      public: json['public'],
      url: json['url'],
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
