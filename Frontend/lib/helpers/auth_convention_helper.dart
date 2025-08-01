import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

Future<bool> conventionEstValidee() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  final response = await http.get(
    Uri.parse("http://10.0.2.2:8081/api/convention/ma-convention"),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200 && response.body != "null") {
    final data = jsonDecode(response.body);
    return data["statut"] == "SIGNEE_VALIDEE";
  }

  return false;
}
