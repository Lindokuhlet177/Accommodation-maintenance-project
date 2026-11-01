namespace StudentStayFix.Web.Models;

/// <summary>Mirrors the upcoming_task table (tasks & inspections on the Overview).</summary>
public class UpcomingTask
{
    public long Id { get; set; }
    public long AccommodationId { get; set; }
    public string Title { get; set; } = "";
    public string? Details { get; set; }
    public DateTimeOffset EventDate { get; set; }
}
