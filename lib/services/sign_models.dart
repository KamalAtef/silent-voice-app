// ── lib/services/sign_models.dart ─────────────────────────────────────────────
// Models for Sign Language transcription (mirrors .NET SignResponseDto)

class SignTranscription {
  final int    signId;
  final String transcriptedTextEn;
  final String transcriptedTextAr;
  final String videoUrl;
  final DateTime date;
  final String? message;

  SignTranscription({
    required this.signId,
    required this.transcriptedTextEn,
    required this.transcriptedTextAr,
    required this.videoUrl,
    required this.date,
    this.message,
  });

  factory SignTranscription.fromJson(Map<String, dynamic> json) {
    return SignTranscription(
      signId             : json['signID']             ?? 0,
      transcriptedTextEn : json['transcriptedTextEn'] ?? '',
      transcriptedTextAr : json['transcriptedTextAr'] ?? '',
      videoUrl           : json['videoUrl']           ?? '',
      date               : DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      message            : json['message'],
    );
  }

  String getFormattedDate() {
    return '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  }
}

// Generic API response wrapper (reuse same pattern as voice)
class SignApiResponse<T> {
  final bool    success;
  final T?      data;
  final String? message;

  SignApiResponse({required this.success, this.data, this.message});
}
