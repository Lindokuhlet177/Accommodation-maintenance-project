using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

public class LoginViewModel
{
    [Required(ErrorMessage = "Choose whether you are a landlord or a caretaker")]
    [Display(Name = "Sign in as")]
    public string Role { get; set; } = "";

    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Enter a valid email address")]
    public string Email { get; set; } = "";

    [Required(ErrorMessage = "Password is required")]
    [DataType(DataType.Password)]
    public string Password { get; set; } = "";

    /// <summary>The page they were trying to open before being sent to Login.</summary>
    public string? ReturnUrl { get; set; }
}