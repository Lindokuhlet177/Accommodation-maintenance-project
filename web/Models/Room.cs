namespace StudentStayFix.Web.Models;

/// <summary>Mirrors the room table.</summary>
public class Room
{
    public long Id { get; set; }
    public long AccommodationId { get; set; }
    public string RoomNumber { get; set; } = "";
    public int Floor { get; set; }
    public string RoomType { get; set; } = "Single";
    public int Capacity { get; set; } = 1;

    public string FloorText => $"Floor {Floor}";
}
