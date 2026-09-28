# Pakistan Mobile Signal Tracker (Bash)

**Coded by Cyber Security Engineer Mr Sabaz Ali Khan**

A local Bash utility for monitoring the signal quality and internet health of a device/network you own or are authorized to test. It is suitable for Pakistan mobile-data users but does not depend on a specific Pakistani carrier.

## Features

- Mobile carrier/operator name when the OS exposes it
- Mobile technology (for example LTE/5G when available)
- Mobile signal reading via Termux:API on Android or ModemManager on Linux
- Wi-Fi SSID and signal quality
- Active network interface and local IPv4 address
- Ping latency and packet-loss test
- Live terminal dashboard
- Continuous CSV logging
- Text summary reports
- Dependency checker

## Privacy / scope

This project intentionally does **not** collect GPS coordinates, Cell ID/TAC, IMSI, phone numbers, SMS, call contents, passwords, or another person's device information. It monitors the local device/network where you run it.

## Termux / Android setup

1. Install Termux from a trusted Termux distribution source.
2. Install the matching **Termux:API** Android companion app.
3. Open Termux and run:

```bash
chmod +x install.sh signal_tracker.sh
./install.sh
```

4. Grant the Termux:API app the required Phone/Wi-Fi permissions when Android asks.
5. Check support:

```bash
./signal_tracker.sh --check
```

6. Run one scan:

```bash
./signal_tracker.sh --scan
```

7. Start live mode:

```bash
./signal_tracker.sh --live 10
```

8. Log a sample every 10 seconds:

```bash
./signal_tracker.sh --log 10
```

## Kali / Ubuntu / Debian setup

```bash
chmod +x install.sh signal_tracker.sh
./install.sh
./signal_tracker.sh --check
./signal_tracker.sh --scan
```

For cellular signal data on Linux, the mobile modem should be visible to `ModemManager` (`mmcli`). For Wi-Fi signal data, NetworkManager (`nmcli`) is supported.

## Main menu

Run without arguments:

```bash
./signal_tracker.sh
```

## Output

- CSV logs: `logs/signal_log_YYYY-MM-DD.csv`
- Reports: `reports/summary_YYYYMMDD_HHMMSS.txt`

## Signal interpretation

For dBm readings, values closer to zero are stronger. As a practical approximation:

- `-85 dBm` or better: Excellent
- `-86` to `-95 dBm`: Good
- `-96` to `-105 dBm`: Fair
- `-106` to `-115 dBm`: Weak
- Below `-115 dBm`: Very weak

Actual experience also depends on congestion, radio band, network technology, routing, packet loss, and the carrier network.
