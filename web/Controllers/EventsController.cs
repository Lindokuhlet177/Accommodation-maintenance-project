using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;

namespace StudentStayFix.Web.Controllers;

/// <summary>Upcoming tasks & inspections on the Overview (landlord only).</summary>
[Authorize(Policy = "LandlordOnly")]
public class EventsController : AppController
{
    public EventsController(SupabaseDb db, PropertyContext property) : base(db, property) { }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create([Bind(Prefix = "NewTask")] TaskForm form)
    {
        if (CurrentAccommodationId is not long accId)
        {
            TempData["Error"] = "Choose a property first.";
            return RedirectToAction("Index", "Dashboard");
        }

        if (!ModelState.IsValid)
        {
            TempData["Error"] = ModelState.Values.SelectMany(v => v.Errors)
                .Select(e => e.ErrorMessage).FirstOrDefault() ?? "Check the task details.";
            return RedirectToAction("Index", "Dashboard");
        }

        // The form is in South African time (UTC+2, no daylight saving)
        var when = new DateTimeOffset(form.Date!.Value.ToDateTime(form.Time!.Value), TimeSpan.FromHours(2));

        if (when < DateTimeOffset.UtcNow.AddHours(-1))
        {
            TempData["Error"] = "Choose a date and time that hasn't passed.";
            return RedirectToAction("Index", "Dashboard");
        }

        try
        {
            await Db.InsertAsync<UpcomingTask>("upcoming_task", new
            {
                accommodation_id = accId,
                title = form.Title.Trim(),
                details = string.IsNullOrWhiteSpace(form.Details) ? null : form.Details.Trim(),
                event_date = when,
                created_by = User.UserId()
            });
            TempData["Success"] = "Task added.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not add the task: " + ex.Message;
        }

        return RedirectToAction("Index", "Dashboard");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(long id)
    {
        try
        {
            await Db.DeleteAsync("upcoming_task", $"id=eq.{id}");
            TempData["Success"] = "Task removed.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not remove the task: " + ex.Message;
        }

        return RedirectToAction("Index", "Dashboard");
    }
}