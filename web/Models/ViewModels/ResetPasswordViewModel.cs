using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

public class ResetPasswordViewModel
{
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Enter a valid email address")]
    public string Email { get; set; } = "";

    [Required(ErrorMessage = "Enter the code from the email")]
    [RegularExpression(@"^\d{6,10}$", ErrorMessage = "The code is the number in the email")]
    [Display(Name = "Code from the email")]
    public string Code { get; set; } = "";

    [Required(ErrorMessage = "New password is required")]
    [MinLength(6, ErrorMessage = "Password must be at least 6 characters")]
    [DataType(DataType.Password)]
    [Display(Name = "New password")]
    public string Password { get; set; } = "";

    [Required(ErrorMessage = "Please confirm your new password")]
    [Compare(nameof(Password), ErrorMessage = "Passwords do not match")]
    [DataType(DataType.Password)]
    [Display(Name = "Confirm new password")]
    public string ConfirmPassword { get; set; } = "";
}