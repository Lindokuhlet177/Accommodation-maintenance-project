using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;

namespace StudentStayFix.Web.Controllers;

/// <summary>What students did: new, reopened and resolved requests.</summary>
public class NotificationsController : AppController
{
    public NotificationsController(SupabaseDb db, PropertyContext property) : base(db, property) { }

    public async Task<IActionResult> Index()
    {
        ViewData["Title"] = "Notifications";
        ViewData["Active"] = "";
        ViewData["Heading"] = "Notifications";

        var vm = new StaffNotificationsViewModel();

        try
        {
            // When did I last look? (decides New vs Earlier)
            var me = await Db.GetOneAsync<Staff>($"staff?select=id,notifications_seen_at&id=eq.{User.UserId()}");
            var seenAt = me?.NotificationsSeenAt;

            // Student actions on requests I may see (RLS: caretaker = own building)
            var rows = await Db.GetAsync<StaffEventRow>(
                "status_history?select=id,request_id,status,note,changed_at," +
                "maintenance_request!inner(id,title,room(id,room_number,accommodation_id),student(id,name,surname))" +
                "&kind=eq.status&status=in.(Open,Closed)&order=changed_at.desc&limit=50");

            var names = Shell.Properties.ToDictionary(p => p.Id, p => p.Name);
            vm.Items = rows.Select(r => ToNotification(r, seenAt, names)).ToList();

            // Landlord: things waiting for action
            if (Shell.IsLandlord)
            {
                vm.PendingRegistrations = (await Db.GetAsync<PendingStudent>(
                    "student?select=id&registration_status=eq.pending&room_id=is.null")).Count;
                vm.PendingCaretakers = (await Db.GetAsync<Staff>(
                    "staff?select=id&role=eq.Caretaker&is_approved=eq.false")).Count;
            }

            // Opening the page clears the bell (New stays highlighted this time)
            await Db.RpcAsync("mark_staff_notifications_seen");
            Shell.UnreadCount = 0;
            Shell.HasNotifications = false;
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not load notifications: " + ex.Message;
        }

        return View(vm);
    }

    private static StaffNotification ToNotification(
        StaffEventRow r, DateTimeOffset? seenAt, Dictionary<long, string> names)
    {
        var req = r.MaintenanceRequest;
        var student = req?.Student == null ? "Former resident" : $"{req.Student.Name} {req.Student.Surname}".Trim();
        var property = req?.Room != null && names.TryGetValue(req.Room.AccommodationId, out var n) ? n : "";
        var where = $"{student} • Room {req?.Room?.RoomNumber}" + (property == "" ? "" : $" • {property}");

        // The trigger writes "Request submitted" for new requests and
        // "Student reported still a problem: <comment>" when reopened
        var note = r.Note ?? "";
        var colon = note.IndexOf(": ", StringComparison.Ordinal);
        var comment = colon >= 0 ? note[(colon + 2)..] : null;

        var (kind, title) = r.Status switch
        {
            RequestStatus.Closed => ("resolved", $"Resolved: {req?.Title}"),
            _ when note.StartsWith("Request submitted") => ("new", $"New request: {req?.Title}"),
            _ => ("reopened", $"Reopened: {req?.Title}")
        };

        return new StaffNotification
        {
            Kind = kind,
            Title = title,
            Text = where,
            Comment = comment,
            RequestId = r.RequestId,
            When = r.ChangedAt,
            IsUnread = seenAt == null || r.ChangedAt > seenAt
        };
    }
}