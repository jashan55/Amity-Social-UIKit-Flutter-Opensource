part of '../message_bubble_view.dart';

extension FileMessageWidget on MessageBubbleView {
  Widget _buildFileMessageWidget(
      BuildContext context, bool isUser, MessageBubbleState state) {
    final fileData = message.data as MessageFileData;
    final file = fileData.file;
    final fileName = file?.fileName ?? "Unknown file";
    final fileSize = int.tryParse(file?.fileSize?.toString() ?? '') ?? 0;
    final fileUrl = file?.fileUrl ?? "";
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    final bool isUploading =
        message.syncState != AmityMessageSyncState.SYNCED &&
            message.syncState != AmityMessageSyncState.FAILED;

    Color initialColor = isUser
        ? messageColor.rightBubbleDefault
        : messageColor.leftBubbleDefault;

    return Transform.translate(
      offset: Offset(
          ((bounce * bounceOffset) - bounceOffset) * (isUser ? -1 : 1),
          0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            (message.syncState == AmityMessageSyncState.FAILED)
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.end,
        children: [
          if (isUser &&
              message.createdAt != null &&
              message.syncState == AmityMessageSyncState.SYNCED) ...[
            _buildDateWidget(message.createdAt!),
            const SizedBox(width: 8),
          ],
          if (isUser && isUploading) ...[
            _buildSideTextWidget(context.l10n.message_sending),
            const SizedBox(width: 8),
          ],
          if (!isUser) ...[
            _buildAvatarWidget(context),
            const SizedBox(width: 8),
          ],
          if (message.syncState == AmityMessageSyncState.FAILED &&
              isUser) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    _showActionSheet(context);
                  },
                  child: SvgPicture.asset(
                    'assets/Icons/amity_ic_error_message.svg',
                    package: 'amity_uikit_beta_service',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      theme.baseColorShade2,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatefulBuilder(
                      builder: (context, setState) {
                        return GestureDetector(
                          onTap: () {
                            if (fileUrl.isNotEmpty) {
                              _openFile(context, fileUrl, fileName);
                            }
                          },
                          onLongPress: () async {
                            if (message.syncState ==
                                AmityMessageSyncState.FAILED) {
                              return;
                            }
                            HapticFeedback.heavyImpact();
                            final RenderBox? messageBox =
                                context.findRenderObject() as RenderBox?;
                            final Offset? messagePosition =
                                messageBox?.localToGlobal(Offset.zero);
                            double height = messageBox?.size.height ?? 0;
                            double width = messageBox?.size.width ?? 0;
                            if (message.reactionCount != null &&
                                message.reactionCount! > 0) {
                              height += 26;
                            } else {
                              height += 4;
                            }
                            final offset = Offset(
                                isUser
                                    ? messagePosition!.dx + width
                                    : messagePosition!.dx,
                                messagePosition.dy + height);

                            final reactions =
                                configProvider.getAllMessageReactions();
                            final reactionActionOffset = Offset(
                                isUser
                                    ? messagePosition.dx + width - 208
                                    : messagePosition.dx,
                                messagePosition.dy - 52);
                            await _showReactionAndMenu(context, offset,
                                reactionActionOffset, message, state, reactions);
                          },
                          child: Opacity(
                            opacity: isUploading ? 0.5 : 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: initialColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _getFileIcon(extension, isUser),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          fileName,
                                          style: TextStyle(
                                            color: isUser
                                                ? messageColor.rightBubbleText
                                                : messageColor.leftBubbleText,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatFileSize(fileSize),
                                          style: TextStyle(
                                            color: isUser
                                                ? messageColor.rightBubbleText
                                                    .withOpacity(0.7)
                                                : messageColor.leftBubbleText
                                                    .withOpacity(0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (message.syncState ==
                        AmityMessageSyncState.FAILED) ...[
                      const SizedBox(height: 4),
                      _buildFailToSendText(context),
                    ],
                  ],
                ),
                if (isUploading) _buildUploadingIndicator(),
                if (message.syncState == AmityMessageSyncState.UPLOADING)
                  _buildCancelDownloadButton(),
              ],
            ),
          ),
          if (!isUser && message.createdAt != null) ...[
            const SizedBox(width: 8),
            _buildDateWidget(message.createdAt!),
          ],
        ],
      ),
    );
  }

  Widget _getFileIcon(String extension, bool isUser) {
    IconData iconData;
    Color iconColor;

    switch (extension) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case 'ppt':
      case 'pptx':
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case 'zip':
      case 'rar':
      case '7z':
        iconData = Icons.folder_zip;
        iconColor = Colors.amber;
        break;
      case 'txt':
        iconData = Icons.text_snippet;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = isUser
            ? messageColor.rightBubbleText
            : messageColor.leftBubbleText;
        break;
    }

    return Icon(
      iconData,
      size: 32,
      color: iconColor,
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _openFile(BuildContext context, String url, String fileName) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // ignore
    }
  }
}
