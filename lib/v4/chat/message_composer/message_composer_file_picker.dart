import 'package:amity_uikit_beta_service/v4/chat/message_composer/bloc/message_composer_bloc.dart';
import 'package:amity_uikit_beta_service/v4/chat/message_composer/message_composer.dart';
import 'package:amity_uikit_beta_service/v4/core/toast/bloc/amity_uikit_toast_bloc.dart';
import 'package:amity_uikit_beta_service/v4/utils/media_permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

extension MessageComposerFilePicker on AmityMessageComposer {
  void pickMultipleFiles(BuildContext context, String appName, FileType type,
      {int maxFiles = 10}) async {
    try {
      final granted = await MediaPermissionHandler().handleMediaPermissions();
      if (!granted) {
        toastBloc.add(AmityToastDismiss());
        return;
      }

      XFile? selectedMedia;

      // Route the Media button through image_picker so Android 13+ uses the
      // system Photo Picker (ACTION_PICK_IMAGES) instead of the Documents UI
      // that file_picker falls back to without READ_MEDIA_* permissions —
      // otherwise Media and File look identical.
      if (type == FileType.media) {
        MediaPermissionHandler().configureAndroidPhotoPicker(true);
        selectedMedia = await ImagePicker().pickMedia();
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: type,
          allowMultiple: false,
          withData: false,
          withReadStream: false,
        );
        if (result != null && result.files.isNotEmpty) {
          final path = result.files.first.path;
          if (path != null) selectedMedia = XFile(path);
        }
      }

      if (selectedMedia != null) {
        action.onMessageCreated();
        if (!context.mounted) return;
        context.read<MessageComposerBloc>().add(
              MessageComposerSelectImageAndVideoEvent(
                selectedMedia: selectedMedia,
              ),
            );
        return;
      }

      toastBloc.add(AmityToastDismiss());
    } catch (e) {
      toastBloc.add(AmityToastDismiss());
    }
  }

  void pickDocumentFiles(BuildContext context, String appName) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        final path = pickedFile.path;
        if (path != null) {
          action.onMessageCreated();
          if (!context.mounted) return;
          context.read<MessageComposerBloc>().add(
                MessageComposerSelectFileEvent(
                  filePath: path,
                ),
              );
          return;
        }
      }

      toastBloc.add(AmityToastDismiss());
    } catch (e) {
      toastBloc.add(AmityToastDismiss());
    }
  }
}
