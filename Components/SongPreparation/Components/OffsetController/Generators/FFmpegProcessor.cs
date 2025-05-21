using Godot;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;

public partial class FFmpegProcessor : Node
{
	public byte[] ProcessWithFFmpeg(string inputPath, string ffmpegPath, int size_x, int size_y, string color)
	{
		ProcessStartInfo startInfo = new ProcessStartInfo
		{
			FileName = ffmpegPath,
			Arguments = $"-i \"{inputPath}\" -filter_complex showwavespic=s={size_x}x{size_y}:colors={color} -frames:v 1 -f image2pipe -vcodec png pipe:1",
			RedirectStandardOutput = true,
			RedirectStandardError = true,
			UseShellExecute = false,
			CreateNoWindow = true
		};

		using (Process process = new Process { StartInfo = startInfo })
		{
			try
			{
				process.Start();

				// MemoryStream async
				using (MemoryStream memoryStream = new MemoryStream())
				{
					// Output reading in different task
					Task copyTask = process.StandardOutput.BaseStream.CopyToAsync(memoryStream);

					// Waiting for FFmpeg exit signal (but no more than 10 secs)
					bool exited = process.WaitForExit(10000);
					if (!exited)
					{
						process.Kill(); // Terminate, if stuck
						GD.PrintErr("FFmpeg timeout exceeded, process killed.");
						return null;
					}

					// Wait for end of data copying
					copyTask.Wait(5000);

					if (process.ExitCode != 0)
					{
						string errorOutput = process.StandardError.ReadToEnd();
						GD.PrintErr($"FFmpeg failed (exit code {process.ExitCode}): {errorOutput}");
						return null;
					}

					byte[] bytes = memoryStream.ToArray();
					if (bytes.Length < 8 || !IsValidPng(bytes))
					{
						GD.PrintErr("FFmpeg did not return valid PNG data.");
						return null;
					}

					return bytes;
				}
			}
			catch (Exception ex)
			{
				GD.PrintErr($"FFmpeg processing error: {ex.Message}");
				return null;
			}
		}
	}

	private bool IsValidPng(byte[] bytes)
	{
		return bytes.Length >= 8 &&
			   bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E &&
			   bytes[3] == 0x47 && bytes[4] == 0x0D && bytes[5] == 0x0A &&
			   bytes[6] == 0x1A && bytes[7] == 0x0A;
	}
}
