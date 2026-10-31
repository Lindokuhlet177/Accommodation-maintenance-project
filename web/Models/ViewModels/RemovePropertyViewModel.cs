namespace StudentStayFix.Web.Models.ViewModels;

/// <summary>The "Remove property" confirmation page.</summary>
public class RemovePropertyViewModel
{
    public Accommodation Property { get; set; } = new();
    public int Rooms { get; set; }
    public int Tenants { get; set; }
    public int Requests { get; set; }
    public int Caretakers { get; set; }

    /// <summary>Same rules as delete_property in the database.</summary>
    public bool CanRemove => Tenants == 0 && Requests == 0 && Caretakers == 0;
}