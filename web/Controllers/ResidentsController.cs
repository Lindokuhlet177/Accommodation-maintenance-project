using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;
using System.Net.Mail;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using static StudentStayFix.Web.Models.ViewModels.TenantForm;

namespace StudentStayFix.Web.Controllers;

[Authorize(Policy = "LandlordOnly")]
public class ResidentsController : AppController
{
    public ResidentsController(SupabaseDb db, PropertyContext property) : base(db, property) { }

    // ---------------- TENANTS LIST ----------------

    public async Task<IActionResult> Index(string? search, string? accommodation, long? room)
    {
        ViewData["Title"] = "Tenants";
        ViewData["Active"] = "Residents";
        ViewData["Heading"] = "Tenants";

        var vm = new TenantListViewModel
        {
            Search = search,
            Room = room,
            Accommodations = Shell.Properties,
            AccommodationNames = Shell.Properties.ToDictionary(p => p.Id, p => p.Name)
        };

        // "all", a chosen property, or the one selected in the sidebar
        List<long> accIds;
        if (accommodation == "all")
        {
            accIds = Shell.Properties.Select(p => p.Id).ToList();
            vm.Accommodation = "all";
        }
        else if (long.TryParse(accommodation, out var chosen) && CanSee(chosen))
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
            return View(vm);
        }

        if (accIds.Count == 0) return View(vm);
        var ids = SupabaseDb.In(accIds);

        try
        {
            var roomsTask = Db.GetAsync<Room>($"room?select=*&accommodation_id={ids}&order=room_number.asc");
            var tenantsTask = Db.GetAsync<Tenancy>(
                "tenancy?select=*,room!inner(id,room_number,floor,accommodation_id)" +
                $"&room.accommodation_id={ids}&order=surname.asc,name.asc");
            await Task.WhenAll(roomsTask, tenantsTask);

            vm.Rooms = roomsTask.Result;
            vm.Total = tenantsTask.Result.Count;

            var q = search?.Trim();
            vm.Rows = tenantsTask.Result
                .Where(t => string.IsNullOrEmpty(q)
                            || t.FullName.Contains(q, StringComparison.OrdinalIgnoreCase)
                            || t.StudentNumber.Contains(q, StringComparison.OrdinalIgnoreCase))
                .Where(t => room == null || t.RoomId == room)
                .ToList();
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not load tenants: " + ex.Message;
        }
        // Number of unmatched sign-ups, for the "Registration requests" button
        try
        {
            var pending = await Db.GetAsync<PendingStudent>(
                "student?select=id&registration_status=eq.pending&room_id=is.null");
            ViewData["PendingCount"] = pending.Count;
        }
        catch (SupabaseException) { ViewData["PendingCount"] = 0; }

        // Caretakers waiting for approval, for the "Caretakers" button
        try
        {
            var waiting = await Db.GetAsync<Staff>("staff?select=id&role=eq.Caretaker&is_approved=eq.false");
            ViewData["PendingCaretakers"] = waiting.Count;
        }
        catch (SupabaseException) { ViewData["PendingCaretakers"] = 0; }
        return View(vm);
    }

    // ---------------- ADD TENANT ----------------

    [HttpGet]
    public async Task<IActionResult> Create(long? roomId)
    {
        if (CurrentAccommodationId == null) return RedirectToAction(nameof(Index));
        SetCreateTitles();

        var form = new TenantForm();
        await LoadRoomChoicesAsync(form);

        // Coming from a room page ("+ Add tenant"): pre-select that room if it has space
        if (roomId != null && form.RoomChoices.Any(r => r.Room.Id == roomId && !r.IsOccupied))
            form.RoomId = roomId;

        return View(form);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(TenantForm form)
    {
        if (CurrentAccommodationId == null) return RedirectToAction(nameof(Index));
        SetCreateTitles();
        await LoadRoomChoicesAsync(form);

        // The room must belong to the property being viewed
        if (form.RoomId != null && form.RoomChoices.All(r => r.Room.Id != form.RoomId))
            ModelState.AddModelError(nameof(form.RoomId), "Choose a room in this property");

        if (!ModelState.IsValid) return View(form);

        try
        {
            // add_tenancy (Step W1c): landlord check, capacity, duplicates,
            // and links a student who already signed up with these details
            var tenancyId = await Db.RpcAsync<long>("add_tenancy", new
            {
                p_room_id = form.RoomId,
                p_name = form.Name.Trim(),
                p_surname = form.Surname.Trim(),
                p_student_number = form.StudentNumber.Trim(),
                p_email = string.IsNullOrWhiteSpace(form.Email) ? null : form.Email.Trim(),
                p_phone = string.IsNullOrWhiteSpace(form.Phone) ? null : form.Phone.Trim()
            });

            var saved = await Db.GetOneAsync<Tenancy>($"tenancy?select=*&id=eq.{tenancyId}");
            TempData["Success"] = saved?.HasSignedUp == true
                ? $"{form.Name} {form.Surname} added and linked to their app account."
                : $"{form.Name} {form.Surname} added. They'll be linked automatically when they sign up in the app.";

            return RedirectToAction(nameof(Index));
        }
        catch (SupabaseException ex)
        {
            ModelState.AddModelError("", ex.Message);   // e.g. "This room is already full"
            return View(form);
        }
    }

    // ---------------- VIEW ONE TENANT ----------------

    public async Task<IActionResult> Details(long id)
    {
        var tenancy = await Db.GetOneAsync<Tenancy>(
            $"tenancy?select=*,room!inner(id,room_number,floor,room_type,accommodation_id)&id=eq.{id}");
        if (tenancy == null) return NotFound();
        if (!CanSee(tenancy.Room?.AccommodationId)) return Forbid();

        var vm = new TenantDetailsViewModel
        {
            Tenancy = tenancy,
            AccommodationName = Shell.Properties
                .FirstOrDefault(p => p.Id == tenancy.Room?.AccommodationId)?.Name ?? ""
        };

        // Signed up in the app? Load their account and their requests
        if (tenancy.StudentId is Guid studentId)
        {
            var studentTask = Db.GetOneAsync<RequestStudent>(
                $"student?select=id,name,surname,student_number,email,phone,registered_at&id=eq.{studentId}");
            var requestsTask = Db.GetAsync<MaintenanceRequest>(
                $"maintenance_request?select=*,room(id,room_number,floor,accommodation_id)" +
                $"&student_id=eq.{studentId}&order=date_submitted.desc");
            await Task.WhenAll(studentTask, requestsTask);

            vm.Student = studentTask.Result;
            vm.Requests = requestsTask.Result;
        }

        ViewData["Title"] = tenancy.FullName;
        ViewData["Active"] = "Residents";
        ViewData["Heading"] = "Tenant";
        return View(vm);
    }

    // ---------------- END TENANCY (moving out) ----------------

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EndTenancy(long id)
    {
        var tenancy = await Db.GetOneAsync<Tenancy>(
            $"tenancy?select=*,room!inner(id,room_number,accommodation_id)&id=eq.{id}");
        if (tenancy == null) return NotFound();
        if (!CanSee(tenancy.Room?.AccommodationId)) return Forbid();

        try
        {
            // end_tenancy (Step W1c): removes the contract and the room link,
            // keeps the student's past requests
            await Db.RpcAsync("end_tenancy", new { p_tenancy_id = id });
            TempData["Success"] = $"{tenancy.FullName}'s tenancy in room {tenancy.Room?.RoomNumber} has ended.";
            return RedirectToAction(nameof(Index));
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not end the tenancy: " + ex.Message;
            return RedirectToAction(nameof(Details), new { id });
        }
    }
    // ---------------- REGISTRATION REQUESTS (unmatched sign-ups) ----------------

    public async Task<IActionResult> Registrations()
    {
        ViewData["Title"] = "Registration requests";
        ViewData["Active"] = "Residents";
        ViewData["Heading"] = "Registration Requests";

        var vm = new RegistrationListViewModel();

        try
        {
            vm.Students = await Db.GetAsync<PendingStudent>(
                "student?select=id,name,surname,student_number,email,registered_at" +
                "&registration_status=eq.pending&room_id=is.null&order=registered_at.desc");

            // Rooms with a free bed, in every property, for the dropdown
            var ids = SupabaseDb.In(Shell.Properties.Select(p => p.Id));
            var rooms = Shell.Properties.Count == 0 ? [] :
                await Db.GetAsync<Room>($"room?select=*&accommodation_id={ids}");
            var tenancies = rooms.Count == 0 ? [] :
                await Db.GetAsync<Tenancy>($"tenancy?select=id,room_id&room_id={SupabaseDb.In(rooms.Select(r => r.Id))}");

            vm.RoomGroups = Shell.Properties
                .Select(p => new RoomGroup(p.Name, rooms
                    .Where(r => r.AccommodationId == p.Id)
                    .Select(r => new RoomRow { Room = r, Tenants = tenancies.Where(t => t.RoomId == r.Id).ToList() })
                    .Where(r => !r.IsOccupied)
                    .OrderBy(r => r.Room.Floor).ThenBy(r => r.Room.RoomNumber.Length).ThenBy(r => r.Room.RoomNumber)
                    .ToList()))
                .Where(g => g.Rooms.Count > 0)
                .ToList();
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not load registration requests: " + ex.Message;
        }

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> LinkStudent(Guid studentId, long? roomId, string? studentNumber)
    {
        if (roomId == null)
        {
            TempData["Error"] = "Choose a room for the student.";
            return RedirectToAction(nameof(Registrations));
        }

        try
        {
            // No student number yet? Save the one the landlord typed first
            if (!string.IsNullOrWhiteSpace(studentNumber))
            {
                await Db.RpcAsync("set_student_number", new
                {
                    p_student_id = studentId,
                    p_student_number = studentNumber.Trim().ToUpperInvariant()
                });
            }

            // Creates the tenancy (capacity check) and links the student (Step W1c)
            await Db.RpcAsync("link_student_to_room", new { p_student_id = studentId, p_room_id = roomId });
            TempData["Success"] = "Student linked to the room. They can now report problems in the app.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = ex.Message;   // e.g. "This room is already full"
        }

        return RedirectToAction(nameof(Registrations));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeclineStudent(Guid studentId)
    {
        try
        {
            await Db.RpcAsync("decline_student_registration", new { p_student_id = studentId });
            TempData["Success"] = "Registration declined.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Registrations));
    }

    // ---------------- CARETAKERS (approve / remove access) ----------------

    public async Task<IActionResult> Caretakers()
    {
        ViewData["Title"] = "Caretakers";
        ViewData["Active"] = "Residents";
        ViewData["Heading"] = "Caretakers";

        var caretakers = new List<Staff>();
        try
        {
            // Pending first, then by name
            caretakers = await Db.GetAsync<Staff>(
                "staff?select=*&role=eq.Caretaker&order=is_approved.asc,name.asc");
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not load caretakers: " + ex.Message;
        }

        return View(caretakers);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ApproveCaretaker(Guid id, long? accommodationId)
    {
        if (accommodationId == null || !CanSee(accommodationId))
        {
            TempData["Error"] = "Choose the building this caretaker works at.";
            return RedirectToAction(nameof(Caretakers));
        }

        try
        {
            // Policy "Landlord can update staff" (Step W1); role filter = caretakers only
            await Db.UpdateAsync("staff", $"id=eq.{id}&role=eq.Caretaker",
                new { is_approved = true, accommodation_id = accommodationId });
            TempData["Success"] = "Caretaker saved. They can sign in now.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not save: " + ex.Message;
        }

        return RedirectToAction(nameof(Caretakers));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RevokeCaretaker(Guid id)
    {
        try
        {
            await Db.UpdateAsync("staff", $"id=eq.{id}&role=eq.Caretaker", new { is_approved = false });
            TempData["Success"] = "Access removed. The caretaker will be signed out within the hour.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not remove access: " + ex.Message;
        }

        return RedirectToAction(nameof(Caretakers));
    }
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RejectCaretaker(Guid id)
    {
        try
        {
            // Removes the pending sign-up completely (Step 1 function)
            await Db.RpcAsync("reject_caretaker", new { p_staff_id = id });
            TempData["Success"] = "Caretaker sign-up rejected and removed.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Caretakers));
    }

    // ---------------- IMPORT A LIST OF TENANTS (CSV) ----------------

    private const int MaxImportRows = 1000;

    [HttpGet]
    public IActionResult Import()
    {
        if (CurrentAccommodationId == null) return RedirectToAction(nameof(Index));
        SetImportTitles();
        return View();
    }

    /// <summary>The template file the landlord fills in.</summary>
    [HttpGet]
    public IActionResult ImportTemplate()
    {
        var csv = "name,surname,student_number,room_number,email,phone\r\n" +
                  "Thandi,Nkosi,222071197,201,thandi@stud.cut.ac.za,0821234567\r\n";
        // UTF-8 with BOM so Excel shows special characters correctly
        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv)).ToArray();
        return File(bytes, "text/csv", "tenant-list-template.csv");
    }

    /// <summary>Step 1: read the file and show the preview (nothing is saved yet).</summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(2_000_000)]
    public async Task<IActionResult> Import(IFormFile? file)
    {
        if (CurrentAccommodationId is not long accId) return RedirectToAction(nameof(Index));
        SetImportTitles();

        if (file == null || file.Length == 0)
            return ImportError("Choose a CSV file to upload.");
        if (!file.FileName.EndsWith(".csv", StringComparison.OrdinalIgnoreCase))
            return ImportError("The file must be a .csv file. In Excel use File → Save As → CSV.");
        if (file.Length > 1_000_000)
            return ImportError("The file is too big (maximum 1 MB).");

        string text;
        using (var reader = new StreamReader(file.OpenReadStream(), Encoding.UTF8))
            text = await reader.ReadToEndAsync();

        var csv = CsvReader.Parse(text);
        if (csv.Count < 2)
            return ImportError("The file has no students in it (only a header, or empty).");
        if (csv.Count - 1 > MaxImportRows)
            return ImportError($"Import at most {MaxImportRows} students at a time.");

        // Find the columns by their header names
        var header = csv[0].Fields;
        int iName = CsvReader.FindColumn(header, "name", "first name", "firstname");
        int iSurname = CsvReader.FindColumn(header, "surname", "last name", "lastname");
        int iNumber = CsvReader.FindColumn(header, "student_number", "student number", "student nr", "student no", "studentno");
        int iRoom = CsvReader.FindColumn(header, "room_number", "room number", "room", "room no");
        int iEmail = CsvReader.FindColumn(header, "email", "email address");
        int iPhone = CsvReader.FindColumn(header, "phone", "cell", "cellphone", "phone number", "contact", "mobile");

        if (iName < 0 || iSurname < 0 || iNumber < 0 || iRoom < 0)
            return ImportError("The file needs the columns name, surname, student_number and room_number. " +
                               "Download the template to see the layout.");

        string Get(string[] f, int i) => i >= 0 && i < f.Length ? f[i].Trim() : "";

        var rows = csv.Skip(1).Select(r => new ImportRow
        {
            Line = r.Line,
            Name = Get(r.Fields, iName),
            Surname = Get(r.Fields, iSurname),
            StudentNumber = Get(r.Fields, iNumber).ToUpperInvariant(),
            RoomNumber = Get(r.Fields, iRoom).ToUpperInvariant(),
            Email = NullIfEmpty(Get(r.Fields, iEmail)),
            Phone = NullIfEmpty(Get(r.Fields, iPhone))
        }).ToList();

        // Check every row against the property's rooms and existing tenants
        try
        {
            var rooms = await Db.GetAsync<Room>($"room?select=*&accommodation_id=eq.{accId}");
            var roomTenants = rooms.Count == 0 ? [] :
                await Db.GetAsync<Tenancy>($"tenancy?select=id,room_id&room_id={SupabaseDb.In(rooms.Select(r => r.Id))}");
            var takenNumbers = (await Db.GetAsync<Tenancy>("tenancy?select=student_number"))
                .Select(t => t.StudentNumber).ToHashSet(StringComparer.OrdinalIgnoreCase);

            CheckRows(rows, rooms, roomTenants, takenNumbers);
        }
        catch (SupabaseException ex)
        {
            return ImportError("Could not check the list: " + ex.Message);
        }

        var vm = new ImportPreviewViewModel
        {
            PropertyName = Shell.Current?.Name ?? "",
            FileName = file.FileName,
            Rows = rows,
            ReadyRowsJson = JsonSerializer.Serialize(rows.Where(r => r.IsReady))
        };
        return View("ImportPreview", vm);
    }

    /// <summary>Step 2: save the ready rows (the database checks everything again).</summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ImportConfirm(string rowsJson)
    {
        if (CurrentAccommodationId is not long accId) return RedirectToAction(nameof(Index));
        SetImportTitles();

        List<ImportRow> rows;
        try { rows = JsonSerializer.Deserialize<List<ImportRow>>(rowsJson) ?? []; }
        catch (JsonException) { rows = []; }

        if (rows.Count == 0 || rows.Count > MaxImportRows)
        {
            TempData["Error"] = "There were no rows to import. Upload the list again.";
            return RedirectToAction(nameof(Import));
        }

        try
        {
            var results = await Db.RpcAsync<List<ImportResult>>("import_tenancies", new
            {
                p_accommodation_id = accId,
                p_rows = rows.Select(r => new
                {
                    line = r.Line,
                    name = r.Name,
                    surname = r.Surname,
                    student_number = r.StudentNumber,
                    room_number = r.RoomNumber,
                    email = r.Email,
                    phone = r.Phone
                })
            }) ?? [];

            return View("ImportSummary", new ImportSummaryViewModel
            {
                PropertyName = Shell.Current?.Name ?? "",
                Results = results,
                NamesByLine = rows.GroupBy(r => r.Line).ToDictionary(g => g.Key, g => g.First().FullName)
            });
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Import failed: " + ex.Message;
            return RedirectToAction(nameof(Import));
        }
    }

    /// <summary>Marks each row Ready or gives its problem (same rules as the database).</summary>
    private static void CheckRows(List<ImportRow> rows, List<Room> rooms,
        List<Tenancy> roomTenants, HashSet<string> takenNumbers)
    {
        var roomsByNumber = rooms.ToDictionary(r => r.RoomNumber.ToUpperInvariant());
        var used = rooms.ToDictionary(r => r.Id, r => roomTenants.Count(t => t.RoomId == r.Id));
        var numbersInFile = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var numberPattern = new Regex(@"^[A-Za-z0-9]+$");
        var phonePattern = new Regex(@"^[0-9+ ()\-]{1,20}$");

        foreach (var r in rows)
        {
            r.Problem =
                r.Name == "" || r.Surname == "" ? "Name and surname are required" :
                r.StudentNumber == "" ? "Student number is required" :
                !numberPattern.IsMatch(r.StudentNumber) ? "Student number: letters and numbers only" :
                !numbersInFile.Add(r.StudentNumber) ? "Student number appears twice in the file" :
                takenNumbers.Contains(r.StudentNumber) ? "This student number already has a room" :
                r.Email != null && !MailAddress.TryCreate(r.Email, out _) ? "Email address is not valid" :
                r.Phone != null && !phonePattern.IsMatch(r.Phone) ? "Phone number is not valid" :
                r.RoomNumber == "" ? "Room number is required" :
                !roomsByNumber.ContainsKey(r.RoomNumber) ? $"Room {r.RoomNumber} does not exist in this property" :
                used[roomsByNumber[r.RoomNumber].Id] >= roomsByNumber[r.RoomNumber].Capacity ? $"Room {r.RoomNumber} is already full" :
                null;

            // A ready row takes a bed, so later rows see the room filling up
            if (r.IsReady) used[roomsByNumber[r.RoomNumber].Id]++;
        }
    }

    private IActionResult ImportError(string message)
    {
        ViewData["ImportError"] = message;
        return View("Import");
    }

    private static string? NullIfEmpty(string s) => string.IsNullOrWhiteSpace(s) ? null : s;

    private void SetImportTitles()
    {
        ViewData["Title"] = "Import tenants";
        ViewData["Active"] = "Residents";
        ViewData["Heading"] = "Import Tenants";
    }
    // ---------------- Helpers ----------------

    /// <summary>Rooms of the current property, with their tenants (to show how full they are).</summary>
    private async Task LoadRoomChoicesAsync(TenantForm form)
    {
        var accId = CurrentAccommodationId!.Value;
        var rooms = await Db.GetAsync<Room>($"room?select=*&accommodation_id=eq.{accId}");
        var tenancies = rooms.Count == 0
            ? []
            : await Db.GetAsync<Tenancy>($"tenancy?select=id,room_id&room_id={SupabaseDb.In(rooms.Select(r => r.Id))}");

        form.RoomChoices = rooms
            .Select(r => new RoomRow { Room = r, Tenants = tenancies.Where(t => t.RoomId == r.Id).ToList() })
            .OrderBy(r => r.Room.Floor)
            .ThenBy(r => r.Room.RoomNumber.Length)
            .ThenBy(r => r.Room.RoomNumber)
            .ToList();
    }

    private void SetCreateTitles()
    {
        ViewData["Title"] = "Add tenant";
        ViewData["Active"] = "Residents";
        ViewData["Heading"] = "Add Tenant";
    }
}