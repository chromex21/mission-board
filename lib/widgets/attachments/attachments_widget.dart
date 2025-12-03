import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attachment_model.dart';
import '../../utils/notification_helper.dart';

class AttachmentsWidget extends StatefulWidget {
  final String missionId;
  final bool canAdd;

  const AttachmentsWidget({
    super.key,
    required this.missionId,
    this.canAdd = true,
  });

  @override
  State<AttachmentsWidget> createState() => _AttachmentsWidgetState();
}

class _AttachmentsWidgetState extends State<AttachmentsWidget> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachmentProvider = Provider.of<AttachmentProvider>(context);

    return Column(
      children: [
        // Attachments list
        Expanded(
          child: StreamBuilder<List<Attachment>>(
            stream: attachmentProvider.streamAttachmentsForMission(
              widget.missionId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading attachments',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                );
              }

              final attachments = snapshot.data ?? [];

              if (attachments.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: attachments.length,
                itemBuilder: (context, index) {
                  final attachment = attachments[index];
                  return _AttachmentCard(
                    attachment: attachment,
                    onDelete: () => _deleteAttachment(attachment),
                  );
                },
              );
            },
          ),
        ),

        // Add attachment button
        if (widget.canAdd) _buildAddButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_file, size: 64, color: AppTheme.grey600),
          const SizedBox(height: 16),
          Text(
            'No attachments',
            style: TextStyle(color: AppTheme.grey600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste Drive, Dropbox, or file links',
            style: TextStyle(color: AppTheme.grey600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        border: Border(top: BorderSide(color: AppTheme.grey700)),
      ),
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_link, size: 20),
        label: const Text('Add Link / File'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Attachment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste a link to Google Drive, Dropbox, or any file',
                style: TextStyle(color: AppTheme.grey400, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'URL *',
                  hintText: 'https://drive.google.com/...',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'File Name (optional)',
                  hintText: 'My Document.pdf',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Project requirements document',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitAttachment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttachment(BuildContext dialogContext) async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      context.showWarning('Please enter a URL');
      return;
    }

    // Validate URL format
    try {
      Uri.parse(url);
    } catch (e) {
      context.showError('Invalid URL format');
      return;
    }

    final attachmentProvider = Provider.of<AttachmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final navigator = Navigator.of(dialogContext);
    final attachment = await attachmentProvider.addAttachment(
      missionId: widget.missionId,
      userId: authProvider.user?.uid ?? '',
      url: url,
      fileName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
    );

    if (!mounted) return;

    if (attachment != null) {
      navigator.pop();
      _clearForm();
      context.showSuccess('Attachment added');
    } else {
      context.showError('Failed to add attachment');
    }
  }

  void _clearForm() {
    _urlController.clear();
    _nameController.clear();
    _descController.clear();
  }

  void _deleteAttachment(Attachment attachment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attachment'),
        content: Text('Remove "${attachment.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AttachmentProvider>(
                context,
                listen: false,
              ).deleteAttachment(attachment.id, widget.missionId);
              Navigator.pop(context);
              context.showSuccess('Attachment deleted');
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onDelete;

  const _AttachmentCard({required this.attachment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.grey900,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.grey700),
      ),
      child: InkWell(
        onTap: () => _launchUrl(attachment.url),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (attachment.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        attachment.description!,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_getTypeIcon(), size: 12, color: AppTheme.grey600),
                        const SizedBox(width: 4),
                        Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppTheme.errorRed,
                ),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (attachment.iconName) {
      case 'drive':
        iconData = Icons.folder_special;
        iconColor = const Color(0xFF4285F4); // Google blue
        break;
      case 'dropbox':
        iconData = Icons.cloud;
        iconColor = const Color(0xFF0061FF); // Dropbox blue
        break;
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = const Color(0xFFE53935); // PDF red
        break;
      case 'word':
        iconData = Icons.description;
        iconColor = const Color(0xFF2B579A); // Word blue
        break;
      case 'excel':
        iconData = Icons.table_chart;
        iconColor = const Color(0xFF217346); // Excel green
        break;
      case 'powerpoint':
        iconData = Icons.slideshow;
        iconColor = const Color(0xFFD24726); // PowerPoint red
        break;
      case 'archive':
        iconData = Icons.folder_zip;
        iconColor = AppTheme.warningOrange;
        break;
      case 'image':
        iconData = Icons.image;
        iconColor = AppTheme.primaryPurple;
        break;
      case 'video':
        iconData = Icons.videocam;
        iconColor = AppTheme.errorRed;
        break;
      case 'audio':
        iconData = Icons.audiotrack;
        iconColor = AppTheme.successGreen;
        break;
      case 'link':
        iconData = Icons.link;
        iconColor = AppTheme.infoBlue;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = AppTheme.grey600;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  IconData _getTypeIcon() {
    switch (attachment.type) {
      case AttachmentType.driveFile:
        return Icons.cloud;
      case AttachmentType.dropboxFile:
        return Icons.cloud;
      case AttachmentType.otherFile:
        return Icons.insert_drive_file;
      case AttachmentType.link:
        return Icons.link;
    }
  }

  String _getTypeLabel() {
    switch (attachment.type) {
      case AttachmentType.driveFile:
        return 'Google Drive';
      case AttachmentType.dropboxFile:
        return 'Dropbox';
      case AttachmentType.otherFile:
        final ext = attachment.fileExtension.toUpperCase();
        return ext.isEmpty ? 'File' : '$ext File';
      case AttachmentType.link:
        return 'Link';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
