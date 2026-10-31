namespace StudentStayFix.Web.Models.ViewModels;

/// <summary>A status_history row with its request, room and student joined in.</summary>
public class StaffEventRow
{
    public long Id { get; set; }
    public long RequestId { get; set; }
    public string Status { get; set; } = "";
    public string? Note { get; set; }
    public DateTimeOffset ChangedAt { get; set; }
    public EventRequest? MaintenanceRequest { get; set; }
}

public class EventRequest
{
    public long Id { get; set; }
    public string Title { get; set; } = "";
    public Room? Room { get; set; }
    public RequestStudent? Student { get; set; }
}

/// <summary>One notification card on the page.</summary>
public class StaffNotification
{
    public string Kind { get; set; } = "";       // "new", "reopened", "resolved"
    public string Title { get; set; } = "";
    public string Text { get; set; } = "";
    public string? Comment { get; set; }
    public long RequestId { get; set; }
    public DateTimeOffset When { get; set; }
    public bool IsUnread { get; set; }
}

public class StaffNotificationsViewModel
{
    public List<StaffNotification> Items { get; set; } = [];
    public int PendingRegistrations { get; set; }
    public int PendingCaretakers { get; set; }

    public List<StaffNotification> NewItems => Items.Where(i => i.IsUnread).ToList();
    public List<StaffNotification> EarlierItems => Items.Where(i => !i.IsUnread).ToList();
}