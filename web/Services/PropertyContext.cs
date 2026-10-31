using StudentStayFix.Web.Models;

namespace StudentStayFix.Web.Services;

/// <summary>Everything the sidebar and header need on every page.</summary>
public class ShellModel
{
    public bool IsLandlord { get; set; }
    public string UserName { get; set; } = "";
    public string RoleName { get; set; } = "";
    public string Initials { get; set; } = "?";

    /// <summary>Landlord: all properties. Caretaker: only their own.</summary>
    public List<Accommodation> Properties { get; set; } = [];

    /// <summary>The property being viewed (sidebar "PROPERTY" card).</summary>
    public Accommodation? Current { get; set; }

    /// <summary>Red dot on the bell (filled in on later steps).</summary>
    public bool HasNotifications { get; set; }

    /// <summary>Unread notifications (red number on the bell).</summary>
    public int UnreadCount { get; set; }
    /// <summary>Profile photo link, or null to show initials.</summary>
    public string? AvatarUrl { get; set; }
}

/// <summary>
/// Works out which properties the user may see and which one is selected.
/// Landlord: picked in the sidebar (remembered in a cookie). Caretaker: always theirs.
/// </summary>
public class PropertyContext
{
    public const string CookieName = "ssf_property";

    private readonly SupabaseDb _db;
    private readonly IHttpContextAccessor _ctx;

    public PropertyContext(SupabaseDb db, IHttpContextAccessor ctx)
    {
        _db = db;
        _ctx = ctx;
    }

    public async Task<ShellModel> LoadAsync()

    {

        var http = _ctx.HttpContext!;
        var user = http.User;

        var shell = new ShellModel
        {
            IsLandlord = user.IsLandlord(),
            UserName = user.FullName(),
            RoleName = user.RoleName(),
            Initials = AppClaims.Initials(user.FullName()),
            AvatarUrl = _db.AvatarUrl(user.AvatarPathOf()),
        };

        if (shell.IsLandlord)
        {
            shell.Properties = await _db.GetAsync<Accommodation>(
                "accommodation?select=id,name,address&order=name.asc");

            var picked = http.Request.Cookies[CookieName];
            shell.Current = shell.Properties.FirstOrDefault(p => p.Id.ToString() == picked)
                            ?? shell.Properties.FirstOrDefault();
        }
        else if (user.StaffAccommodationId() is long id)
        {
            shell.Properties = await _db.GetAsync<Accommodation>(
                $"accommodation?select=id,name,address&id=eq.{id}");
            shell.Current = shell.Properties.FirstOrDefault();
        }
        // Bell: unread count (not critical, so a failure just shows no badge)
        try
        {
            shell.UnreadCount = await _db.RpcAsync<int>("staff_unread_notifications");
            shell.HasNotifications = shell.UnreadCount > 0;
        }
        catch (SupabaseException) { }
        return shell;

    }

    /// <summary>Landlord picked another property in the sidebar.</summary>
    public static void SetCurrent(HttpResponse response, long accommodationId)
    {
        response.Cookies.Append(CookieName, accommodationId.ToString(), new CookieOptions
        {
            HttpOnly = true,
            Secure = true,
            SameSite = SameSiteMode.Lax,
            Expires = DateTimeOffset.UtcNow.AddDays(30)
        });
    }
}