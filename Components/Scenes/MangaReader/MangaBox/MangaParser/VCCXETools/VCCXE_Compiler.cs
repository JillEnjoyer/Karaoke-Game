// VCCXE_Compiler.cs
using System;
using System.IO;
using System.Collections.Generic;
using System.Text;
using System.Security.Cryptography;

namespace VCCXE_Compiler {
    // Data types within the Data Block
    public enum AssetType : byte {
        LineartMesh = 0x01,
        ColorWebP = 0x02,
        AudioOpus = 0x03,
        ScriptJson = 0x04,
        Font = 0x05
    }

    // Base record in index entry (header)
    public struct IndexEntry {
        public uint Id;
        public AssetType Type;
        public long Offset;
        public uint Length;
    }

    public class VCCXPacker {
        private string _outputPath;
        private List<IndexEntry> _entries = new List<IndexEntry>();
        private MemoryStream _indexStream = new MemoryStream();
        
        // Header constants (TODO: Change to not visible solution for reverse engineering)
        private const uint MAGIC = 0x56434358; // "VCCX"
        private const ushort VERSION = 0x0001;

        public void CreatePackage(string path, byte[] authorSteamIdHash, byte[] globalKey) {
            _outputPath = path;
            
            using (FileStream fs = new FileStream(_outputPath, FileMode.Create))
            using (BinaryWriter writer = new BinaryWriter(fs)) {
                
                // Header (will be filled later, reserve 256 bytes)
                writer.Write(new byte[256]);

                // CONTENT BLOB
                long currentOffset = 256;

                // AddAsset(writer, pageMeshBytes, AssetType.LineartMesh, ref currentOffset);
                // AddAsset(writer, colorBytes, AssetType.ColorWebP, ref currentOffset);

                long indexOffset = currentOffset;
                //WriteIndexToStream();
                byte[] encryptedIndex = EncryptBlock(_indexStream.ToArray(), globalKey);
                uint indexLength = (uint)encryptedIndex.Length;
                writer.Write(encryptedIndex);

                fs.Seek(0, SeekOrigin.Begin);
                writer.Write(MAGIC);
                writer.Write(VERSION);
                writer.Write((byte)0x00); // STATE: Factory
                writer.Write((byte)0x00); // FLAGS
                writer.Write(authorSteamIdHash); // 32 bytes
                
                fs.Seek(0x28, SeekOrigin.Begin);
                writer.Write(new byte[32]); 

                fs.Seek(0x48, SeekOrigin.Begin);
                byte[] salt = null;//GenerateRandomBytes(16);
                writer.Write(salt);
                
                fs.Seek(0x80, SeekOrigin.Begin); 
                writer.Write(indexOffset);
                writer.Write(indexLength);
            }

            //ComputeAndWriteFinalHash(_outputPath);
        }

        private void AddAsset(BinaryWriter writer, byte[] data, AssetType type, uint id, byte[] key, ref long offset) {
            byte[] encryptedData = EncryptBlock(data, key);
            var entry = new IndexEntry {
                Id = id,
                Type = type,
                Offset = offset,
                Length = (uint)encryptedData.Length
            };
            _entries.Add(entry);
            
            writer.Write(encryptedData);
            offset += encryptedData.Length;
        }

        private byte[] EncryptBlock(byte[] data, byte[] key) {
            using (Aes aes = Aes.Create()) {
                aes.Key = key;
                aes.Mode = CipherMode.ECB;
                aes.Padding = PaddingMode.PKCS7;
                return aes.CreateEncryptor().TransformFinalBlock(data, 0, data.Length);
            }
        }
    }
}