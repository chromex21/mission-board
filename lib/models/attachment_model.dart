import 'package:cloud_firestore/cloud_firestore.dart';

enum AttachmentType { link, driveFile, dropboxFile, otherFile }

class Attachment {
  final String id;
  final String missionId;
  final String? commentId; // Optional: attach to comment instead of mission
  final String userId;
  final String url;
  final String? fileName;
  final String? description;
  final AttachmentType type;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.missionId,
    this.commentId,
    required this.userId,
    required this.url,
    this.fileName,
    this.description,
    AttachmentType? type,
    DateTime? createdAt,
  }) : type = type ?? _detectType(url),
       createdAt = createdAt ?? DateTime.now();

  static AttachmentType _detectType(String url) {
    final lowercaseUrl = url.toLowerCase();
    if (lowercaseUrl.contains('drive.google.com') ||
        lowercaseUrl.contains('docs.google.com')) {
      return AttachmentType.driveFile;
    } else if (lowercaseUrl.contains('dropbox.com')) {
      return AttachmentType.dropboxFile;
    } else if (_isFileUrl(url)) {
      return AttachmentType.otherFile;
    }
    return AttachmentType.link;
  }

  static bool _isFileUrl(String url) {
    final extensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.zip',
      '.rar',
      '.7z',
      '.tar',
      '.gz',
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.svg',
      '.mp4',
      '.avi',
      '.mov',
      '.wmv',
      '.flv',
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.txt',
      '.csv',
      '.json',
      '.xml',
    ];
    return extensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  factory Attachment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Attachment(
      id: doc.id,
      missionId: data['missionId'] ?? '',
      commentId: data['commentId'],
      userId: data['userId'] ?? '',
      url: data['url'] ?? '',
      fileName: data['fileName'],
      description: data['description'],
      type: AttachmentType.values.firstWhere(
        (e) => e.toString() == 'AttachmentType.${data['type'] ?? 'link'}',
        orElse: () => AttachmentType.link,
      ),
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missionId': missionId,
      'commentId': commentId,
      'userId': userId,
      'url': url,
      'fileName': fileName,
      'description': description,
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  String get displayName {
    if (fileName != null && fileName!.isNotEmpty) {
      return fileName!;
    }

    // Try to extract filename from URL
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.isNotEmpty && lastSegment != '/') {
          return Uri.decodeComponent(lastSegment);
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return 'Attachment';
  }

  String get fileExtension {
    final name = displayName.toLowerCase();
    final lastDot = name.lastIndexOf('.');
    if (lastDot != -1 && lastDot < name.length - 1) {
      return name.substring(lastDot + 1);
    }
    return '';
  }

  String get iconName {
    switch (type) {
      case AttachmentType.driveFile:
        return 'drive';
      case AttachmentType.dropboxFile:
        return 'dropbox';
      case AttachmentType.otherFile:
        final ext = fileExtension;
        if (['pdf'].contains(ext)) {
          return 'pdf';
        }
        if (['doc', 'docx'].contains(ext)) {
          return 'word';
        }
        if (['xls', 'xlsx'].contains(ext)) {
          return 'excel';
        }
        if (['ppt', 'pptx'].contains(ext)) {
          return 'powerpoint';
        }
        if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
          return 'archive';
        }
        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg'].contains(ext)) {
          return 'image';
        }
        if (['mp4', 'avi', 'mov', 'wmv', 'flv'].contains(ext)) {
          return 'video';
        }
        if (['mp3', 'wav', 'flac', 'aac'].contains(ext)) {
          return 'audio';
        }
        return 'file';
      case AttachmentType.link:
        return 'link';
    }
  }
}
