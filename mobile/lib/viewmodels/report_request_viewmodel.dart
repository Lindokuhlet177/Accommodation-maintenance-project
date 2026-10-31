
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/maintenance_request.dart';
import '../models/request_status.dart';
import '../services/request_service.dart';
import '../services/storage_service.dart';
import '../services/student_service.dart';

/// A photo chosen on the phone, not uploaded yet.
class PickedPhoto {
  final Uint8List bytes; // for the thumbnail and the upload
  final String name;     // original file name, for its extension

  const PickedPhoto({required this.bytes, required this.name});
}

/// Logic and state behind Report a Problem (steps 1 and 2).
class ReportRequestViewModel extends ChangeNotifier {
  static const int maxDescriptionLength = 500;
  static const int maxTitleLength = MaintenanceRequest.maxTitleLength;
  static const int maxPhotos = MaintenanceRequest.maxPhotos;

  final StudentService _studentService;
  final RequestService _requestService;
  final StorageService _storageService;
  final ImagePicker _picker;

  ReportRequestViewModel({
    StudentService? studentService,
    RequestService? requestService,
    StorageService? storageService,
    ImagePicker? picker,
  })  : _studentService = studentService ?? StudentService(),
        _requestService = requestService ?? RequestService(),
        _storageService = storageService ?? StorageService(),
        _picker = picker ?? ImagePicker();

  // ---------- Step tracking (the 1 — 2 stepper) ----------

  int _currentStep = 0; // 0 = Details, 1 = Photo
  int get currentStep => _currentStep;

  // ---------- Step 1: Details ----------

  String _title = '';
  String get title => _title;

  String? _category;
  String? get category => _category;

  String _description = '';
  String get description => _description;

  RequestPriority _priority = RequestPriority.low; // Low is pre-selected
  RequestPriority get priority => _priority;

  // ---------- Step 2: Photos ----------

  final List<PickedPhoto> _photos = [];
  List<PickedPhoto> get photos => List.unmodifiable(_photos);

  bool get hasPhotos => _photos.isNotEmpty;
  bool get canAddPhoto => _photos.length < maxPhotos;

  // ---------- Submitting ----------

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Set if the request saved but some photos did not.
  String? _photoWarning;
  String? get photoWarning => _photoWarning;

  /// Set after a successful submit, for the Request Submitted screen.
  MaintenanceRequest? _submittedRequest;
  MaintenanceRequest? get submittedRequest => _submittedRequest;

  // ---------- Step 1 actions ----------

  void setTitle(String value) {
    _title = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setCategory(String? value) {
    _category = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setPriority(RequestPriority value) {
    _priority = value;
    notifyListeners();
  }

  /// "Next" button. Returns true if Step 1 is valid and we moved on.
  bool goToPhotoStep() {
    if (_title.trim().isEmpty) {
      _errorMessage = 'Please enter a title.';
    } else if (_title.trim().length > maxTitleLength) {
      _errorMessage = 'Title must be $maxTitleLength characters or less.';
    } else if (_category == null) {
      _errorMessage = 'Please choose an issue category.';
    } else if (_description.trim().isEmpty) {
      _errorMessage = 'Please describe the problem.';
    } else if (_description.length > maxDescriptionLength) {
      _errorMessage =
          'Description must be $maxDescriptionLength characters or less.';
    } else {
      _errorMessage = null;
      _currentStep = 1;
    }
    notifyListeners();
    return _currentStep == 1;
  }

  /// Back arrow / tapping "1 Details" on the stepper.
  void backToDetails() {
    _currentStep = 0;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------- Step 2 actions ----------

  /// "Tap to add photos" / "Add More". source = camera or gallery.
  Future<void> pickPhoto(ImageSource source) async {
    if (!canAddPhoto) {
      _errorMessage = 'You can add up to $maxPhotos photos.';
      notifyListeners();
      return;
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 70, // compress, keeps uploads well under 5 MB
        maxWidth: 1600,   // big enough to see the problem clearly
      );
      if (file == null) return; // student cancelled

      _photos.add(PickedPhoto(
        bytes: await file.readAsBytes(),
        name: file.name,
      ));
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Could not open the camera or gallery.';
    }
    notifyListeners();
  }

  /// The small "x" on a thumbnail.
  void removePhoto(int index) {
    if (index < 0 || index >= _photos.length) return;
    _photos.removeAt(index);
    _errorMessage = null;
    notifyListeners();
  }

  /// "Submit" button. Returns true if the request was saved.
  Future<bool> submit() async {
    if (_isSubmitting) return false; // ignore double taps

    _isSubmitting = true;
    _errorMessage = null;
    _photoWarning = null;
    notifyListeners();

    try {
      // 1. Get the student's id and room fresh from the database
      final student = await _studentService.getCurrentStudent();
      if (student == null || !student.hasRoom) {
        _errorMessage =
            'Your room has not been assigned yet. Please contact your landlord.';
        return false;
      }

      // 2. Save the request first (the trigger adds "Request submitted")
      final request = await _requestService.createRequest(
        studentId: student.id,
        roomId: student.roomId!,
        title: _title.trim(),
        category: _category!,
        description: _description.trim(),
        priority: _priority,
      );
      _submittedRequest = request;

      // 3. Upload the photos and link them to the request
      if (_photos.isNotEmpty) {
        try {
          final paths = await Future.wait(_photos.map(
            (p) => _storageService.uploadRequestPhoto(
              bytes: p.bytes,
              fileName: p.name,
            ),
          ));
          await _requestService.addPhotos(requestId: request.id, paths: paths);
        } catch (_) {
          // The request itself is saved, so don't treat this as a failure
          _photoWarning =
              'Your request was submitted, but the photos could not be uploaded.';
        }
      }
      return true;
    } catch (_) {
      _errorMessage =
          'Could not submit your request. Check your connection and try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Clears everything for the next report.
  void reset() {
    _currentStep = 0;
    _title = '';
    _category = null;
    _description = '';
    _priority = RequestPriority.low;
    _photos.clear();
    _isSubmitting = false;
    _errorMessage = null;
    _photoWarning = null;
    _submittedRequest = null;
    notifyListeners();
  }
}