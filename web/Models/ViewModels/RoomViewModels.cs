using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

/// <summary>One row on the Rooms page.</summary>
public class RoomRow
{
    public Room Room { get; set; } = new();
    public List<Tenancy> Tenants { get; set; } = [];

    public bool IsOccupied => Tenants.Count >= Room.Capacity;
    public string StatusText => IsOccupied ? "Occupied" : "Available";
    public string TenantText => Tenants.Count == 0 ? "-" : string.Join(", ", Tenants.Select(t => t.FullName));
}

public class RoomListViewModel
{
    public string? Search { get; set; }
    public int? Floor { get; set; }
    public List<int> Floors { get; set; } = [];
    public List<RoomRow> Rows { get; set; } = [];
    public int TotalRooms { get; set; }
}

/// <summary>The "+ Add Room" form.</summary>
public class RoomForm
{
    public static readonly string[] Types = ["Single", "Double"];

    [Required(ErrorMessage = "Enter the room number")]
    [StringLength(10, ErrorMessage = "Room number must be 10 characters or less")]
    [RegularExpression(@"^[A-Za-z0-9\-]+$", ErrorMessage = "Use letters, numbers and dashes only, e.g. 2A")]
    [Display(Name = "Room number")]
    public string RoomNumber { get; set; } = "";

    [Range(0, 50, ErrorMessage = "Floor must be between 0 and 50")]
    public int Floor { get; set; }

    [Required(ErrorMessage = "Choose the room type")]
    [Display(Name = "Room type")]
    public string RoomType { get; set; } = "Single";

    /// <summary>Single = 1 student, Double = 2 (agreed rule).</summary>
    public int Capacity => RoomType == "Double" ? 2 : 1;
}
/// <summary>The room View page.</summary>
public class RoomDetailsViewModel
{
    public RoomRow Row { get; set; } = new();
    public string AccommodationName { get; set; } = "";
    public List<MaintenanceRequest> Requests { get; set; } = [];

    public int ActiveRequests => Requests.Count(r => r.IsActive);
    public bool HasSpace => !Row.IsOccupied;
}