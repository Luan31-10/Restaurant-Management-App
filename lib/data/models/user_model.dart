class UserModel {
  final int id;
  final String name;
  final String role;
  final String? accessToken;
  final bool adminChallenge; // THÊM TRƯỜNG NÀY ĐỂ BIẾT KHI NÀO CẦN XÁC THỰC BƯỚC 2

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.accessToken,
    this.adminChallenge = false, // Giá trị mặc định
  });

  static const empty = UserModel(id: 0, name: '', role: '');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      accessToken: json['accessToken'],
      adminChallenge: json['adminChallenge'] ?? false, // Xử lý null từ JSON
    );
  }
}