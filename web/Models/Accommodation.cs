namespace StudentStayFix.Web.Models;

/// <summary>Mirrors the accommodation table (a property).</summary>
public class Accommodation
{
    public long Id { get; set; }
    public string Name { get; set; } = "";
    public string? Address { get; set; }
}
