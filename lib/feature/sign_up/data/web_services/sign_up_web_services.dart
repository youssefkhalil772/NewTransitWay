import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/networking/api_constants.dart';
import '../models/sign_up_request_body.dart';

class SignUpWebServices {
  Future<http.Response> signUp(SignUpRequestBody signUpRequestBody, File? photo) async {
    final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.register}");
    
    var request = http.MultipartRequest('POST', url);
    
    // إضافة الحقول النصية
    request.fields['FullName'] = signUpRequestBody.fullName;
    request.fields['Email'] = signUpRequestBody.email;
    request.fields['Phone'] = signUpRequestBody.phone;
    request.fields['Password'] = signUpRequestBody.password;
    
    // إضافة الصورة إذا وجدت
    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('Photo', photo.path));
    }
    
    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}
