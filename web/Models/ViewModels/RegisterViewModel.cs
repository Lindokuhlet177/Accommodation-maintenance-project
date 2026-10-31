using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

public class RegisterViewModel
{
    [Required(ErrorMessage = "Full name is required")]
    [StringLength(80, ErrorMessage = "Name must be 80 characters or less")]
    [Display(Name = "Full name")]
    public string Name { get; set; } = "";

    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Enter a valid email address")]
    public string Email { get; set; } = "";

    [Required(ErrorMessage = "Choose the accommodation you work at")]
    [Display(Name = "Accommodation")]
    public long? AccommodationId { get; set; }

    [Required(ErrorMessage = "Password is required")]
    [MinLength(6, ErrorMessage = "Password must be at least 6 characters")]
    [DataType(DataType.Password)]
    public string Password { get; set; } = "";

    [Required(ErrorMessage = "Please confirm your password")]
    [Compare(nameof(Password), ErrorMessage = "Passwords do not match")]
    [DataType(DataType.Password)]
    [Display(Name = "Confirm password")]
    public string ConfirmPassword { get; set; } = "";

    /// <summary>Choices for the dropdown (not posted back).</summary>
    public List<AccommodationOption> Accommodations { get; set; } = [];
}