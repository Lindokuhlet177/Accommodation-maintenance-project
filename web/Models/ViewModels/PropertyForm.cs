using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

public class PropertyForm
{
    [Required(ErrorMessage = "Enter the property name")]
    [StringLength(100, ErrorMessage = "Name must be 100 characters or less")]
    [Display(Name = "Property name")]
    public string Name { get; set; } = "";

    [StringLength(200, ErrorMessage = "Address must be 200 characters or less")]
    [Display(Name = "Address (optional)")]
    public string? Address { get; set; }
}