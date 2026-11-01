namespace StudentStayFix.Web.Models;

/// <summary>Mirrors the tenancy table: one signed contract (Step W1c).</summary>
public class Tenancy
{
    public long Id { get; set; }
    public long RoomId { get; set; }
    public string Name { get; set; } = "";
    public string Surname { get; set; } = "";
    public string StudentNumber { get; set; } = "";
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public Guid? StudentId { get; set; }          // filled once the student signs up in Flutter
    public DateTimeOffset CreatedAt { get; set; }
    public Room? Room { get; set; }

    public string FullName => $"{Name} {Surname}".Trim();
    public bool HasSignedUp => StudentId != null;
}
