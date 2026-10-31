using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;
using Microsoft.AspNetCore.Authorization;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;

namespace StudentStayFix.Web.Controllers;

public class PropertyController : AppController
{
    public PropertyController(SupabaseDb db, PropertyContext property) : base(db, property) { }

    /// <summary>Sidebar: switch to another property, then stay on the same page.</summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Select(long id, string? returnUrl)
    {
        if (Shell.IsLandlord && CanSee(id))
            PropertyContext.SetCurrent(Response, id);

        return !string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl)
            ? LocalRedirect(returnUrl)
            : RedirectToAction("Index", "Dashboard");
    }

    // ---------------- ADD PROPERTY (landlord) ----------------

    [HttpGet]
    [Authorize(Policy = "LandlordOnly")]
    public IActionResult Create()
    {
        SetTitles();
        return View(new PropertyForm());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = "LandlordOnly")]
    public async Task<IActionResult> Create(PropertyForm form)
    {
        SetTitles();
        if (!ModelState.IsValid) return View(form);

        var name = form.Name.Trim();

        // No two properties with the same name
        if (Shell.Properties.Any(p => string.Equals(p.Name, name, StringComparison.OrdinalIgnoreCase)))
        {
            ModelState.AddModelError(nameof(form.Name), "You already have a property with this name");
            return View(form);
        }

        try
        {
            // Policy "Landlord can add accommodations" (Step W1)
            var created = await Db.InsertAsync<Accommodation>("accommodation", new
            {
                name,
                address = string.IsNullOrWhiteSpace(form.Address) ? null : form.Address.Trim()
            });

            // Select the new property, then go and add its rooms
            PropertyContext.SetCurrent(Response, created.Id);
            TempData["Success"] = $"{created.Name} added. Now add its rooms.";
            return RedirectToAction("Index", "Rooms");
        }
        catch (SupabaseException ex)
        {
            ModelState.AddModelError("", "Could not add the property: " + ex.Message);
            return View(form);
        }
    }

    private void SetTitles()
    {
        ViewData["Title"] = "Add property";
        ViewData["Active"] = "";
        ViewData["Heading"] = "Add Property";
    }

    // ---------------- REMOVE PROPERTY (added by mistake) ----------------

    [HttpGet]
    [Authorize(Policy = "LandlordOnly")]
    public async Task<IActionResult> Remove()
    {
        if (Shell.Current is not Accommodation property) return RedirectToAction("Index", "Dashboard");

        ViewData["Title"] = "Remove property";
        ViewData["Active"] = "";
        ViewData["Heading"] = "Remove Property";

        var id = property.Id;
        var rooms = await Db.GetAsync<Room>($"room?select=id&accommodation_id=eq.{id}");
        var roomIds = SupabaseDb.In(rooms.Select(r => r.Id));

        var vm = new RemovePropertyViewModel
        {
            Property = property,
            Rooms = rooms.Count,
            Tenants = rooms.Count == 0 ? 0 :
                (await Db.GetAsync<Tenancy>($"tenancy?select=id&room_id={roomIds}")).Count,
            Requests = rooms.Count == 0 ? 0 :
                (await Db.GetAsync<MaintenanceRequest>($"maintenance_request?select=id&room_id={roomIds}")).Count,
            Caretakers = (await Db.GetAsync<Staff>($"staff?select=id&accommodation_id=eq.{id}")).Count
        };

        return View(vm);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Policy = "LandlordOnly")]
    public async Task<IActionResult> Remove(long id)
    {
        if (!CanSee(id)) return Forbid();
        var name = Shell.Properties.First(p => p.Id == id).Name;

        try
        {
            // The database re-checks everything (tenants, requests, caretakers)
            await Db.RpcAsync("delete_property", new { p_accommodation_id = id });

            // Forget the removed property; the sidebar falls back to the first one
            Response.Cookies.Delete(PropertyContext.CookieName);
            TempData["Success"] = $"{name} has been removed.";
            return RedirectToAction("Index", "Dashboard");
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = ex.Message;
            return RedirectToAction(nameof(Remove));
        }
    }
}