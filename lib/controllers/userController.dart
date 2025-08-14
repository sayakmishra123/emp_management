import 'package:e_management/model/userdetails.dart';
import 'package:get/get.dart';
// import 'user_model.dart'; // import the UserModel

class UserController extends GetxController {
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  void setUser(UserModel user) {
    currentUser.value = user;
  }

  void clearUser() {
    currentUser.value = null;
  }
}
