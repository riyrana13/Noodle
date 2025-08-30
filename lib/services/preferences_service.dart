import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _queryTypeKey = 'query_type';
  static const String _defaultQueryType = 'cpu';

  // Get the current query type preference
  static Future<String> getQueryType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_queryTypeKey) ?? _defaultQueryType;
  }

  // Set the query type preference
  static Future<void> setQueryType(String queryType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queryTypeKey, queryType);
  }

  // Get all available query types
  static List<String> getAvailableQueryTypes() {
    return ['cpu', 'gpu'];
  }

  // Get display name for query type
  static String getDisplayName(String queryType) {
    switch (queryType.toLowerCase()) {
      case 'cpu':
        return 'CPU';
      case 'gpu':
        return 'GPU';
      default:
        return 'CPU';
    }
  }

  // Get description for query type
  static String getDescription(String queryType) {
    switch (queryType.toLowerCase()) {
      case 'cpu':
        return 'Use CPU for processing (slower but more compatible)';
      case 'gpu':
        return 'Use GPU for processing (faster but requires GPU support)';
      default:
        return 'Use CPU for processing (slower but more compatible)';
    }
  }

  // Get icon for query type
  static String getIcon(String queryType) {
    switch (queryType.toLowerCase()) {
      case 'cpu':
        return '🖥️';
      case 'gpu':
        return '🚀';
      default:
        return '🖥️';
    }
  }
}
