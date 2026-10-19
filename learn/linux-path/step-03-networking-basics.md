# Step 3: Networking Basics

> **Time:** ~8-10 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 2](step-02-user-and-group-mgmnt.md) · **Next:** [Step 4: Shell Scripting](step-04-shell-scripting.md)

<!-- -->

> [!WARNING]
> Do this in a throwaway VM or the devcontainer, never on a machine you cannot afford to lose.
> Keep a second SSH session open while changing SSH or firewall settings. Network changes over
> SSH can cut off your own connection. Prefer a VM console, or use the **network namespace labs**
> in this step (`ip netns`), which build a whole network inside one machine and cannot break your
> real connection.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).
Tasks 3.3-3.6 and 3.9 were run in a privileged Ubuntu 24.04 container using network namespaces.
Addresses `192.0.2.0/24` and `203.0.113.0/24` are reserved for documentation, so they are safe to use in labs.

## Legacy tools you will still meet

| Old | Modern | Note |
|-----|--------|------|
| `ifconfig`, `route`, `netstat` | `ip addr`, `ip route`, `ss` | `net-tools` is not installed by default |
| `iptables` | `nftables` (`nft`) | `iptables` on current distros is often a wrapper over nftables |
| `/etc/network/interfaces` | Netplan (Ubuntu), NetworkManager (RHEL, Fedora, desktops), systemd-networkd | Pick the one your distro uses |
| `isc-dhcp-server` | `dnsmasq`, Kea | ISC DHCP reached end of life in 2022 |
| `nslookup` | `dig`, `resolvectl query` | |

---

## Beginner

### Task 3.1: View and configure interfaces

- **What you will learn:** read interface state with `ip`, add a temporary address, then make it persistent with the right tool for your distro.
- **Target distro:** both. Persistence differs: **Ubuntu** uses Netplan, **RHEL family** uses NetworkManager (`nmcli`), minimal **Debian** uses `/etc/network/interfaces` or systemd-networkd.
- **Risk level:** `safe` with a dummy interface (below); `can lock you out` if you change the address of the interface you are connected over.

> [!WARNING]
> Never edit the persistent config of your SSH interface without a console. Netplan has a safety
> net: `sudo netplan try` reverts after 120 s unless you confirm.

Temporary, using a dummy interface so nothing real changes:

```bash
ip -br link show
sudo ip link add lab0 type dummy
sudo ip addr add 192.0.2.10/24 dev lab0
sudo ip link set lab0 up
ip -br addr show lab0
ip route show dev lab0
```

**Verify it worked**

**Expected output:**

```text
lab0             UNKNOWN        192.0.2.10/24 fe80::7ca1:4eff:fe55:4e16/64 
192.0.2.0/24 proto kernel scope link src 192.0.2.10 
```

(`UNKNOWN` is normal for a dummy device. The IPv6 link-local address will differ.)

Persistent static IP on a real interface (replace `enp1s0`, addresses and gateway; *typical,
not applied here*):

```bash
# Ubuntu: /etc/netplan/60-static.yaml, mode 600
sudo tee /etc/netplan/60-static.yaml >/dev/null <<'EOF'
network:
  version: 2
  ethernets:
    enp1s0:
      addresses: [192.168.1.50/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 9.9.9.9]
EOF
sudo chmod 600 /etc/netplan/60-static.yaml
sudo netplan try          # confirms or rolls back automatically
```

```bash
# RHEL family / Fedora (NetworkManager)
nmcli -p connection show
sudo nmcli connection modify "System enp1s0" ipv4.method manual \
  ipv4.addresses 192.168.1.50/24 ipv4.gateway 192.168.1.1 ipv4.dns "1.1.1.1 9.9.9.9"
sudo nmcli connection up "System enp1s0"
```

**Acceptance criteria**

- [ ] You can read an address, a route and a link state from `ip` output.
- [ ] A dummy interface has your documentation address.
- [ ] You can name the tool that owns persistent config on your distro.

**Undo it**

```bash
sudo ip link del lab0            # removes the address and route with it
# Netplan: delete the file and run: sudo netplan apply
```

**Troubleshooting**

- Address vanishes after reboot: you used `ip addr add` only. That is runtime state.
- `Error: ipv4: Address already assigned` / `RTNETLINK answers: File exists`: the address is already on the device.
- Netplan: `Invalid YAML` or tabs: use spaces only, and check with `sudo netplan generate`.

### Task 3.2: Everyday network tools

- **What you will learn:** test reachability (`ping`), path (`traceroute`/`tracepath`), DNS (`dig`, `resolvectl`), and listening sockets (`ss`).
- **Target distro:** both. Packages: `iputils-ping dnsutils traceroute` (Debian/Ubuntu); `iputils bind-utils traceroute` (RHEL).
- **Risk level:** `safe`.

```bash
ping -c 2 1.1.1.1
dig +short example.com A
dig -x 1.1.1.1 +short
traceroute -n -m 3 1.1.1.1
ss -tulpn | head
resolvectl status | head -5       # systemd-resolved systems only
```

**Verify it worked**

**Expected output** (addresses and hop times vary with your network):

```text
--- 1.1.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 24.511/25.900/27.289/1.389 ms
172.66.147.243
104.20.23.154
one.one.one.one.
traceroute to 1.1.1.1 (1.1.1.1), 3 hops max, 60 byte packets
 1  172.17.0.1  0.099 ms  0.012 ms  0.009 ms
```

**Acceptance criteria**

- [ ] You can tell a DNS failure (`ping 1.1.1.1` works, `ping example.com` does not) from a routing failure.
- [ ] You can list which process listens on which port with `ss -tulpn`.

**Undo it:** nothing to undo (read-only).

**Troubleshooting**

- `ping: socket: Operation not permitted` in containers: add the capability `NET_RAW` or run as root.
- `dig: command not found`: install `dnsutils` / `bind-utils`.
- `traceroute` shows `* * *`: routers drop the probes. Try `traceroute -T -p 443` (TCP) or `tracepath`.

### Task 3.3: A firewall with nftables (and ufw / firewalld)

- **What you will learn:** a default-deny inbound policy, allow-listing SSH, blocking one address, and persisting the rules. `nftables` is the kernel's packet filter; `ufw` (Ubuntu) and `firewalld` (RHEL) are friendlier front-ends to it. Do not run two front-ends at once.
- **Target distro:** both. Install: `sudo apt install -y nftables` / `sudo dnf install -y nftables`.
- **Risk level:** `can lock you out`.

> [!WARNING]
> A default-deny policy without an SSH rule disconnects you. Test inside a network namespace first
> (below), keep a console or second SSH session open, and use the "dead man's switch" at the end.

**Safe test inside a namespace** (does not touch your real firewall):

```bash
sudo ip netns add fw
sudo ip netns exec fw nft -f - <<'EOF'
flush ruleset
table inet filter {
  set blocked { type ipv4_addr; elements = { 203.0.113.50 } }
  chain input {
    type filter hook input priority 0; policy drop;
    iif lo accept
    ct state established,related accept
    ct state invalid drop
    ip saddr @blocked drop
    ip protocol icmp accept
    tcp dport 22 accept
  }
}
EOF
sudo ip netns exec fw nft list ruleset
```

**Verify it worked**

**Expected output:**

```text
table inet filter {
 set blocked {
  type ipv4_addr
  elements = { 203.0.113.50 }
 }

 chain input {
  type filter hook input priority filter; policy drop;
  iif "lo" accept
  ct state established,related accept
  ct state invalid drop
  ip saddr @blocked drop
  ip protocol icmp accept
  tcp dport 22 accept
 }
}
```

**On the real host** save the same ruleset to the file the distro loads at boot, check syntax first:

```bash
sudo tee /etc/nftables.conf >/dev/null <<'EOF'
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    iif lo accept
    ct state established,related accept
    ct state invalid drop
    ip protocol icmp accept
    ip6 nexthdr icmpv6 accept
    tcp dport 22 accept
  }
  chain forward { type filter hook forward priority 0; policy drop; }
  chain output  { type filter hook output  priority 0; policy accept; }
}
EOF
sudo nft -c -f /etc/nftables.conf && echo "syntax ok"
# dead man's switch: flush the rules in 2 minutes unless you cancel this job
sudo systemd-run --on-active=120 --unit=fw-rollback nft flush ruleset
sudo nft -f /etc/nftables.conf
# if you can still log in from a NEW session, cancel the rollback and enable at boot:
sudo systemctl stop fw-rollback.timer
sudo systemctl enable --now nftables
```

Same policy with the front-ends:

```bash
# Ubuntu: ufw
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp && sudo ufw deny from 203.0.113.50 && sudo ufw enable && sudo ufw status verbose

# RHEL family: firewalld
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="203.0.113.50" drop'
sudo firewall-cmd --reload && sudo firewall-cmd --list-all
```

`ufw` and `firewalld` output was *not captured* here (they need real root on a full system).

**Acceptance criteria**

- [ ] `nft list ruleset` shows policy `drop` on `input` with an SSH accept rule.
- [ ] A new SSH session still connects after loading the rules.
- [ ] The rules are present after a reboot.

**Undo it**

```bash
sudo nft flush ruleset
sudo systemctl disable --now nftables
sudo ip netns del fw
# ufw: sudo ufw disable      firewalld: remove the rich rule with --remove-rich-rule
```

**Troubleshooting**

- Locked out: use the console; `sudo nft flush ruleset` restores access. Your dead man's switch does this.
- `Error: syntax error, unexpected ...` : run `nft -c -f file` to see the line; `inet` tables cover IPv4 and IPv6.
- Rules gone after reboot: `nftables.service` is not enabled, or `ufw`/`firewalld` is overwriting them. Use one manager only.

---

## Intermediate

### Task 3.4: A DHCP server with dnsmasq

- **What you will learn:** scopes (range, mask, lease time), options (router, DNS), and testing a lease. ISC `dhcpd` is end-of-life; **dnsmasq** (small networks, also does DNS) or **Kea** (large) replace it.
- **Target distro:** both (`sudo apt install -y dnsmasq` / `sudo dnf install -y dnsmasq`).
- **Risk level:** `can lock you out` of the network. A second DHCP server on a LAN hands out wrong leases to everyone. **Only run this on an isolated lab network or in the namespace below.**

Namespace lab (a server and a client joined by a virtual cable):

```bash
sudo ip netns add dhcpsrv; sudo ip netns add dhcpcli
sudo ip link add s0 type veth peer name c0
sudo ip link set s0 netns dhcpsrv; sudo ip link set c0 netns dhcpcli
sudo ip -n dhcpsrv addr add 192.168.50.1/24 dev s0
sudo ip -n dhcpsrv link set s0 up; sudo ip -n dhcpsrv link set lo up
sudo ip -n dhcpcli link set c0 up

cat > /tmp/dnsmasq-lab.conf <<'EOF'
interface=s0
bind-interfaces
port=0
dhcp-range=192.168.50.100,192.168.50.150,255.255.255.0,12h
dhcp-option=option:router,192.168.50.1
dhcp-option=option:dns-server,192.168.50.1
dhcp-leasefile=/tmp/dnsmasq.leases
EOF
dnsmasq --test -C /tmp/dnsmasq-lab.conf
sudo ip netns exec dhcpsrv dnsmasq -C /tmp/dnsmasq-lab.conf --pid-file=/tmp/dm.pid
sudo ip netns exec dhcpcli dhclient -1 -v c0
ip -n dhcpcli -br addr show c0
```

(`port=0` turns off dnsmasq's DNS part; remove it to also serve DNS.)

**Verify it worked**

**Expected output:**

```text
dnsmasq: syntax check OK.
DHCPDISCOVER on c0 to 255.255.255.255 port 67 interval 3 (xid=0x1fff7a39)
DHCPOFFER of 192.168.50.110 from 192.168.50.1
DHCPREQUEST for 192.168.50.110 on c0 to 255.255.255.255 port 67 (xid=0x397aff1f)
DHCPACK of 192.168.50.110 from 192.168.50.1 (xid=0x1fff7a39)
bound to 192.168.50.110 -- renewal in 18957 seconds.
c0@if8           UP             192.168.50.110/24 fe80::9ca0:51ff:fe2e:cff3/64 
```

On a real lab VM, add `dhcp-host=aa:bb:cc:dd:ee:ff,192.168.50.20` for a reserved address and read
leases from `/var/lib/misc/dnsmasq.leases`. Open the firewall for UDP 67 (`ufw allow 67/udp`, `firewall-cmd --add-service=dhcp`).

**Acceptance criteria**

- [ ] The client gets an address in the configured range, with the router and DNS options.
- [ ] You can state the lease time and where leases are stored.

**Undo it**

```bash
sudo kill "$(cat /tmp/dm.pid)"
sudo ip netns del dhcpsrv; sudo ip netns del dhcpcli
rm -f /tmp/dnsmasq-lab.conf /tmp/dnsmasq.leases
```

**Troubleshooting**

- `dnsmasq: failed to bind DHCP server socket: Address already in use`: another DHCP server or `systemd-resolved`/NetworkManager's dnsmasq is running; use `bind-interfaces` and a specific `interface=`.
- Client times out: the server interface is down, or a firewall blocks UDP 67/68.
- Clients get an address but no DNS: the `dns-server` option is missing, or `port=0` and nothing else serves DNS.

### Task 3.5: A local DNS server with BIND9

- **What you will learn:** a caching and forwarding resolver, an authoritative zone for your lab domain, and checking with `named-checkconf`/`named-checkzone`/`dig`.
- **Target distro:** Debian/Ubuntu package `bind9`, service `named` (alias `bind9`), config in `/etc/bind/`. RHEL: package `bind`, service `named`, config in `/etc/named.conf` and `/var/named/`.
- **Risk level:** `can lock you out` of name resolution if you point the system's resolver at a server that is not working. Test with `dig @127.0.0.1` and do not change `/etc/resolv.conf` until it answers.

```bash
sudo apt install -y bind9 bind9-utils dnsutils       # RHEL: sudo dnf install -y bind bind-utils
sudo mkdir -p /etc/bind/zones

sudo tee /etc/bind/named.conf.options >/dev/null <<'EOF'
options {
  directory "/var/cache/bind";
  listen-on { 127.0.0.1; };
  listen-on-v6 { none; };
  allow-query { localhost; 192.168.0.0/16; };
  allow-recursion { localhost; 192.168.0.0/16; };
  recursion yes;
  forwarders { 1.1.1.1; 9.9.9.9; };
  dnssec-validation auto;
};
EOF
sudo tee /etc/bind/named.conf.local >/dev/null <<'EOF'
zone "lab.example" {
  type primary;
  file "/etc/bind/zones/db.lab.example";
};
EOF
sudo tee /etc/bind/zones/db.lab.example >/dev/null <<'EOF'
$TTL 1h
@   IN SOA ns1.lab.example. admin.lab.example. ( 2026101701 1h 15m 1w 1h )
    IN NS  ns1.lab.example.
ns1 IN A   192.168.50.1
web IN A   192.168.50.20
www IN CNAME web
EOF
sudo named-checkconf && sudo named-checkzone lab.example /etc/bind/zones/db.lab.example
sudo chown -R bind:bind /etc/bind/zones
sudo systemctl restart named
```

(`allow-recursion` limits recursion to your network: an open resolver gets abused for DDoS amplification. Increment the zone serial on every change.)

**Verify it worked**

```bash
dig @127.0.0.1 web.lab.example +short
dig @127.0.0.1 www.lab.example +noall +answer
dig @127.0.0.1 example.com +short
dig @127.0.0.1 nonexist.lab.example | grep -E 'status|ANSWER:'
```

**Expected output:**

```text
192.168.50.20
www.lab.example. 3600 IN CNAME web.lab.example.
web.lab.example. 3600 IN A 192.168.50.20
172.66.147.243
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 43392
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
```

(The `example.com` address is whatever your forwarder returns. I ran `named` directly in a container, not through systemd; on a normal host use `systemctl restart named`.)

**Acceptance criteria**

- [ ] The zone answers authoritatively (flag `aa`) for your names and `NXDOMAIN` for unknown ones.
- [ ] A client configured with `nameserver <your server>` resolves both local and public names.
- [ ] `named-checkzone` passes before every reload.

**Undo it**

```bash
sudo systemctl disable --now named
sudo rm -r /etc/bind/zones
# restore the packaged named.conf.options/.local from your backup or reinstall the package
```

**Troubleshooting**

- `zone ... loading from master file failed: not at top of zone`: a record has leading whitespace before the name, or a name is missing the trailing dot.
- `REFUSED`: the client IP is not in `allow-query` / `allow-recursion`.
- On Ubuntu, AppArmor blocks zone files outside `/etc/bind`, `/var/lib/bind` and `/var/cache/bind`; check `journalctl -k | grep DENIED`.

### Task 3.6: NAT router with nftables

- **What you will learn:** IP forwarding, masquerade (source NAT), and a forward chain that only lets internal clients out.
- **Target distro:** both (nftables). `firewalld` equivalent: `firewall-cmd --permanent --zone=external --add-masquerade`.
- **Risk level:** `can lock you out`. Running a router with a bad forward policy exposes the internal network. The lab below is entirely inside namespaces.

Build `client (10.10.0.2) → router → "internet" (203.0.113.10)`:

```bash
sudo ip netns add client; sudo ip netns add router; sudo ip netns add inet
sudo ip link add c-r type veth peer name r-c; sudo ip link set c-r netns client; sudo ip link set r-c netns router
sudo ip link add r-i type veth peer name i-r; sudo ip link set r-i netns router; sudo ip link set i-r netns inet
sudo ip -n client addr add 10.10.0.2/24 dev c-r; sudo ip -n client link set c-r up; sudo ip -n client link set lo up
sudo ip -n router addr add 10.10.0.1/24 dev r-c;  sudo ip -n router addr add 203.0.113.1/24 dev r-i
sudo ip -n router link set r-c up; sudo ip -n router link set r-i up
sudo ip -n inet addr add 203.0.113.10/24 dev i-r; sudo ip -n inet link set i-r up; sudo ip -n inet link set lo up
sudo ip -n client route add default via 10.10.0.1
sudo ip netns exec router sysctl -qw net.ipv4.ip_forward=1

echo "before NAT:"
sudo ip netns exec client ping -c1 -W1 203.0.113.10

sudo ip netns exec router nft -f - <<'EOF'
table ip nat {
  chain postrouting {
    type nat hook postrouting priority 100; policy accept;
    oifname "r-i" masquerade
  }
}
table inet filter {
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    iifname "r-c" oifname "r-i" accept
  }
}
EOF
echo "after NAT:"
sudo ip netns exec client ping -c2 -W1 203.0.113.10
```

On a real router make forwarding permanent: `echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-forward.conf && sudo sysctl --system`.

**Verify it worked**

**Expected output** (captured):

```text
before NAT:
1 packets transmitted, 0 received, 100% packet loss, time 0ms
after NAT:
--- 203.0.113.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1035ms
rtt min/avg/max/mdev = 0.083/0.094/0.106/0.011 ms
```

The "internet" has no route back to `10.10.0.0/24`, so the first ping fails; masquerade rewrites the
source address to `203.0.113.1`, so the second succeeds.

**Acceptance criteria**

- [ ] Ping fails before NAT and works after.
- [ ] Traffic from `inet` toward `client` is still dropped (`forward` policy drop).

**Undo it**

```bash
for n in client router inet; do sudo ip netns del "$n"; done
sudo rm -f /etc/sysctl.d/99-forward.conf
```

**Troubleshooting**

- No traffic after NAT: `net.ipv4.ip_forward` is 0, or the `forward` chain drops it. Run `nft list ruleset` and `sysctl net.ipv4.ip_forward`.
- Works for ping but not TCP: a stateful rule is missing (`ct state established,related accept`).
- Clients cannot resolve names: give them a DNS server (DHCP option from Task 3.4).

---

## Advanced

### Task 3.7: A VPN with WireGuard (OpenVPN as an alternative)

- **What you will learn:** key pairs, peers and `AllowedIPs`. WireGuard is in the Linux kernel, has a tiny config, and is usually the first choice today. OpenVPN is still useful for TCP/443 tunnelling and legacy clients.
- **Target distro:** both. `sudo apt install -y wireguard` / `sudo dnf install -y wireguard-tools` (kernel module is built in on current kernels).
- **Risk level:** `can lock you out`. `AllowedIPs = 0.0.0.0/0` routes all traffic through the tunnel and can cut off SSH. Start with only the tunnel subnet.

```bash
umask 077
wg genkey | tee server.key | wg pubkey > server.pub
wg genkey | tee client.key | wg pubkey > client.pub
wc -c server.key server.pub
```

**Server** (`/etc/wireguard/wg0.conf`, mode 600; replace the keys with your own):

```ini
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = <contents of server.key>

[Peer]
PublicKey = <contents of client.pub>
AllowedIPs = 10.8.0.2/32
```

**Client** (`/etc/wireguard/wg0.conf`):

```ini
[Interface]
Address = 10.8.0.2/24
PrivateKey = <contents of client.key>

[Peer]
PublicKey = <contents of server.pub>
Endpoint = vpn.example.org:51820
AllowedIPs = 10.8.0.0/24
PersistentKeepalive = 25
```

```bash
sudo ufw allow 51820/udp                 # RHEL: sudo firewall-cmd --permanent --add-port=51820/udp && sudo firewall-cmd --reload
sudo systemctl enable --now wg-quick@wg0
sudo wg show
ping -c2 10.8.0.1                        # from the client
```

**Verify it worked.** Key generation was captured (WireGuard keys are 44 characters plus a newline):

```text
45 /tmp/priv
```

The tunnel itself (`wg show` and `ping`) needs two hosts; *typical output*: `latest handshake: N seconds ago` and `transfer: ... received, ... sent` under the peer, and replies from `10.8.0.1`. I did not run this part.

OpenVPN alternative: use `easy-rsa` to build a CA and issue certificates, then `openvpn-server@server.service`. See the OpenVPN how-to linked below. Prefer WireGuard unless you need it.

**Acceptance criteria**

- [ ] `wg show` lists a recent handshake.
- [ ] Private keys are mode `600` and never copied into chat, tickets or git.
- [ ] Only the tunnel subnet is routed through the VPN (check `ip route`).

**Undo it**

```bash
sudo systemctl disable --now wg-quick@wg0
sudo rm /etc/wireguard/wg0.conf
shred -u server.key client.key 2>/dev/null || rm -f server.key client.key
```

**Troubleshooting**

- No handshake: the UDP port is blocked, the endpoint is wrong, or the public keys are swapped.
- Handshake works but no traffic: `AllowedIPs` mismatch on one side, or IP forwarding/NAT missing on the server.
- `RTNETLINK answers: Operation not supported`: the kernel lacks WireGuard (very old kernels); upgrade.

### Task 3.8: Monitor the network and write a custom check

- **What you will learn:** the Nagios plugin contract (exit code 0 OK, 1 WARNING, 2 CRITICAL, 3 UNKNOWN plus one line of text) that Nagios, Icinga, Zabbix, Sensu and Prometheus exporters can all use, and how to write your own check.
- **Target distro:** both. Plugins: `monitoring-plugins` (Debian/Ubuntu), `nagios-plugins-all` (EPEL on RHEL). Full servers: **Zabbix** or **Icinga 2** (see their quick-start guides) and **Prometheus** + `blackbox_exporter` in [Step 7](step-07-system-monitoring.md).
- **Risk level:** `safe`.

```bash
sudo apt install -y monitoring-plugins-basic monitoring-plugins-standard shellcheck
P=/usr/lib/nagios/plugins          # RHEL: /usr/lib64/nagios/plugins
$P/check_http -H 127.0.0.1 -p 8081 -w 1 -c 2     # start python3 -m http.server 8081 first
$P/check_tcp  -H 127.0.0.1 -p 9999 -t 2
$P/check_disk -w 20% -c 10% -p /
$P/check_load -w 5,4,3 -c 10,8,6
```

A custom check (memory used percent) that follows the contract:

```bash
sudo tee /usr/local/bin/check_mem_used.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Nagios-style check. Exit 0 OK, 1 WARNING, 2 CRITICAL, 3 UNKNOWN.
set -euo pipefail
warn="${1:-80}" crit="${2:-90}"
read -r total avail < <(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print t, a}' /proc/meminfo)
[[ -n "${total:-}" && "$total" -gt 0 ]] || { echo "UNKNOWN - cannot read /proc/meminfo"; exit 3; }
used=$(( (total - avail) * 100 / total ))
msg="memory used ${used}% | mem_used_pct=${used};${warn};${crit};0;100"
if   (( used >= crit )); then echo "CRITICAL - $msg"; exit 2
elif (( used >= warn )); then echo "WARNING - $msg";  exit 1
else echo "OK - $msg"; exit 0; fi
EOF
sudo chmod +x /usr/local/bin/check_mem_used.sh
check_mem_used.sh 80 90; echo "rc=$?"
check_mem_used.sh 1 2;   echo "rc=$?"
```

**Verify it worked**

**Expected output** (values depend on the machine):

```text
HTTP OK: HTTP/1.0 200 OK - 342 bytes in 0.003 second response time |time=0.002717s;1.000000;2.000000;0.000000;10.000000 size=342B;;;0;
rc=0
connect to address 127.0.0.1 and port 9999: Connection refused
rc=2
OK - memory used 29% | mem_used_pct=29;80;90;0;100
rc=0
CRITICAL - memory used 29% | mem_used_pct=29;1;2;0;100
rc=2
```

(Each plugin line was followed by its own `rc=` in the run; `check_disk` and `check_load` returned `OK` with rc 0. Full Nagios/Zabbix server installation and e-mail alerting were *not* run; follow the vendor guides below.)

**Acceptance criteria**

- [ ] Your check returns the right exit code at each threshold.
- [ ] `shellcheck` on the script is clean.
- [ ] You can describe how a monitoring server would call it (agent, NRPE or SSH).

**Undo it**

```bash
sudo rm /usr/local/bin/check_mem_used.sh
```

**Troubleshooting**

- Plugin not found: the path differs on RHEL (`/usr/lib64/nagios/plugins`).
- `check_http` returns `CRITICAL - Socket timeout`: a firewall drops the packets, or you used the wrong port.
- Exit code always 0 in the monitoring tool: the script printed text but did not `exit` with the status.

### Task 3.9: Load-balance with HAProxy

- **What you will learn:** frontend/backend, round-robin, active health checks and automatic failover.
- **Target distro:** both (`sudo apt install -y haproxy` / `sudo dnf install -y haproxy`). Config in `/etc/haproxy/haproxy.cfg`.
- **Risk level:** `safe` on loopback ports as shown.

```bash
mkdir -p /tmp/a /tmp/b
echo "server A" > /tmp/a/index.html; echo "server B" > /tmp/b/index.html
(cd /tmp/a && python3 -m http.server 8081 --bind 127.0.0.1 >/dev/null 2>&1 &)
(cd /tmp/b && python3 -m http.server 8082 --bind 127.0.0.1 >/dev/null 2>&1 &)

cat > /tmp/haproxy.cfg <<'EOF'
global
    log stdout format raw local0
    maxconn 2000

defaults
    mode http
    log global
    option httplog
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend web
    bind 127.0.0.1:8080
    default_backend app

backend app
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    server a 127.0.0.1:8081 check inter 2s fall 2 rise 2
    server b 127.0.0.1:8082 check inter 2s fall 2 rise 2
EOF
haproxy -c -f /tmp/haproxy.cfg
haproxy -f /tmp/haproxy.cfg -D -p /tmp/hap.pid
for i in 1 2 3 4; do curl -s 127.0.0.1:8080/; done
pkill -f "http.server 8081"; sleep 6          # health check marks A down after 2 failures
for i in 1 2 3; do curl -s 127.0.0.1:8080/; done
```

**Verify it worked**

**Expected output:**

```text
Configuration file is valid
server A
server B
server A
server B
after killing A:
server B
server B
server B
```

**Acceptance criteria**

- [ ] Requests alternate between backends.
- [ ] After one backend dies, no request fails.
- [ ] `haproxy -c` passes before each reload.

**Undo it**

```bash
kill "$(cat /tmp/hap.pid)"; pkill -f "http.server 808"
rm -rf /tmp/a /tmp/b /tmp/haproxy.cfg
```

**Troubleshooting**

- `503 Service Unavailable`: all backends are down or failing the health check. Check `option httpchk` path and status.
- `cannot bind socket`: another process holds the port (`ss -tulpn | grep 8080`).
- Session stickiness needed (shopping carts): add `cookie SERVERID insert indirect` and `cookie a`/`b` on the server lines.

---

## Step checklist

- [ ] 3.1 Interfaces
- [ ] 3.2 Tools
- [ ] 3.3 Firewall (nftables)
- [ ] 3.4 DHCP (dnsmasq)
- [ ] 3.5 DNS (BIND9)
- [ ] 3.6 NAT
- [ ] 3.7 VPN (WireGuard)
- [ ] 3.8 Monitoring checks
- [ ] 3.9 HAProxy

## Further reading

- [nftables wiki](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page): rules, sets, NAT and examples.
- [WireGuard quick start](https://www.wireguard.com/quickstart/): the official walk-through.
- [BIND 9 Administrator Reference Manual](https://bind9.readthedocs.io/en/latest/): every directive, with examples.
- [HAProxy documentation](https://docs.haproxy.org/): configuration manual for each version.
- [Nagios plugin development guidelines](https://nagios-plugins.org/doc/guidelines.html): the plugin exit-code and output contract.

**Next:** [Step 4: Shell Scripting](step-04-shell-scripting.md)
