namespace StudentStayFix.Web.Services;

/// <summary>
/// A Supabase error with a message that is safe to show to the user.
/// </summary>
public class SupabaseException : Exception
{
    public int StatusCode { get; }

    public SupabaseException(string message, int statusCode = 0) : base(message)
    {
        StatusCode = statusCode;
    }
}
