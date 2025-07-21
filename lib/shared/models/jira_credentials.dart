class JiraCredentials {
  String? authCode;
  String? refreshToken;
  String? accessToken;
  String? accountId;
  String? cloudId;
  String? expireDate;
  String? email;
  String? avatarUrl;

  JiraCredentials({this.authCode, this.refreshToken, this.accessToken, this.accountId, this.cloudId, this.expireDate, this.email, this.avatarUrl});

  factory JiraCredentials.fromMap(Map<String, dynamic> map) {
    return JiraCredentials(
      authCode: map['auth-code'] as String?,
      refreshToken: map['refresh-token'] as String?,
      accessToken: map['access-token'] as String?,
      accountId: map['account-id'] as String?,
      email: map['email'] as String?,
      cloudId: map['cloud-id'] as String?,
      expireDate: map['expire-date'] as String?,
      avatarUrl: map['avatar-url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auth-code': authCode,
      'refresh-token': refreshToken,
      'access-token': accessToken,
      'email': email,
      'account-id': accountId,
      'cloud-id': cloudId,
      'expire-date': expireDate,
      'avatar-url': avatarUrl,
    };
  }
}
