namespace StudentStayFix.Web.Models;


public class Staff
{
    public Guid Id { get; set; }               // same as their Supabase login id
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string Role { get; set; } = "";     // "Landlord" or "Caretaker"
    public long? AccommodationId { get; set; } // caretaker's building
    public bool IsApproved { get; set; }
    public string? Phone { get; set; }
    public string? AvatarPath { get; set; }

    public DateTimeOffset? NotificationsSeenAt { get; set; }
}