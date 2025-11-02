using Godot;
using System.Text;
using Godot.Collections;

public static class PacketPacker
{
    public static byte[] PackData(Dictionary data, byte[] xorKey)
    {
        var json = Json.Stringify(data);
        var bytes = Encoding.UTF8.GetBytes(json);
        return Xor(bytes, xorKey);
    }

    public static Dictionary UnpackData(byte[] packet, byte[] xorKey)
    {
        var bytes = Xor(packet, xorKey);
        var json = Encoding.UTF8.GetString(bytes);
        var parse = Json.ParseString(json);
        if (parse.VariantType == Variant.Type.Nil)
            return new Dictionary();
        return (Dictionary)parse;
    }

    private static byte[] Xor(byte[] data, byte[] key)
    {
        var result = new byte[data.Length];
        for (int i = 0; i < data.Length; i++)
            result[i] = (byte)(data[i] ^ key[i % key.Length]);
        return result;
    }

    public static byte[] GenerateXorKey(string password, int keyLength = 8)
    {
        var bytes = Encoding.UTF8.GetBytes(password);
        var key = new byte[keyLength];
        for (int i = 0; i < keyLength; i++)
            key[i] = bytes[i % bytes.Length];
        return key;
    }
}