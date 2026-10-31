namespace StudentStayFix.Web.Models;

/// <summary>Mirrors the maintenance_request table (+ the student and room joined in).</summary>
public class MaintenanceRequest
{
    public long Id { get; set; }
    public Guid StudentId { get; set; }
    public long RoomId { get; set; }
    public Guid? UpdatedByStaffId { get; set; }
    public string Title { get; set; } = "";
    public string Category { get; set; } = "";
    public string Description { get; set; } = "";
    public string Priority { get; set; } = RequestPriority.Low;
    public string Status { get; set; } = RequestStatus.Open;
    public DateTimeOffset DateSubmitted { get; set; }
    public DateTimeOffset? DateResolved { get; set; }
    public DateTimeOffset? ViewedAt { get; set; }
    public string? ViewedBy { get; set; }

    // Joined in by the query: select=*,student(...),room(...)
    public RequestStudent? Student { get; set; }
    public Room? Room { get; set; }

    /// <summary>"MT 000123", the same format as the Flutter app.</summary>
    public string Reference => $"MT {Id:D6}";

    public bool IsActive => RequestStatus.IsActive(Status);

    public string StudentName =>
        Student == null ? "Former resident" : $"{Student.Name} {Student.Surname}".Trim();
}

/// <summary>The student fields joined into a request.</summary>
public class RequestStudent
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Surname { get; set; } = "";
    public string? StudentNumber { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }

    public DateTimeOffset? RegisteredAt { get; set; }
}