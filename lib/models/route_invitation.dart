class RouteInvitation {
  const RouteInvitation({
    required this.id,
    required this.routeId,
    required this.title,
    required this.role,
    this.token,
    this.ownerName = '同行者',
    this.email,
    this.expiresAt,
    this.available = true,
  });
  final String id;
  final String routeId;
  final String title;
  final String role;
  final String? token;
  final String ownerName;
  final String? email;
  final DateTime? expiresAt;
  final bool available;
  String get roleLabel => role == 'editor' ? '共同编辑' : '只读查看';
  factory RouteInvitation.fromMap(Map<String, dynamic> row) => RouteInvitation(
    id: row['id'] as String,
    routeId: row['route_id'] as String,
    title: row['title'] as String? ?? '邀请同行',
    role: row['role'] as String,
    token: row['token'] as String?,
    ownerName: row['owner_name'] as String? ?? '同行者',
    email: row['invited_email'] as String?,
    expiresAt: DateTime.tryParse(row['expires_at'] as String? ?? ''),
    available: row['available'] != false,
  );
}
