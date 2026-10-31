using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

public class TenantListViewModel
{
    // Filters (from the address bar)
    public string? Search { get; set; }
    public string Accommodation { get; set; } = "";   // property id, or "all"
    public long? Room { get; set; }

    // Filter choices
    public List<Accommodation> Accommodations { get; set; } = [];
    public List<Room> Rooms { get; set; } = [];
    public Dictionary<long, string> AccommodationNames { get; set; } = [];
    public bool ShowingAll => Accommodation == "all";

    // Table
    public List<Tenancy> Rows { get; set; } = [];
    public int Total { get; set; }
}

/// <summary>The "+ Add Tenants" form.</summary>
/// <summary>The "+ Add Tenants" form.</summary>
public class TenantForm
{
    [Required(ErrorMessage = "Enter the first name")]
    [StringLength(60)]
    [Display(Name = "First name")]
    public string Name { get; set; } = "";

    [Required(ErrorMessage = "Enter the surname")]
    [StringLength(60)]
    public string Surname { get; set; } = "";

    [Required(ErrorMessage = "Enter the student number")]
    [StringLength(20)]
    [RegularExpression(@"^[A-Za-z0-9]+$", ErrorMessage = "Letters and numbers only")]
    [Display(Name = "Student number")]
    public string StudentNumber { get; set; } = "";

    [EmailAddress(ErrorMessage = "Enter a valid email address")]
    [Display(Name = "Email (optional)")]
    public string? Email { get; set; }

    [StringLength(20, ErrorMessage = "Phone must be 20 characters or less")]
    [RegularExpression(@"^[0-9+ ()\-]*$", ErrorMessage = "Numbers, spaces, + ( ) and - only")]
    [Display(Name = "Phone (optional)")]
    public string? Phone { get; set; }

    [Required(ErrorMessage = "Choose a room")]
    [Display(Name = "Room")]
    public long? RoomId { get; set; }

    /// <summary>Rooms of the current property, with how full they are.</summary>
    public List<RoomRow> RoomChoices { get; set; } = [];
}
/// <summary>The tenant View page.</summary>
public class TenantDetailsViewModel
{
    public Tenancy Tenancy { get; set; } = new();
    public string AccommodationName { get; set; } = "";

    /// <summary>Their app account, once they've signed up (null before).</summary>
    public RequestStudent? Student { get; set; }

    public List<MaintenanceRequest> Requests { get; set; } = [];
    public int OpenRequests => Requests.Count(r => r.IsActive);
}
/// <summary>A student who signed up but didn't match a contract.</summary>
public class PendingStudent
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Surname { get; set; } = "";
    public string? StudentNumber { get; set; }
    public string Email { get; set; } = "";

    [StringLength(20, ErrorMessage = "Phone must be 20 characters or less")]
    [RegularExpression(@"^[0-9+ ()\-]*$", ErrorMessage = "Numbers, spaces, + ( ) and - only")]
    [Display(Name = "Phone (optional)")]
    public string? Phone { get; set; }

    public DateTimeOffset RegisteredAt { get; set; }

    public string FullName => $"{Name} {Surname}".Trim();
}

/// <summary>Rooms with space in one property (for the "Link to room" dropdown).</summary>
public record RoomGroup(string PropertyName, List<RoomRow> Rooms);

public class RegistrationListViewModel
{
    public List<PendingStudent> Students { get; set; } = [];
    public List<RoomGroup> RoomGroups { get; set; } = [];
}