# surge-configs

[Surge for iOS](https://nssurge.com) configuration(s) built around the built-in
[Tailscale policy](https://manual.nssurge.com/policies/tailscale.html).

## Goals

`firefly.config` aims to give an iPhone complete network-level filtering while keeping tailnet access:

1. **Tailnet access.** Surge joins the tailnet as its own node, so the iOS Tailscale app is not needed
   and the two do not fight over the single VPN slot.
2. **Upstream DNS security that stays off the tailnet.** All DNS goes to Cloudflare over TLS (DoT),
   routed direct, never through the tailnet or an exit node.
3. **DNS-style blocklisting** comparable to AdGuard Pro for iOS: ads, trackers, malware, phishing
   and C2 domains, plus blocking of DoH endpoints that would let apps bypass the filtering.

## How it works

| Piece | Config | Purpose |
|---|---|---|
| Tailscale node | `[Proxy] Tailnet = tailscale, section-name=Home` and `[Tailscale Home]` | Joins the tailnet as `iphone192-surge`. First launch needs the interactive login. |
| Tailnet routing | `IP-CIDR 100.64.0.0/10`, `IP-CIDR6 fd7a:115c:a1e0::/48` to `Tailnet` | Sends tailnet IPs through the tailnet. |
| MagicDNS | `auto-add-magic-dns-rule = true` | Surge adds a rule so tailnet hostnames resolve via the tailnet's DNS. |
| Encrypted upstream DNS | `encrypted-dns-server = tls://1.1.1.1, tls://1.0.0.1` | DNS-over-TLS with certificate verification on. |
| DNS hijack | `hijack-dns = *:53` | Captures plain DNS from apps and answers it through Surge's resolver. |
| Blocking | `DOMAIN-SET ... REJECT,pre-matching` | See below. |
| Everything else | `FINAL,DIRECT` | Normal traffic goes out directly. Only tailnet traffic is proxied. |

### Rule lists

| List | Source | Role |
|---|---|---|
| `lists/tif.mini.domainset` | [hagezi](https://github.com/hagezi/dns-blocklists) `tif.mini` | Threat intelligence feed: malware, phishing, C2, scams. |
| `lists/doh.domainset` | hagezi `doh` | Public DoH resolvers, blocked so apps cannot sidestep DNS filtering. |
| `lists/pro.domainset` | hagezi `pro` | Ads, trackers, and other unwanted domains (the AdGuard Pro-style layer). |

The hagezi lists are converted by `scripts/convert-hagezi.sh` (daily via GitHub Actions) because Surge
matches bare `DOMAIN-SET` entries exactly; the leading dot makes them match subdomains too.

`pre-matching` makes Surge evaluate REJECT rules before all other rules. The threat and DoH lists use it. The
Pro ad/tracker list does not, so personal `DIRECT` exceptions placed above it can override it.

`DEST-PORT,853` (DoT) and UDP 443 (QUIC) are rejected so apps cannot bypass DNS filtering or hide the SNI.
`extended-matching` also matches the TLS SNI and HTTP Host of a connection, which catches
traffic that connects by IP or resolved its name elsewhere.

## Install

1. In Surge for iOS, import the config from this repo (raw URL, file, or AirDrop) and select it.
2. Start Surge and complete the Tailscale interactive login when prompted.
3. Let the rule sets download (Surge > Rules > Update external resources).
4. Verify: open a tailnet hostname, run Surge's DNS test, and visit a known ad domain to confirm it is rejected.

## Files

- `firefly.config`: the Surge profile.
- `lists/`: hagezi lists converted to Surge format (generated, do not edit).
- `scripts/convert-hagezi.sh`: the converter.
- `.github/workflows/update-lists.yml`: refreshes `lists/` daily.
