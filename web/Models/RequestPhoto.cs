namespace StudentStayFix.Web.Models;

/// <summary>Mirrors request_photo: one photo of a request.</summary>
public class RequestPhoto
{
    public long Id { get; set; }
    public long RequestId { get; set; }
    public string Path { get; set; } = "";
    public DateTimeOffset UploadedAt { get; set; }
}