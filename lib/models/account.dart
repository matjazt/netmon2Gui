/// Mirrors AccountDto returned by GET /api/accounts/* and /api/accounts/me.
class Account {
  final int id;
  final String username;
  final int accountTypeId;
  final String accountTypeName;
  final String? fullName;
  final String? email;
  final DateTime? createdAt;
  final DateTime? lastSeen;

  const Account({
    required this.id,
    required this.username,
    required this.accountTypeId,
    required this.accountTypeName,
    this.fullName,
    this.email,
    this.createdAt,
    this.lastSeen,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as int,
        username: json['username'] as String,
        accountTypeId: json['accountTypeId'] as int,
        accountTypeName: json['accountTypeName'] as String,
        fullName: json['fullName'] as String?,
        email: json['email'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        lastSeen: json['lastSeen'] != null
            ? DateTime.parse(json['lastSeen'] as String)
            : null,
      );
}

/// Used when creating or updating an account (POST/PUT /api/accounts).
class SaveAccountRequest {
  final String username;
  final int accountTypeId;
  /// Plain-text password; cleared field means "do not change" on updates.
  final String? password;
  final String? fullName;
  final String? email;

  const SaveAccountRequest({
    required this.username,
    required this.accountTypeId,
    this.password,
    this.fullName,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'accountTypeId': accountTypeId,
        if (password != null && password!.isNotEmpty) 'password': password,
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
      };
}
