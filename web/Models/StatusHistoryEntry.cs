namespace StudentStayFix.Web.Models;

/// <summary>Mirrors status_history: one timeline entry.</summary>
public class StatusHistoryEntry
{
    public long Id { get; set; }
    public long RequestId { get; set; }
    public string Status { get; set; } = "";
    public string? Note { get; set; }
    public string Kind { get; set; } = "status";   // "status" or "note" 
    public DateTimeOffset ChangedAt { get; set; }
}