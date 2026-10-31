namespace StudentStayFix.Web.Models;

/// <summary>The 5 statuses in the database, and how the web shows them.</summary>
public static class RequestStatus
{
    public const string Open = "Open";
    public const string Assigned = "Assigned";
    public const string InProgress = "In Progress";
    public const string Completed = "Completed";   // staff finished, waiting for the student
    public const string Closed = "Closed";         // student confirmed it's fixed

    public static readonly string[] All = [Open, Assigned, InProgress, Completed, Closed];

    /// <summary>Statuses staff may choose (Closed is set by the student in Flutter).</summary>
    public static readonly string[] StaffChoices = [Open, Assigned, InProgress, Completed];

    /// <summary>Wording on the web, as agreed for the designs.</summary>
    public static string Label(string status) => status switch
    {
        Completed => "Awaiting student",
        Closed => "Resolved",
        _ => status
    };

    /// <summary>CSS class for the coloured chip (app.css .chip.*).</summary>
    public static string Css(string status) => status switch
    {
        Open => "open",
        Assigned => "assigned",
        InProgress => "in-progress",
        Completed => "completed",
        Closed => "closed",
        _ => ""
    };

    /// <summary>Still needs attention (everything except Resolved).</summary>
    public static bool IsActive(string status) => status != Closed;
}

/// <summary>The 4 priorities in the database.</summary>
public static class RequestPriority
{
    public const string Low = "Low";
    public const string Medium = "Medium";
    public const string High = "High";
    public const string Urgent = "Urgent";

    /// <summary>Most urgent first, for lists and filters.</summary>
    public static readonly string[] All = [Urgent, High, Medium, Low];

    public static string Css(string priority) => priority.ToLowerInvariant();
}