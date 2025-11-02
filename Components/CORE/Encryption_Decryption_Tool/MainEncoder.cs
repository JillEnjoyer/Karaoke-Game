using Godot;
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public partial class MainEncoder : Node
{
    // Get key (32 bytes) from steamId
    private static byte[] GetKey(string steamId)
    {
        using var sha = SHA256.Create();
        return sha.ComputeHash(Encoding.UTF8.GetBytes(steamId));
    }

    // Random IV (16 bytes) for AES
    private static byte[] GenerateIV()
    {
        using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
        byte[] iv = new byte[16];
        rng.GetBytes(iv);
        return iv;
    }

    public static bool EncryptFile(string inputPath, string outputPath, string steamId)
    {
        byte[] key = GetKey(steamId);
        byte[] iv = GenerateIV();
        byte[] steamIdHash = key;

        if (!outputPath.EndsWith(".vlzip", StringComparison.OrdinalIgnoreCase))
            outputPath += ".vlzip";

        using var aes = Aes.Create();
        aes.Key = key;
        aes.IV = iv;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;

        using var input = File.OpenRead(inputPath);
        using var output = File.OpenWrite(outputPath);

        output.Write(iv, 0, iv.Length);
        output.Write(steamIdHash, 0, steamIdHash.Length);

        using var cryptoStream = new CryptoStream(output, aes.CreateEncryptor(), CryptoStreamMode.Write);
        input.CopyTo(cryptoStream);

        return true;
    }

    public static byte[] DecryptFileToMemory(string inputPath, string steamId)
    {
        byte[] key = GetKey(steamId);

        using var input = File.OpenRead(inputPath);

        byte[] iv = new byte[16];
        input.Read(iv, 0, iv.Length);

        byte[] fileSteamIdHash = new byte[32];
        input.Read(fileSteamIdHash, 0, fileSteamIdHash.Length);

        byte[] expectedHash = key;
        if (!fileSteamIdHash.AsSpan().SequenceEqual(expectedHash))
            return null;

        using var aes = Aes.Create();
        aes.Key = key;
        aes.IV = iv;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;

        try
        {
            using var cryptoStream = new CryptoStream(input, aes.CreateDecryptor(), CryptoStreamMode.Read);
            using var ms = new MemoryStream();
            cryptoStream.CopyTo(ms);
            return ms.ToArray();
        }
        catch (CryptographicException)
        {
            return null;
        }
    }

    public static bool DecryptFile(string inputPath, string steamId)
    {
        byte[] key = GetKey(steamId);

        using var input = File.OpenRead(inputPath);

        byte[] iv = new byte[16];
        input.Read(iv, 0, iv.Length);

        byte[] fileSteamIdHash = new byte[32];
        input.Read(fileSteamIdHash, 0, fileSteamIdHash.Length);

        byte[] expectedHash = key;
        if (!fileSteamIdHash.AsSpan().SequenceEqual(expectedHash))
            return false;

        string outputPath = inputPath.EndsWith(".vlzip", StringComparison.OrdinalIgnoreCase)
            ? Path.Combine(Path.GetDirectoryName(inputPath) ?? "", Path.GetFileNameWithoutExtension(inputPath))
            : inputPath + ".decrypted";

        using var aes = Aes.Create();
        aes.Key = key;
        aes.IV = iv;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;

        try
        {
            using var cryptoStream = new CryptoStream(input, aes.CreateDecryptor(), CryptoStreamMode.Read);
            using var output = File.OpenWrite(outputPath);
            cryptoStream.CopyTo(output);
            return true;
        }
        catch (CryptographicException)
        {
            return false;
        }
    }
}