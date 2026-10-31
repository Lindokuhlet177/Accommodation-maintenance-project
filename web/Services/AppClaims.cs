using System.Security.Claims;

namespace StudentStayFix.Web.Services;

/// <summary>
/// What we store in the login cookie, and easy ways to read it back.
/// </summary>
public static class AppClaims
{
    // Extra values kept in the cookie (besides id, name, email, role)
    public const string AccessToken = "sb_access_token";
    public const string RefreshToken = "sb_refresh_token";
    public const string ExpiresAt = "sb_expires_at";
    public const string AccommodationId = "accommodation_id";
    public const string AvatarPath = "avatar_path";

    // ---------- Reading the logged-in user ----------

    public static string UserId(this ClaimsPrincipal user) =>
        user.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "";

    public static string FullName(this ClaimsPrincipal user) =>
        user.FindFirst(ClaimTypes.Name)?.Value ?? "";

    public static string FirstName(this ClaimsPrincipal user) =>
        user.FullName().Split(' ', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? "";

    public static string RoleName(this ClaimsPrincipal user) =>
        user.FindFirst(ClaimTypes.Role)?.Value ?? "";

    public static bool IsLandlord(this ClaimsPrincipal user) => user.IsInRole("Landlord");

    /// <summary>Caretaker: their building. Landlord: null (sees all).</summary>
    public static long? StaffAccommodationId(this ClaimsPrincipal user) =>
        long.TryParse(user.FindFirst(AccommodationId)?.Value, out var id) ? id : null;

    public static string? AvatarPathOf(this ClaimsPrincipal user)
    {
        var v = user.FindFirst(AvatarPath)?.Value;
        return string.IsNullOrWhiteSpace(v) ? null : v;
    }

    public static string Initials(string name)
    {
        var parts = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return "?";
        if (parts.Length == 1) return parts[0][..1].ToUpper();
        return (parts[0][..1] + parts[^1][..1]).ToUpper();
    }

    // ---------- Building the cookie at login ----------

    public static List<Claim> Build(
    string userId, string name, string email, string role,
    long? accommodationId, string? avatarPath, AuthSession session) =>
[
    new(ClaimTypes.NameIdentifier, userId),
        new(ClaimTypes.Name, name),
        new(ClaimTypes.Email, email),
        new(ClaimTypes.Role, role),
        new(AccommodationId, accommodationId?.ToString() ?? ""),
        new(AvatarPath, avatarPath ?? ""),
        new(AccessToken, session.AccessToken),
        new(RefreshToken, session.RefreshToken),
        new(ExpiresAt, session.ExpiresAt.ToString())
];
}