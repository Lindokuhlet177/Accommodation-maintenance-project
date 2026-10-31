using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;

namespace StudentStayFix.Web.Controllers;

[Authorize(Policy = "LandlordOnly")]
public class RoomsController : AppController
{
    public RoomsController(SupabaseDb db, PropertyContext property) : base(db, property) { }

    // ---------------- LIST ----------------

    public async Task<IActionResult> Index(string? search, int? floor)
    {
        ViewData["Title"] = "Rooms";
        ViewData["Active"] = "Rooms";
        ViewData["Heading"] = "Rooms";

        var vm = new RoomListViewModel { Search = search, Floor = floor };
        if (CurrentAccommodationId is not long accId) return View(vm);

        try
        {
            var rooms = await Db.GetAsync<Room>($"room?select=*&accommodation_id=eq.{accId}");
            var tenancies = rooms.Count == 0
                ? []
                : await Db.GetAsync<Tenancy>(
                    $"tenancy?select=*&room_id={SupabaseDb.In(rooms.Select(r => r.Id))}&order=created_at.asc");

            var rows = rooms
                .Select(r => new RoomRow { Room = r, Tenants = tenancies.Where(t => t.RoomId == r.Id).ToList() })
                .OrderBy(r => r.Room.Floor)
                .ThenBy(r => r.Room.RoomNumber.Length)      // "2A" before "10A"
                .ThenBy(r => r.Room.RoomNumber)
                .ToList();

            vm.TotalRooms = rows.Count;
            vm.Floors = rows.Select(r => r.Room.Floor).Distinct().Order().ToList();

            vm.Rows = rows
                .Where(r => string.IsNullOrWhiteSpace(search)
                            || r.Room.RoomNumber.Contains(search.Trim(), StringComparison.OrdinalIgnoreCase))
                .Where(r => floor == null || r.Room.Floor == floor)
                .ToList();
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not load rooms: " + ex.Message;
        }

        return View(vm);
    }

    // ---------------- VIEW ONE ROOM ----------------

    public async Task<IActionResult> Details(long id)
    {
        var room = await Db.GetOneAsync<Room>($"room?select=*&id=eq.{id}");
        if (room == null) return NotFound();
        if (!CanSee(room.AccommodationId)) return Forbid();

        var tenantsTask = Db.GetAsync<Tenancy>($"tenancy?select=*&room_id=eq.{id}&order=created_at.asc");
        var requestsTask = Db.GetAsync<MaintenanceRequest>(
            $"maintenance_request?select=*,student(id,name,surname)&room_id=eq.{id}&order=date_submitted.desc");
        await Task.WhenAll(tenantsTask, requestsTask);

        var vm = new RoomDetailsViewModel
        {
            Row = new RoomRow { Room = room, Tenants = tenantsTask.Result },
            AccommodationName = Shell.Properties.FirstOrDefault(p => p.Id == room.AccommodationId)?.Name ?? "",
            Requests = requestsTask.Result
        };

        ViewData["Title"] = $"Room {room.RoomNumber}";
        ViewData["Active"] = "Rooms";
        ViewData["Heading"] = $"Room {room.RoomNumber}";
        return View(vm);
    }

    // ---------------- ADD ROOM ----------------

    [HttpGet]
    public IActionResult Create()
    {
        if (CurrentAccommodationId == null) return RedirectToAction(nameof(Index));
        SetCreateTitles();
        return View(new RoomForm());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(RoomForm form)
    {
        if (CurrentAccommodationId is not long accId) return RedirectToAction(nameof(Index));
        SetCreateTitles();

        if (!RoomForm.Types.Contains(form.RoomType))
            ModelState.AddModelError(nameof(form.RoomType), "Choose Single or Double");

        if (!ModelState.IsValid) return View(form);

        var number = form.RoomNumber.Trim().ToUpperInvariant();

        try
        {
            // No two rooms with the same number in one property
            var existing = await Db.GetOneAsync<Room>(
                $"room?select=id&accommodation_id=eq.{accId}&room_number=eq.{SupabaseDb.Enc(number)}");
            if (existing != null)
            {
                ModelState.AddModelError(nameof(form.RoomNumber), $"Room {number} already exists in this property");
                return View(form);
            }

            await Db.InsertAsync<Room>("room", new
            {
                accommodation_id = accId,
                room_number = number,
                floor = form.Floor,
                room_type = form.RoomType,
                capacity = form.Capacity
            });

            TempData["Success"] = $"Room {number} added.";
            return RedirectToAction(nameof(Index));
        }
        catch (SupabaseException ex)
        {
            ModelState.AddModelError("", "Could not add the room: " + ex.Message);
            return View(form);
        }
    }

    private void SetCreateTitles()
    {
        ViewData["Title"] = "Add room";
        ViewData["Active"] = "Rooms";
        ViewData["Heading"] = "Add Room";
    }
}