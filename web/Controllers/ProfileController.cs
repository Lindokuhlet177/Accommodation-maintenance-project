using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;
using System.Security.Claims;

namespace StudentStayFix.Web.Controllers;

/// <summary>My profile: photo, name, phone (landlord and caretaker).</summary>
public class ProfileController : AppController
{
    private const long MaxPhotoBytes = 2 * 1024 * 1024;   // same as the bucket limit

    public ProfileController(SupabaseDb db, PropertyContext property) : base(db, property) { }

    public async Task<IActionResult> Index()
    {
        ViewData["Title"] = "My profile";
        ViewData["Active"] = "";
        ViewData["Heading"] = "My Profile";

        var me = await Db.GetOneAsync<Staff>($"staff?select=*&id=eq.{User.UserId()}");
        if (me == null) return RedirectToAction("Logout", "Account");

        return View(new ProfilePageViewModel
        {
            Staff = me,
            AvatarUrl = Db.AvatarUrl(me.AvatarPath),
            BuildingText = Shell.IsLandlord
                ? "All properties"
                : Shell.Current?.Name ?? "Not linked yet",
            Form = new ProfileForm { Name = me.Name, Phone = me.Phone }
        });
    }

    // ---------------- Name + phone ----------------

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Update([Bind(Prefix = "Form")] ProfileForm form)
    {
        if (!ModelState.IsValid)
        {
            TempData["Error"] = ModelState.Values.SelectMany(v => v.Errors)
                .Select(e => e.ErrorMessage).FirstOrDefault() ?? "Check your details.";
            return RedirectToAction(nameof(Index));
        }

        try
        {
            // Updates ONLY the caller's own name and phone (Step P1)
            await Db.RpcAsync("update_my_staff_profile", new
            {
                p_name = form.Name.Trim(),
                p_phone = string.IsNullOrWhiteSpace(form.Phone) ? null : form.Phone.Trim()
            });

            await UpdateCookieClaimAsync(ClaimTypes.Name, form.Name.Trim());   // header shows new name
            TempData["Success"] = "Profile updated.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    // ---------------- Photo ----------------

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(3_000_000)]
    public async Task<IActionResult> Photo(IFormFile? photo)
    {
        if (photo == null || photo.Length == 0)
        {
            TempData["Error"] = "Choose a photo to upload.";
            return RedirectToAction(nameof(Index));
        }
        if (photo.Length > MaxPhotoBytes)
        {
            TempData["Error"] = "The photo is too big (maximum 2 MB).";
            return RedirectToAction(nameof(Index));
        }

        byte[] bytes;
        using (var ms = new MemoryStream())
        {
            await photo.CopyToAsync(ms);
            bytes = ms.ToArray();
        }

        // Check the file really is a JPEG, PNG or WebP (not just its name)
        var kind = DetectImage(bytes);
        if (kind == null)
        {
            TempData["Error"] = "Use a JPG, PNG or WebP photo.";
            return RedirectToAction(nameof(Index));
        }

        var userId = User.UserId();
        var oldPath = User.AvatarPathOf();
        // New name each time, so browsers never show an old cached photo
        var path = $"{userId}/avatar-{DateTime.UtcNow.Ticks}.{kind.Value.Ext}";

        try
        {
            await Db.UploadAvatarAsync(path, bytes, kind.Value.ContentType);
            await Db.RpcAsync("set_my_avatar", new { p_path = path });
            await UpdateCookieClaimAsync(AppClaims.AvatarPath, path);
            await Db.DeleteAvatarAsync(oldPath);    // tidy up the previous photo
            TempData["Success"] = "Photo updated.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = "Could not upload the photo: " + ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RemovePhoto()
    {
        var oldPath = User.AvatarPathOf();
        try
        {
            await Db.RpcAsync("set_my_avatar", new { p_path = (string?)null });
            await UpdateCookieClaimAsync(AppClaims.AvatarPath, null);
            await Db.DeleteAvatarAsync(oldPath);
            TempData["Success"] = "Photo removed.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = ex.Message;
        }
        return RedirectToAction(nameof(Index));
    }

    /// <summary>Recognises JPEG, PNG and WebP from their first bytes.</summary>
    private static (string Ext, string ContentType)? DetectImage(byte[] b)
    {
        if (b.Length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF)
            return ("jpg", "image/jpeg");
        if (b.Length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47)
            return ("png", "image/png");
        if (b.Length > 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
            && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P')
            return ("webp", "image/webp");
        return null;
    }
}
