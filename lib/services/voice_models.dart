/// Voice Models - Models for Voice API responses

// ==================== VOICE TRANSCRIPTION ====================
class VoiceTranscription {
  final int voiceId;
  final String transcriptedTextEn;
  final String transcriptedTextAr;
  final String audioUrl;
  final String language;
  final DateTime date;
  final String? message;

  VoiceTranscription({
    required this.voiceId,
    required this.transcriptedTextEn,
    required this.transcriptedTextAr,
    required this.audioUrl,
    required this.language,
    required this.date,
    this.message,
  });

  factory VoiceTranscription.fromJson(Map<String, dynamic> json) {
    return VoiceTranscription(
      voiceId: json['voiceID'] ?? json['voiceId'] ?? 0,
      transcriptedTextEn: json['transcriptedTextEn'] ?? '',
      transcriptedTextAr: json['transcriptedTextAr'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      language: json['language'] ?? 'en',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'voiceID': voiceId,
    'transcriptedTextEn': transcriptedTextEn,
    'transcriptedTextAr': transcriptedTextAr,
    'audioUrl': audioUrl,
    'language': language,
    'date': date.toIso8601String(),
    'message': message,
  };

  /// Get text based on language
  String getText(String lang) {
    return lang == 'ar' ? transcriptedTextAr : transcriptedTextEn;
  }

  /// Get formatted date
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return 'Today $displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // Within a week
      return '${difference.inDays} days ago';
    } else {
      // More than a week
      final month = date.month;
      final day = date.day;
      final year = date.year;
      return '$day/$month/$year';
    }
  }
}

// ==================== API RESPONSE ====================
class VoiceApiResponse {
  final bool success;
  final String? message;
  final VoiceTranscription? data;

  VoiceApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory VoiceApiResponse.fromJson(Map<String, dynamic> json) {
    return VoiceApiResponse(
      success: json['success'] ?? true,
      message: json['message'],
      data: json['voiceID'] != null || json['transcriptedTextEn'] != null
          ? VoiceTranscription.fromJson(json)
          : null,
    );
  }
}

// ==================== HISTORY RESPONSE ====================
class VoiceHistoryResponse {
  final bool success;
  final String? message;
  final List<VoiceTranscription> data;

  VoiceHistoryResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory VoiceHistoryResponse.fromJson(dynamic json) {
    if (json is List) {
      return VoiceHistoryResponse(
        success: true,
        data: json.map((item) => VoiceTranscription.fromJson(item)).toList(),
      );
    } else if (json is Map) {
      final dataList = json['data'] ?? json['Data'] ?? [];
      return VoiceHistoryResponse(
        success: json['success'] ?? true,
        message: json['message'],
        data: (dataList as List)
            .map((item) => VoiceTranscription.fromJson(item))
            .toList(),
      );
    }
    return VoiceHistoryResponse(success: false, data: []);
  }
}