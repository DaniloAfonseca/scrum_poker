class BaseServices {
  String get baseUrl {
    final uri = Uri.base;
    final scheme = uri.scheme;
    final host = uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$port/';
  }

  final String firebaseApiUrl = 'https://generatetokefromemail-fvxqqvi45a-uc.a.run.app';

  Uri jiraApiUrl(String url) => Uri.parse('https://api.atlassian.com/$url');
}
