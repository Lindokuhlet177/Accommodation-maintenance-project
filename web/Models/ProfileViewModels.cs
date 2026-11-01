﻿using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

public class ProfileForm
{
    [Required(ErrorMessage = "Enter your name")]
    [StringLength(80, ErrorMessage = "Name must be 80 characters or less")]
    [Display(Name = "Full name")]
    public string Name { get; set; } = "";

    [StringLength(20, ErrorMessage = "Phone must be 20 characters or less")]
    [RegularExpression(@"^[0-9+ ()\-]*$", ErrorMessage = "Numbers, spaces, + ( ) and - only")]
    [Display(Name = "Phone (optional)")]
    public string? Phone { get; set; }
}

public class ProfilePageViewModel
{
    public Staff Staff { get; set; } = new();
    public string? AvatarUrl { get; set; }
    public string BuildingText { get; set; } = "";
    public ProfileForm Form { get; set; } = new();
}
