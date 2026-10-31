using System.ComponentModel.DataAnnotations;

namespace StudentStayFix.Web.Models.ViewModels;

public class TaskForm
{
    [Required(ErrorMessage = "Enter a title")]
    [StringLength(100, ErrorMessage = "Title must be 100 characters or less")]
    public string Title { get; set; } = "";

    [Required(ErrorMessage = "Choose a date")]
    public DateOnly? Date { get; set; }

    [Required(ErrorMessage = "Choose a time")]
    public TimeOnly? Time { get; set; }

    [StringLength(500, ErrorMessage = "Details must be 500 characters or less")]
    public string? Details { get; set; }
}