class BaseServices {
  // String get baseUrl {
  //   final uri = Uri.base;
  //   final scheme = uri.scheme;
  //   final host = uri.host;
  //   final port = uri.hasPort ? ':${uri.port}' : '';
  //   return '$scheme://$host$port/';
  // }
  final String clientId = 'zItLU1FUQJtfd2ZNzhk6j6XwNMohRpXJ';

  final String firebaseApiUrl = 'https://generatetokenfromemail-fvxqqvi45a-uc.a.run.app';
  final String firebaseJiraApiUrl = 'https://jiraauth-fvxqqvi45a-uc.a.run.app';

  Uri jiraApiAuthUrl(String url) => Uri.parse('https://api.atlassian.com/$url');
  //Note if you want use confluence instead of /jira/ put /confluence/
  Uri jiraApiUrl(String id, String url) => Uri.parse('https://api.atlassian.com/ex/jira/$id/$url');
}
