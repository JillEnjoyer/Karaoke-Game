using Godot;
using System;
using System.Threading;
using System.Threading.Tasks;
using Open.Nat;

public partial class NatManager : Node, IDisposable
{
    private NatDiscoverer nat;
    private NatDevice device;
    private Mapping tcpMapping;
    private Mapping udpMapping;
    private bool portsMapped = false;

    public async Task<bool> MapPorts(int tcpPort, int udpPort)
    {
        try
        {
            nat = new NatDiscoverer();
            var cts = new CancellationTokenSource(5000);
            device = await nat.DiscoverDeviceAsync(PortMapper.Upnp, cts);

            tcpMapping = new Mapping(Protocol.Tcp, tcpPort, tcpPort, "GodotHostTCP");
            udpMapping = new Mapping(Protocol.Udp, udpPort, udpPort, "GodotHostUDP");

            await device.CreatePortMapAsync(tcpMapping);
            await device.CreatePortMapAsync(udpMapping);

            portsMapped = true;
            GD.Print($"Ports were forwarded: TCP {tcpPort}, UDP {udpPort}");
            return true;
        }
        catch (Exception e)
        {
            GD.Print($"Unable to automatically forward ports: {e.Message}");
            portsMapped = false;
            return false;
        }
    }

    public async Task<bool> UnmapPorts()
    {
        if (!portsMapped || device == null)
            return false;

        try
        {
            if (tcpMapping != null)
                await device.DeletePortMapAsync(tcpMapping);
            if (udpMapping != null)
                await device.DeletePortMapAsync(udpMapping);

            GD.Print("Ports were unmapped.");
            portsMapped = false;
            return true;
        }
        catch (Exception e)
        {
            GD.Print($"Unable to unmap ports: {e.Message}");
            return false;
        }
    }

    public async void DisposePorts()
    {
        await UnmapPorts();
    }

    public override void _ExitTree()
    {
        DisposePorts();
    }
}