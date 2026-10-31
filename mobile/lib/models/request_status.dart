/// The 5 statuses from Step 2.2, matching the database check rule.
enum RequestStatus {
  open('Open'),
  assigned('Assigned'),
  inProgress('In Progress'),
  completed('Completed'),
  closed('Closed');

  /// The exact text stored in the database.
  final String dbValue;
  const RequestStatus(this.dbValue);

  /// Turns database text back into an enum value.
  static RequestStatus fromDb(String value) =>
      RequestStatus.values.firstWhere((s) => s.dbValue == value);

  /// What the student sees on the chip (Open / In Progress / Closed).
  String get chipLabel => switch (this) {
        RequestStatus.open || RequestStatus.assigned => 'Open',
        RequestStatus.inProgress || RequestStatus.completed => 'In Progress',
        RequestStatus.closed => 'Closed',
      };

  /// Counts toward "Active Requests" on Home.
  bool get isActive => this != RequestStatus.closed;

  /// Show the Confirm Resolution button only in this state.
  bool get awaitingConfirmation => this == RequestStatus.completed;
}

/// Low / Medium / High / Urgent, matching the database check rule.
enum RequestPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  final String dbValue;
  const RequestPriority(this.dbValue);

  static RequestPriority fromDb(String value) =>
      RequestPriority.values.firstWhere((p) => p.dbValue == value);
}