namespace StudentStayFix.Web.Models;

/// <summary>One choice in an accommodation dropdown (from public_accommodations).</summary>
public class AccommodationOption
{
    public long Id { get; set; }
    public string Name { get; set; } = "";
}