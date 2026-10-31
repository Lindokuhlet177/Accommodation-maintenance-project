using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;

namespace StudentStayFix.Web.Controllers;

public class RequestsController : AppController
{
    public RequestsController(SupabaseDb db, PropertyContext property) : base(db, property) { }

    // ---------------- LIST ----------------

    public async Task<IActionResult> Index(string? status, string? priority, string? accommodation, long? room)
    {
        ViewData["Title"] = "Requests";
        ViewData["Active"] = "Requests";
        ViewData["Heading"] = "Maintenance Requests";

        var vm = new RequestListViewModel
        {
            Status = status,
            Priority = priority,
            Room = room,
            ShowAccommodationFilter = Shell.IsLandlord,
            Accommodations = Shell.Properties
        };

        // Which properties? Caretaker: always theirs.
        // Landlord: "all", a chosen property, or the one selected in the sidebar.
        List<long> accIds;
        if (Shell.IsLandlord && accommodation == "all")
        {
            accIds = Shell.Properties.Select(p => p.Id).ToList();
            vm.Accommodation = "all";
        }
        else if (Shell.IsLandlord && long.TryParse(accommodation, out var chosen) && CanSee(chosen))
        {
            accIds = [chosen];
            vm.Accommodation = chosen.ToString();
        }
        else if (CurrentAccommodationId is long current)
        {
            accIds = [current];
            vm.Accommodation = current.ToString();
        }
        else
        {
            return View(vm);   // no property yet
        }

        vm.AccommodationNames = Shell.Properties.ToDictionary(p => p.Id, p => p.Name);
        var ids = SupabaseDb.In(accIds);

        try
        {
            var roomsTask = Db.GetAsync<Room>(
                $"room?select=id,room_number,floor,accommodation_id&accommodation_id={ids}&order=room_number.asc");

            var requestsTask = Db.GetAsync<MaintenanceRequest>(
                "maintenance_request?select=*,student(id,name,surname,student_number)," +
                "room!inner(id,room_number,floor,accommodation_id)" +
                $"&room.accommodation_id={ids}&order=date_submitted.desc");

            await Task.WhenAll(roomsTask, requestsTask);
            vm.Rooms = roomsTask.Result;
            var all = requestsTask.Result;

            // Stat cards: totals for the chosen property, before the filters
            vm.Total = all.Count;
            vm.Urgent = all.Count(r => r.IsActive && r.Priority == RequestPriority.Urgent);
            vm.InProgress = all.Count(r => r.Status == RequestStatus.InProgress);
            vm.Resolved = all.Count(r => r.Status == RequestStatus.Closed);

            // Filters
            vm.Requests = all
                .Where(r => MatchesStatus(r, status))
                .Where(r => string.IsNullOrEmpty(priority) || r.Priority == priority)
                .Where(r => room == null || r.RoomId == room)
                .ToList();
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not load requests: " + ex.Message;
        }

        return View(vm);
    }

    /// <summary>"Open" means not started yet: Open or Assigned.</summary> 
    /// 
        // ---------------- DETAILS ----------------

    public async Task<IActionResult> Details(long id, string? tab)
    {
        var request = await LoadRequestAsync(id);
        if (request == null) return NotFound();                          // RLS hid it, or it doesn't exist
        if (!CanSee(request.Room?.AccommodationId)) return Forbid();      // another building

        // First time staff open it: "Viewed by …" on the timeline
        if (request.ViewedAt == null)
        {
            try
            {
                await Db.RpcAsync("mark_request_viewed", new { p_request_id = id });
                request = await LoadRequestAsync(id) ?? request;
            }
            catch (SupabaseException) { /* not critical */ }
        }

        var historyTask = Db.GetAsync<StatusHistoryEntry>(
            $"status_history?select=*&request_id=eq.{id}&order=changed_at.asc,id.asc");
        var photosTask = Db.GetAsync<RequestPhoto>(
            $"request_photo?select=*&request_id=eq.{id}&order=uploaded_at.asc");
        await Task.WhenAll(historyTask, photosTask);

        var history = historyTask.Result;
        var photos = photosTask.Result;

        // Temporary links for the private photos (in upload order)
        var links = await Db.SignedPhotoUrlsAsync(photos.Select(p => p.Path));

        var vm = new RequestDetailsViewModel
        {
            Request = request,
            AccommodationName = Shell.Properties
                .FirstOrDefault(p => p.Id == request.Room?.AccommodationId)?.Name ?? "",
            PhotoUrls = photos.Select(p => links.GetValueOrDefault(p.Path))
                              .OfType<string>().ToList(),
            Timeline = BuildTimeline(request, history),
            LastUpdated = history.Count > 0 ? history.Max(h => h.ChangedAt) : request.DateSubmitted,
            NextStep = NextStepFor(request, history),
            Tab = tab is "updates" or "attachments" ? tab : "details",
            Form = new UpdateRequestForm { Status = request.Status, Priority = request.Priority }
        };

        ViewData["Title"] = $"Request {request.Reference}";
        ViewData["Active"] = "Requests";
        ViewData["Heading"] = "Request Details";
        return View(vm);
    }

    // ---------------- UPDATE (Updates tab) ----------------

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Update(long id, [Bind(Prefix = "Form")] UpdateRequestForm form)
    {
        var request = await LoadRequestAsync(id);
        if (request == null) return NotFound();
        if (!CanSee(request.Room?.AccommodationId)) return Forbid();

        // "Mark as Completed" button overrides the chosen status
        var status = string.IsNullOrEmpty(form.QuickStatus) ? form.Status : form.QuickStatus;

        if (!ModelState.IsValid
            || !RequestStatus.StaffChoices.Contains(status)
            || !RequestPriority.All.Contains(form.Priority))
        {
            TempData["Error"] = "Choose a valid status and priority (notes up to 500 characters).";
            return RedirectToAction(nameof(Details), new { id, tab = "updates" });
        }

        try
        {
            // The database function checks access, records the timeline and
            // stops staff from setting Closed (Step W1)
            await Db.RpcAsync("staff_update_request", new
            {
                p_request_id = id,
                p_status = status,
                p_priority = form.Priority,
                p_note = string.IsNullOrWhiteSpace(form.Note) ? null : form.Note.Trim()
            });

            TempData["Success"] = status == RequestStatus.Completed && request.Status != RequestStatus.Completed
                ? "Marked as completed. The student will be asked to confirm the fix."
                : "Request updated.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = ex.Message;   // e.g. "Nothing to update"
        }

        return RedirectToAction(nameof(Details), new { id, tab = "updates" });
    }

    // ---------------- Helpers for Details ----------------

    private Task<MaintenanceRequest?> LoadRequestAsync(long id) =>
        Db.GetOneAsync<MaintenanceRequest>(
            "maintenance_request?select=*,student(id,name,surname,student_number,email,phone)," +
            $"room!inner(id,room_number,floor,accommodation_id)&id=eq.{id}");

    /// <summary>Turns status_history (+ "viewed") into the timeline on the Details tab.</summary>
    private static List<TimelineItem> BuildTimeline(MaintenanceRequest r, List<StatusHistoryEntry> history)
    {
        var items = new List<TimelineItem>();

        for (var i = 0; i < history.Count; i++)
        {
            var h = history[i];
            var when = Ui.Local(h.ChangedAt);

            if (h.Kind == "note")
            {
                items.Add(new("Note added", h.Note ?? "", when, "note"));
            }
            else if (i == 0)
            {
                items.Add(new("Request submitted", "Student reported the issue through the mobile app.", when, "submitted"));
            }
            else if (h.Status == RequestStatus.Open)
            {
                // Back to Open after the first entry = student said it's not fixed
                items.Add(new("Reopened by student", h.Note ?? "The student says the problem is not fixed.", when, "reopened"));
            }
            else if (h.Status == RequestStatus.Closed)
            {
                items.Add(new("Resolved", h.Note ?? "The student confirmed the problem is fixed.", when, "resolved"));
            }
            else
            {
                items.Add(new($"Status changed to {RequestStatus.Label(h.Status)}", h.Note ?? "", when, "status"));
            }
        }

        if (r.ViewedAt is DateTimeOffset viewed)
            items.Add(new("Viewed", $"Viewed by {r.ViewedBy ?? "staff"}.", Ui.Local(viewed), "viewed"));

        return items.OrderBy(i => i.When).ToList();
    }

    /// <summary>The blue "Next step" box on the Details tab.</summary>
    private static string NextStepFor(MaintenanceRequest r, List<StatusHistoryEntry> history)
    {
        var reopened = history.Count > 1 && history[^1].Kind == "status" && history[^1].Status == RequestStatus.Open;
        var service = string.IsNullOrWhiteSpace(r.Category) || r.Category == "Other"
            ? "maintenance"
            : r.Category.ToLower();

        return r.Status switch
        {
            RequestStatus.Open when reopened =>
                "The student says the problem is not fixed. Arrange a follow-up repair and update the status.",
            RequestStatus.Open =>
                $"Contact a {service} service to resolve the issue, then set the status to Assigned or In Progress.",
            RequestStatus.Assigned =>
                "Arrange the repair with maintenance, and set the status to In Progress once work starts.",
            RequestStatus.InProgress =>
                "Mark the request as completed once the work is finished. The student will then confirm the fix in the app.",
            RequestStatus.Completed =>
                "Waiting for the student to confirm the fix in the app. If it isn't fixed, the request returns to Open.",
            _ => "The student confirmed the problem is fixed. No further action is needed."
        };
    }
    private static bool MatchesStatus(MaintenanceRequest r, string? status) => status switch
    {
        null or "" => true,
        RequestStatus.Open => r.Status is RequestStatus.Open or RequestStatus.Assigned,
        _ => r.Status == status
    };
}