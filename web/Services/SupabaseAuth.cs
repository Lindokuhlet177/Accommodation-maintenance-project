using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Options;

namespace StudentStayFix.Web.Services;

/// <summary>A Supabase login session.</summary>
public class AuthSession
{
    public string AccessToken { get; set; } = "";
    public string RefreshToken { get; set; } = "";
    public long ExpiresAt { get; set; }   // Unix seconds
    public string UserId { get; set; } = "";
    public string Email { get; set; } = "";
}

/// <summary>
/// Talks to Supabase Auth: sign in, refresh, sign up, password reset, sign out.
/// </summary>
public class SupabaseAuth
{
    private readonly HttpClient _http;
    private readonly SupabaseSettings _cfg;

    public SupabaseAuth(HttpClient http, IOptions<SupabaseSettings> cfg)
    {
        _http = http;
        _cfg = cfg.Value;
    }

    // ---------- Public methods ----------

    public async Task<AuthSession> SignInAsync(string email, string password)
    {
        var json = await SendAsync(Build(HttpMethod.Post, "token?grant_type=password",
            new { email, password }));
        return ToSession(json!);
    }

    /// <summary>Swaps an almost-expired session for a fresh one.</summary>
    public async Task<AuthSession> RefreshAsync(string refreshToken)
    {
        var json = await SendAsync(Build(HttpMethod.Post, "token?grant_type=refresh_token",
            new { refresh_token = refreshToken }));
        return ToSession(json!);
    }

    /// <summary>
    /// Creates an account. metadata is read by the database triggers.
    /// Returns true if the user can sign in straight away (no email confirmation).
    /// </summary>
    public async Task<bool> SignUpAsync(string email, string password, object metadata)
    {
        var json = await SendAsync(Build(HttpMethod.Post, "signup",
            new { email, password, data = metadata }));
        return json?["access_token"] != null;
    }

    /// <summary>Emails a reset link that opens redirectTo.</summary>
    /// <summary>Emails a 6-digit reset code (template: Reset Password).</summary>
    public async Task SendPasswordResetAsync(string email)
    {
        await SendAsync(Build(HttpMethod.Post, "recover", new { email }));
    }

    /// <summary>Checks the emailed code. Returns a short session used to set the new password.</summary>
    public async Task<AuthSession> VerifyRecoveryCodeAsync(string email, string code)
    {
        var json = await SendAsync(Build(HttpMethod.Post, "verify",
            new { type = "recovery", email, token = code }));
        return ToSession(json!);
    }

    /// <summary>Sets a new password using the token from the reset link.</summary>
    public async Task UpdatePasswordAsync(string accessToken, string newPassword)
    {
        await SendAsync(Build(HttpMethod.Put, "user",
            new { password = newPassword }, accessToken));
    }

    public async Task SignOutAsync(string accessToken)
    {
        try
        {
            await SendAsync(Build(HttpMethod.Post, "logout", null, accessToken));
        }
        catch (SupabaseException)
        {
            // Already signed out or expired: nothing to do
        }
    }

    // ---------- Helpers ----------

    private HttpRequestMessage Build(HttpMethod method, string path, object? body = null,
        string? userToken = null)
    {
        var req = new HttpRequestMessage(method, $"{_cfg.Url.TrimEnd('/')}/auth/v1/{path}");
        req.Headers.Add("apikey", _cfg.PublishableKey);
        if (userToken != null)
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", userToken);
        if (body != null)
            req.Content = JsonContent.Create(body);
        return req;
    }

    private async Task<JsonNode?> SendAsync(HttpRequestMessage req)
    {
        HttpResponseMessage res;
        try
        {
            res = await _http.SendAsync(req);
        }
        catch (HttpRequestException)
        {
            throw new SupabaseException("Could not reach the server. Check your internet connection.");
        }

        var text = await res.Content.ReadAsStringAsync();
        JsonNode? json = null;
        try
        {
            if (!string.IsNullOrWhiteSpace(text)) json = JsonNode.Parse(text);
        }
        catch (JsonException) { /* not JSON: keep null */ }

        if (!res.IsSuccessStatusCode)
        {
            var code = json?["error_code"]?.ToString();
            var message = json?["msg"]?.ToString()
                          ?? json?["error_description"]?.ToString()
                          ?? json?["message"]?.ToString()
                          ?? $"Supabase error ({(int)res.StatusCode})";
            throw new SupabaseException(Friendly(code, message), (int)res.StatusCode);
        }
        return json;
    }

    /// <summary>Turns Supabase error codes into messages staff understand.</summary>
    private static string Friendly(string? code, string message) => code switch
    {
        "invalid_credentials" => "Incorrect email or password.",
        "email_not_confirmed" => "Please confirm your email address first. Check your inbox.",
        "user_already_exists" or "email_exists" => "An account with this email already exists.",
        "weak_password" => "Password is too weak. Use at least 6 characters.",
        "over_request_rate_limit" or "over_email_send_rate_limit" =>
            "Too many attempts. Please wait a minute and try again.",
        "otp_expired" => "This code is wrong or has expired. Request a new one.",
        _ when message.Contains("Invalid login credentials", StringComparison.OrdinalIgnoreCase) =>
            "Incorrect email or password.",
        _ => message
    };

    private static AuthSession ToSession(JsonNode json) => new()
    {
        AccessToken = json["access_token"]?.ToString() ?? "",
        RefreshToken = json["refresh_token"]?.ToString() ?? "",
        ExpiresAt = json["expires_at"]?.GetValue<long>()
                    ?? DateTimeOffset.UtcNow.ToUnixTimeSeconds() + 3600,
        UserId = json["user"]?["id"]?.ToString() ?? "",
        Email = json["user"]?["email"]?.ToString() ?? ""
    };
}
