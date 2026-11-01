using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;

namespace StudentStayFix.Web.Controllers;

public class DashboardController : AppController
{
    public DashboardController(SupabaseDb db, PropertyContext property) : base(db, property) { }

    public async Task<IActionResult> Index()
    {
        ViewData["Title"] = "Overview";
        ViewData["Active"] = "Overview";
        ViewData["Heading"] = $"{Ui.Greeting}, {User.FirstName()}";

        // No property yet (new landlord): the page shows "Add your first property".
        if (CurrentAccommodationId is not long accId)
            return View(new DashboardViewModel { CanManageTasks = Shell.IsLandlord });

        // 1. Every request in this property, with its student and room.
        //    room!inner + room.accommodation_id filters requests by property.
        var requestsQuery =
            "maintenance_request?select=*,student(id,name,surname)," +
            "room!inner(id,room_number,floor,accommodation_id)" +
            $"&room.accommodation_id=eq.{accId}&order=date_submitted.desc";

        // 2. The next 5 tasks (from 12 hours ago, so today's earlier ones still show)
        var from = SupabaseDb.Enc(DateTimeOffset.UtcNow.AddHours(-12).ToString("o"));
        var tasksQuery =
            $"upcoming_task?select=*&accommodation_id=eq.{accId}" +
            $"&event_date=gte.{from}&order=event_date.asc&limit=5";

        // Run both at the same time.
        var requestsTask = Db.GetAsync<MaintenanceRequest>(requestsQuery);
        var tasksTask = Db.GetAsync<UpcomingTask>(tasksQuery);

        try
        {
            await Task.WhenAll(requestsTask, tasksTask);
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not load the overview: " + ex.Message;
            return View(new DashboardViewModel { HasProperty = true, CanManageTasks = Shell.IsLandlord });
        }

        var vm = DashboardViewModel.Build(requestsTask.Result, tasksTask.Result, Shell.IsLandlord);

        
        

        return View(vm);
    }
}
