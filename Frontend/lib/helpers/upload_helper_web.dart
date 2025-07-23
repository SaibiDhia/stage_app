import 'dart:html' as html;

Future<void> uploadAdminFile({
  required int id,
  required String token,
  required Function onRefresh,
}) async {
  final input = html.FileUploadInputElement()..accept = '.pdf';
  input.click();

  input.onChange.listen((e) async {
    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    await reader.onLoadEnd.first;

    final url =
        Uri.parse('http://192.168.0.127:8081/api/convention/$id/upload-admin');
    final request = html.HttpRequest();
    request.open("POST", url.toString());
    request.setRequestHeader("Authorization", token);

    final formData = html.FormData();
    formData.appendBlob("file", file, file.name);

    request.send(formData);

    request.onLoadEnd.listen((event) {
      onRefresh();
    });
  });
}
