namespace StudentStayFix.Web.Models.ViewModels;

/// <summary>One line on the timeline. Kind picks the icon colour.</summary>
public record TimelineItem(string Title, string Text, DateTime When, string Kind);

public class RequestDetailsViewModel
{
    public MaintenanceRequest Request { get; set; } = new();
    public string AccommodationName { get; set; } = "";
    public List<string> PhotoUrls { get; set; } = [];
    public List<TimelineItem> Timeline { get; set; } = [];
    public DateTimeOffset LastUpdated { get; set; }
    public string NextStep { get; set; } = "";

    /// <summary>"details", "updates" or "attachments".</summary>
    public string Tab { get; set; } = "details";

    /// <summary>Resolved requests are read-only (closed by the student).</summary>
    public bool CanUpdate => Request.Status != RequestStatus.Closed;

    public UpdateRequestForm Form { get; set; } = new();

    /// <summary>Short explanation under each status choice on the Updates tab.</summary>
    public static string StatusHint(string status) => status switch
    {
        RequestStatus.Open => "Awaiting action",
        RequestStatus.Assigned => "Given to maintenance staff",
        RequestStatus.InProgress => "Repair being arranged or carried out",
        RequestStatus.Completed => "Repair finished, student will confirm",
        _ => ""
    };
}