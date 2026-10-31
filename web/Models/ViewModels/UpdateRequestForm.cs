using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

/// <summary>The Updates tab form.</summary>
public class UpdateRequestForm
{
    [Required]
    public string Status { get; set; } = "";

    [Required]
    public string Priority { get; set; } = "";

    [StringLength(500, ErrorMessage = "Notes must be 500 characters or less")]
    public string? Note { get; set; }

    /// <summary>Set by the "Mark as Completed" button (overrides Status).</summary>
    public string? QuickStatus { get; set; }
}