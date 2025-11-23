using Godot;
using System;

public partial class MicAnalyzer : Node
{
	// RMS calculating method using short
	private float ComputeRMS(short[] samples)
	{
		double sumSquares = 0;
		foreach (var s in samples)
		{
			double val = s / (double)short.MaxValue; // normalize into [-1,1]
			sumSquares += val * val;
		}
		return (float)Math.Sqrt(sumSquares / samples.Length);
	}

	// Basic method: Takes two arrays and threshold, returns bool
	public bool CompareSamples(Godot.Collections.Array micBuffer, Godot.Collections.Array songBuffer, float threshold)
	{
		if (micBuffer.Count != songBuffer.Count)
		{
			GD.PrintErr("Buffers length mismatch!");
			return false;
		}

		short[] micSamples = new short[micBuffer.Count];
		short[] songSamples = new short[songBuffer.Count];

		for (int i = 0; i < micBuffer.Count; i++)
		{
			micSamples[i] = (short)((float)micBuffer[i] * short.MaxValue);
			songSamples[i] = (short)((float)songBuffer[i] * short.MaxValue);
		}

		float rmsMic = ComputeRMS(micSamples);
		float rmsSong = ComputeRMS(songSamples);

		float diff = Math.Abs(rmsMic - rmsSong);

		return diff <= threshold;
	}
}
