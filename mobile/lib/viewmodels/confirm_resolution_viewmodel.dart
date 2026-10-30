import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/request_service.dart';

/// Logic and state behind the Confirm Resolution screen.
/// Tapping Yes or No sends the answer straight away.
class ConfirmResolutionViewModel extends ChangeNotifier {
  static const int maxCommentLength = 500;

  final RequestService _requestService;

  ConfirmResolutionViewModel({RequestService? requestService})
      : _requestService = requestService ?? RequestService();

  // ---------- State the screen reads ----------

  String _comment = '';
  String get comment => _comment;

  /// Which button is busy: true = Yes, false = No, null = neither.
  bool? _sendingAnswer;
  bool get isSubmitting => _sendingAnswer != null;
  bool get isSendingYes => _sendingAnswer == true;
  bool get isSendingNo => _sendingAnswer == false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ---------- Actions the screen calls ----------

  void setComment(String value) {
    _comment = value;
    _errorMessage = null;
    notifyListeners();
  }

  /// "Yes it's fixed" (isFixed = true) or "No, it's still a problem" (false).
  /// Returns true if the answer was saved.
  Future<bool> submit({required int requestId, required bool isFixed}) async {
    if (isSubmitting) return false; // ignore double taps

    if (_comment.length > maxCommentLength) {
      _errorMessage = 'Comment must be $maxCommentLength characters or less.';
      notifyListeners();
      return false;
    }

    _sendingAnswer = isFixed;
    _errorMessage = null;
    notifyListeners();

    try {
      await _requestService.confirmResolution(
        requestId: requestId,
        isFixed: isFixed,
        comment: _comment,
      );
      return true;
    } on PostgrestException catch (e) {
      // Messages raised by the confirm_resolution function (Step 2.5)
      _errorMessage = e.message.contains('not waiting for confirmation')
          ? 'This request has already been updated. Go back and refresh.'
          : 'Could not save your answer. Please try again.';
      return false;
    } catch (_) {
      _errorMessage = 'Could not save your answer. Check your connection.';
      return false;
    } finally {
      _sendingAnswer = null;
      notifyListeners();
    }
  }
}