namespace StudentStayFix.Web.Models.ViewModels;

public class RequestListViewModel
{
    // Current filters (from the address bar)
    public string? Status { get; set; }
    public string? Priority { get; set; }
    public string Accommodation { get; set; } = "";   // property id, or "all"
    public long? Room { get; set; }

    // Filter choices
    public bool ShowAccommodationFilter { get; set; }
    public List<Accommodation> Accommodations { get; set; } = [];
    public List<Room> Rooms { get; set; } = [];

    /// <summary>Status filter: value -> label (Open includes Assigned).</summary>
    public static readonly (string Value, string Label)[] StatusOptions =
    [
        (RequestStatus.Open, "Open"),
        (RequestStatus.InProgress, "In Progress"),
        (RequestStatus.Completed, "Awaiting student"),
        (RequestStatus.Closed, "Resolved")
    ];

    // Stat cards (for the chosen accommodation, before filters)
    public int Total { get; set; }
    public int Urgent { get; set; }
    public int InProgress { get; set; }
    public int Resolved { get; set; }

    // The table
    public List<MaintenanceRequest> Requests { get; set; } = [];

    /// <summary>Property names by id, shown under the room when "All" is chosen.</summary>
    public Dictionary<long, string> AccommodationNames { get; set; } = [];
    public bool ShowingAll => Accommodation == "all";

    public bool HasFilters =>
        !string.IsNullOrEmpty(Status) || !string.IsNullOrEmpty(Priority) || Room != null;
}