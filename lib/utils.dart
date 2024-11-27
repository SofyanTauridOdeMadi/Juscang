import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

// FCM
const Map<String, dynamic> firebaseServiceAccountKey = {
  "type": "service_account",
  "project_id": "stom-juscang",
  "private_key_id": "6f4a3db81e302cca8a21535ce725a2bfdb61dbb4",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC2eU/qaCRyykeY\nmPAXL+cQOqfXjgj0X6Bj9BAxd8teJb9NY2VgvC4FeMEYRMp2EL/EVd/hYt3IoYbt\nxnJKY1zxGdTWi5LKH9LSs4DwNBFFcX2co9NyhyeodxZEvI4cSRsrsmiXr1NRApsp\n7XT05ZxirM0eKGu3UW5ASnIV2WAxJT88Ss4m/49R+1bvXHoYJQobd0xv6FBrp9YK\nDqciryQYERU9Pf5QwirKN0G3iVudw/Ee6V/EkV88gXKsszSm7pXUpu37dx1GuTw4\n2LxXopD6ALHyRQVU/bDvJb1XgSauNKhTik8yyz5fI4I1pcEdJhnolo/iibkfo8mF\nxx/D+Wx/AgMBAAECggEAOPmR8WAJGWp9hnEibir/27pk09I+i4ccPnljYP7FmiTx\nIYnKirTXLdAxgpFgIhNCvVwO5oIHO/Drf2y6HO3/hCyLn12/PKtJGY8A0H+BcQxp\nqzIgAJ+gy2I7qsSxHrXY7QDs1Yfh3OaSajoBjcHv3YOVHDiEwZ2EbkCQdLAF7/Ho\n69XLhr80B7Ooeo6PuDYgPD6ieRWiMikdBSxJ5bwmeTXYaE0wOftHd3x+ZIrALBZG\nQQ6BuBIKHt5ci+iYkap97f8pppB6cP5Yc01kGWb8FtQC4mGoeE6ZCBDZZPBnNHqo\n6+Z6XjR0QKWp1TefJ+Gy5DbZ/AsGEu/06mlYyEMCsQKBgQDqiDf+kcEo+avVNAoK\nPZNugNna7VTo09Xorjo7eCDluJZA/3grbIJObDgCXO+i8kvuFD5nHxb1TPvF6ugK\neC+YKh5riB9NUq/0/MqXb2oZHUJjLVN5/mUInq3zW9E3D1HJKYHuisiubBYTniL/\nwPnu4BP4uQtP62WsQUgkQ61S+QKBgQDHLTcPur2iGILyfDGxnHgbJ7vY39bh1aet\nZuwwfefNiYxZL/QuQLhK7KQV+BeHhL5af2SKZc2n0CpEzgocbi96EDQ4ETW/GItR\nco1uq8HAQyCK9uDR3BgCSxCfY1A0aq6cYHKplVJcPiQOqeho98dMuYw7xmlUWYkk\nFMP/8n6hNwKBgQDN8F0SyVPOsiWjqfVi9pzd/IDPz3SumUyM62gwzhQ9A2/UlT8l\nCjwFttsboBXAhHgOD3KYRGF5dmbibJnij5RjTiC2Fao+0Gu3eL5AaVHFyb6Arc1O\nIwb+oa9nMOmuKmKLfEoed3kuR7S+9y4OW5pbmiGPVpVLUQ1PS2eYiGDKqQKBgAz+\n0jzgfkb5OnH/0G46O0vqR8Nat3Z8rjgOIxL25AzxEIsxKclqx5t73Sjhywc4jgLx\nlOnCwqxUVK2wk9BPECHytLWDyfHx9AUYaEn0Quv8dT8b5IdMyPQ9WZRMsor4+vOR\nB2oxJ/KEy215gIR4xjQnVxL/Wxf5z4zfHfqxI7n5AoGBAKolYvMNgr/lYF5EvLEs\n5dNGMmtHBeG3HR+VYLjT6gKVLrhfdJhc4LtvhpuOZpPEmAj9fuDZrHZ5r+50KbuU\n3JS9PJ+w1qUmx6qzJIiRB0SUJWY4VxNObykyER68HigkTKz5/FUa/RH48XcyhUUu\nwu+G2io0ccBjYq9qsS01xYj0\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-volux@stom-juscang.iam.gserviceaccount.com",
  "client_id": "111762934565070538603",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-volux@stom-juscang.iam.gserviceaccount.com",
};

Future<void> kirimNotifikasi(
    String tokenPenerima,
    String judul,
    String isi,
    Map<String, String> data,
    ) async {
  try {
    final jsonKey = firebaseServiceAccountKey;

    // Dapatkan token otorisasi
    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': _generateJwt(jsonKey),
      },
    );

    if (response.statusCode == 200) {
      final accessToken = json.decode(response.body)['access_token'];

      // Kirim notifikasi ke FCM
      final notifikasi = {
        'message': {
          'token': tokenPenerima,
          'notification': {
            'title': judul,
            'body': isi,
          },
          'data': data,
        },
      };

      final fcmResponse = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/${jsonKey['project_id']}/messages:send'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(notifikasi),
      );

      if (fcmResponse.statusCode == 200) {
        print('Notifikasi berhasil dikirim');
      } else {
        print('Gagal mengirim notifikasi: ${fcmResponse.body}');
      }
    } else {
      print('Gagal mendapatkan token: ${response.body}');
    }
  } catch (e) {
    print("Error saat mengirim notifikasi: $e");
  }
}

String _generateJwt(Map<String, dynamic> jsonKey) {
  final claims = {
    'iss': jsonKey['client_email'],
    'scope': 'https://www.googleapis.com/auth/firebase.messaging',
    'aud': jsonKey['token_uri'],
    'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600, // 1 jam
    'iat': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
  };

  final privateKeyPem = jsonKey['private_key'];
  final rsaPrivateKey = RSAPrivateKey(privateKeyPem);

  final jwt = JWT(claims);
  final token = jwt.sign(rsaPrivateKey, algorithm: JWTAlgorithm.RS256);

  return token;
}