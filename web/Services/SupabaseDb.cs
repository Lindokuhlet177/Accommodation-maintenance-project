using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Options;

namespace StudentStayFix.Web.Services;

/// <summary>
/// Reads/writes Supabase tables, calls database functions and makes photo links.
/// Every call uses the logged-in staff member's token, so Row Level Security applies.
/// </summary>
public class SupabaseDb
{
    private readonly HttpClient _http;
    private readonly SupabaseSettings _cfg;
    private readonly IHttpContextAccessor _ctx;

    /// <summary>C# PascalCase  <->  database snake_case (RoomNumber <-> room_number).</summary>
    public static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        PropertyNameCaseInsensitive = true,
        NumberHandling = JsonNumberHandling.AllowReadingFromString
    };

    public SupabaseDb(HttpClient http, IOptions<SupabaseSettings> cfg, IHttpContextAccessor ctx)
    {
        _http = http;
        _cfg = cfg.Value;
        _ctx = ctx;
    }

    // ---------- Tables ----------

    /// <summary>GET rows, e.g. "room?select=*&amp;accommodation_id=eq.3&amp;order=room_number.asc"</summary>
    public async Task<List<T>> GetAsync<T>(string query, string? token = null)
    {
        var text = await SendAsync(Build(HttpMethod.Get, $"rest/v1/{query}", null, token));
        return JsonSerializer.Deserialize<List<T>>(text, Json) ?? [];
    }

    /// <summary>GET the first matching row, or null.</summary>
    public async Task<T?> GetOneAsync<T>(string query, string? token = null)
    {
        var sep = query.Contains('?') ? "&" : "?";
        var rows = await GetAsync<T>($"{query}{sep}limit=1", token);
        return rows.FirstOrDefault();
    }

    /// <summary>INSERT a row and return it (with its new id).</summary>
    public async Task<T> InsertAsync<T>(string table, object row)
    {
        var req = Build(HttpMethod.Post, $"rest/v1/{table}", row);
        req.Headers.Add("Prefer", "return=representation");
        var text = await SendAsync(req);
        var rows = JsonSerializer.Deserialize<List<T>>(text, Json) ?? [];
        return rows.Count > 0 ? rows[0] : throw new SupabaseException("Nothing was saved.");
    }

    /// <summary>UPDATE rows, e.g. UpdateAsync("room", "id=eq.5", new { floor = 2 })</summary>
    public async Task UpdateAsync(string table, string filter, object changes)
    {
        var req = Build(HttpMethod.Patch, $"rest/v1/{table}?{filter}", changes);
        req.Headers.Add("Prefer", "return=minimal");
        await SendAsync(req);
    }

    /// <summary>DELETE rows, e.g. DeleteAsync("upcoming_task", "id=eq.7")</summary>
    public async Task DeleteAsync(string table, string filter)
    {
        await SendAsync(Build(HttpMethod.Delete, $"rest/v1/{table}?{filter}"));
    }

    // ---------- Database functions (Steps W1 / W1c) ----------

    /// <summary>Calls a function that returns nothing, e.g. staff_update_request.</summary>
    public async Task RpcAsync(string function, object? args = null)
    {
        await SendAsync(Build(HttpMethod.Post, $"rest/v1/rpc/{function}", args ?? new { }));
    }

    /// <summary>Calls a function that returns data, e.g. public_accommodations.</summary>
    public async Task<T?> RpcAsync<T>(string function, object? args = null)
    {
        var text = await SendAsync(Build(HttpMethod.Post, $"rest/v1/rpc/{function}", args ?? new { }));
        return string.IsNullOrWhiteSpace(text) ? default : JsonSerializer.Deserialize<T>(text, Json);
    }

    // ---------- Photos (private bucket) ----------

    /// <summary>
    /// Temporary links (1 hour) for request photos. Returns path -> link.
    /// Works only for photos the staff member may see (storage policy, Step W1).
    /// </summary>
    public async Task<Dictionary<string, string>> SignedPhotoUrlsAsync(IEnumerable<string> paths)
    {



        var list = paths.Where(p => !string.IsNullOrWhiteSpace(p)).Distinct().ToList();
        if (list.Count == 0) return [];
        // The storage API expects camelCase names. A Dictionary keeps its keys
        // exactly as written (the snake_case rule only renames class properties).
        var body = new Dictionary<string, object>
        {
            ["expiresIn"] = 3600,   // 1 hour
            ["paths"] = list
        };

        var text = await SendAsync(Build(HttpMethod.Post,
            $"storage/v1/object/sign/{_cfg.PhotoBucket}", body));

        var result = new Dictionary<string, string>();
        foreach (var item in JsonNode.Parse(text)?.AsArray() ?? [])
        {
            var path = item?["path"]?.ToString();
            var signed = item?["signedURL"]?.ToString();
            if (path != null && !string.IsNullOrEmpty(signed))
                result[path] = $"{_cfg.Url.TrimEnd('/')}/storage/v1{signed}";
        }
        return result;
    }

    // ---------- Staff profile photos (public bucket, Step P1) ----------

    public const string AvatarBucket = "staff-avatars";

    /// <summary>Public link to a profile photo (null if there is none).</summary>
    public string? AvatarUrl(string? path) =>
        string.IsNullOrWhiteSpace(path)
            ? null
            : $"{_cfg.Url.TrimEnd('/')}/storage/v1/object/public/{AvatarBucket}/{path}";

    /// <summary>Uploads a photo into the logged-in staff member's own folder.</summary>
    public async Task UploadAvatarAsync(string path, byte[] bytes, string contentType)
    {
        var req = new HttpRequestMessage(HttpMethod.Post,
            $"{_cfg.Url.TrimEnd('/')}/storage/v1/object/{AvatarBucket}/{path}");
        req.Headers.Add("apikey", _cfg.PublishableKey);
        if (CurrentUserToken is string token)
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        req.Content = new ByteArrayContent(bytes);
        req.Content.Headers.ContentType = new MediaTypeHeaderValue(contentType);
        await SendAsync(req);
    }

    /// <summary>Deletes an old photo (errors are ignored: it's only tidying up).</summary>
    public async Task DeleteAvatarAsync(string? path)
    {
        if (string.IsNullOrWhiteSpace(path)) return;
        try
        {
            var body = new Dictionary<string, object> { ["prefixes"] = new[] { path } };
            await SendAsync(Build(HttpMethod.Delete, $"storage/v1/object/{AvatarBucket}", body));
        }
        catch (SupabaseException) { }
    }

    // ---------- Small helpers for building filters ----------

    /// <summary>"in.(1,2,3)" for a list of ids.</summary>
    public static string In(IEnumerable<long> ids) => $"in.({string.Join(",", ids)})";

    /// <summary>Makes text safe to put in a URL.</summary>
    public static string Enc(string value) => Uri.EscapeDataString(value);

    // ---------- Request plumbing ----------

    private string? CurrentUserToken =>
        _ctx.HttpContext?.User.FindFirst(AppClaims.AccessToken)?.Value;

    private HttpRequestMessage Build(HttpMethod method, string path, object? body = null,
        string? token = null)
    {
        var req = new HttpRequestMessage(method, $"{_cfg.Url.TrimEnd('/')}/{path}");
        req.Headers.Add("apikey", _cfg.PublishableKey);

        token ??= CurrentUserToken;   // logged-in staff member (null before login)
        if (!string.IsNullOrEmpty(token))
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        if (body != null)
            req.Content = new StringContent(JsonSerializer.Serialize(body, Json),
                Encoding.UTF8, "application/json");
        return req;
    }

    private async Task<string> SendAsync(HttpRequestMessage req)
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
        if (res.IsSuccessStatusCode) return text;

        if ((int)res.StatusCode == 401)
            throw new SupabaseException("Your session has expired. Please sign in again.", 401);

        // Our SQL functions raise friendly messages, e.g. "This room is already full"
        string message = $"Something went wrong ({(int)res.StatusCode}).";
        try
        {
            message = JsonNode.Parse(text)?["message"]?.ToString() ?? message;
        }
        catch (JsonException) { /* not JSON */ }

        if (message.Contains("duplicate key", StringComparison.OrdinalIgnoreCase))
            message = "That record already exists.";

        throw new SupabaseException(message, (int)res.StatusCode);
    }
}