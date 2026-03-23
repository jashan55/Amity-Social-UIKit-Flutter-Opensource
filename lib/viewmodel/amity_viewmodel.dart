import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../components/alert_dialog.dart';

class AmityVM extends ChangeNotifier {
  AmityUser? currentamityUser;

  /// Creates a login builder with the shared session handler
  dynamic _createLoginBuilder(String userID) {
    return AmityCoreClient.login(userID, sessionHandler: (AccessTokenRenewal renewal) {
      renewal.renew();
    });
  }

  /// Handles the login response and error cases
  Future<void> _handleLoginResponse(Future<AmityUser> loginFuture) async {
    await loginFuture.then((value) async {
      log("success");
      currentamityUser = value;
      notifyListeners();
    }).catchError((error, stackTrace) async {
      log("error");
      log(error.toString());
      //        await AmityDialog()
      //            .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  Future<void> login(
      {required String userID,
      String? displayName,
      String? authToken,
      String? avatarUrl}) async {
    log("login with $userID");

    // Create the base login builder
    var loginBuilder = _createLoginBuilder(userID);

    // Add authToken if provided
    if (authToken != null) {
      log("authToken is provided");
      loginBuilder = loginBuilder.authToken(authToken);
    } else {
      log("authToken == null");
    }

    // Add displayName if provided
    if (displayName != null) {
      log("displayName is provided");
      loginBuilder = loginBuilder.displayName(displayName);
    } else if (authToken != null) {
      log("displayName is not provided");
    }

    // Submit and handle the response
    await _handleLoginResponse(loginBuilder.submit());

    // Sync avatar to Amity in the background whenever a URL is provided
    if (avatarUrl != null && avatarUrl.isNotEmpty && currentamityUser != null) {
      // Fire-and-forget so login isn't delayed by the upload
      _syncAvatarFromUrl(avatarUrl);
    }
  }

  /// Downloads an image from [url], uploads it to Amity's file repository,
  /// and sets it as the current user's avatar.
  Future<void> _syncAvatarFromUrl(String url) async {
    try {
      log("syncAvatar: downloading from $url");

      // Download image to a temp file
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        log("syncAvatar: download failed with status ${response.statusCode}");
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/amity_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final bytes = await response.fold<List<int>>([], (list, chunk) => list..addAll(chunk));
      await tempFile.writeAsBytes(bytes);

      // Upload to Amity file repository
      final completer = Completer<String?>();
      AmityCoreClient.newFileRepository()
          .uploadImage(tempFile)
          .stream
          .listen((amityUploadResult) {
        amityUploadResult.when(
          progress: (uploadInfo, cancelToken) {},
          complete: (file) {
            completer.complete(file.fileId);
          },
          error: (error) {
            log("syncAvatar: upload error $error");
            if (!completer.isCompleted) completer.complete(null);
          },
          cancel: () {
            if (!completer.isCompleted) completer.complete(null);
          },
        );
      });

      final fileId = await completer.future;

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {}

      if (fileId == null || fileId.isEmpty) {
        log("syncAvatar: upload failed, no fileId");
        return;
      }

      // Update user profile with the uploaded avatar
      log("syncAvatar: updating user avatar with fileId $fileId");
      await AmityCoreClient.newUserRepository()
          .updateUser(currentamityUser!.userId!)
          .avatarFileId(fileId)
          .update()
          .then((user) {
        currentamityUser = user;
        notifyListeners();
        log("syncAvatar: avatar updated successfully");
      }).onError((error, stackTrace) {
        log("syncAvatar: update user error $error");
      });
    } catch (e) {
      log("syncAvatar: error $e");
    }
  }

  Future<void> refreshCurrentUserData() async {
    if (currentamityUser != null) {
      await AmityCoreClient.newUserRepository()
          .getUser(currentamityUser!.userId!)
          .then((user) {
        currentamityUser = user;
        notifyListeners();
      }).onError((error, stackTrace) async {
        log(error.toString());
        await AmityDialog()
            .showAlertErrorDialog(title: "Error!", message: error.toString());
      });
    }
  }

  late Function(AmityPost) onShareButtonPressed;
  void setShareButtonFunction(
      Function(AmityPost) onShareButtonPressed) {} // Callback function)
}
