<p align="center">
  <img src="assets/readme-banner.svg" alt="VPS Deploy Doctor banner" width="100%" />
</p>

<h1 align="center">VPS Deploy Doctor</h1>

<p align="center">
  <b>Read-only deployment diagnostics for student VPS projects and indie web apps.</b>
</p>

<p align="center">
  <a href="README.zh-CN.md">简体中文</a>
  ·
  <a href="#quick-start">Quick Start</a>
  ·
  <a href="#checks">Checks</a>
  ·
  <a href="#troubleshooting-map">Troubleshooting Map</a>
</p>

<p align="center">
  <a href="https://github.com/aolingge/vps-deploy-doctor/actions/workflows/validate.yml"><img src="https://img.shields.io/github/actions/workflow/status/aolingge/vps-deploy-doctor/validate.yml?branch=main&style=flat-square" alt="CI status" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/aolingge/vps-deploy-doctor?style=flat-square" alt="MIT license" /></a>
  <a href="https://github.com/aolingge/vps-deploy-doctor/releases"><img src="https://img.shields.io/github/v/release/aolingge/vps-deploy-doctor?style=flat-square" alt="Latest release" /></a>
</p>

---

<table>
  <tr>
    <td width="25%" valign="top"><b>Safe by default</b><br />No restarts, no firewall edits, no config writes.</td>
    <td width="25%" valign="top"><b>Find the layer</b><br />Separate Nginx, systemd, port, firewall, Docker, and HTTP issues.</td>
    <td width="25%" valign="top"><b>Get the next command</b><br />Print the log command users should run next.</td>
    <td width="25%" valign="top"><b>Scriptable output</b><br />Use JSON lines in CI, support scripts, or lab notes.</td>
  </tr>
</table>

<p align="center">
  <img src="assets/diagnosis-preview.svg" alt="VPS deployment diagnosis preview with pass warn and fail checks" width="92%" />
</p>

## Why This Exists

When a student project goes online and returns `502`, `404`, or nothing at all, the problem is usually one of five things:

- Nginx config is invalid or not reloaded.
- Spring Boot / Node / Python service is not running.
- The app port is wrong or blocked.
- Firewall or cloud security group is missing HTTP/HTTPS.
- Logs exist, but nobody knows which one to read first.

**VPS Deploy Doctor runs safe read-only checks and prints the next debugging command.**

## Quick Start

Copy the script to your VPS and run:

```bash
bash bin/vps-deploy-doctor.sh \
  --url http://example.com \
  --service demo-api \
  --port 8080
```

JSON output for automation:

```bash
bash bin/vps-deploy-doctor.sh --json --url http://127.0.0.1 --port 8080
```

You know it worked when you see a summary:

```text
PASS  nginx          nginx -t passed
WARN  firewall       no ufw or firewalld command found
FAIL  http           http://example.com returned HTTP 502

Summary: PASS=5 WARN=2 FAIL=1
```

## Checks

| Check | What it tells you |
| --- | --- |
| OS | Detects Linux distribution metadata. |
| Nginx | Runs `nginx -t` and checks whether the service is active. |
| HTTP | Requests the target URL and reports status code. |
| Port | Checks whether a process listens on the expected app port. |
| systemd | Checks whether your app service is active. |
| Firewall | Detects UFW or firewalld status. |
| Docker | Checks whether Docker daemon is reachable. |
| Disk / memory | Shows basic resource pressure. |
| Logs | Prints the next useful log command. |

## Troubleshooting Map

| Symptom | Start here |
| --- | --- |
| `502 Bad Gateway` | Check `systemd`, app port, and Nginx upstream. |
| Frontend refresh returns `404` | Check SPA fallback: `try_files $uri $uri/ /index.html;` |
| Domain does not open | Check cloud security group, firewall, DNS, and Nginx service. |
| App works locally but not on VPS | Check `--port`, `systemctl status`, and logs. |
| Docker app is down | Check `docker info` and `docker compose logs`. |

## Safety

This tool is read-only by default. It does not edit Nginx files, restart services, change firewall rules, or upload logs.

Do not paste private IPs, tokens, cookies, SSH keys, or full production logs into public issues.

## Works Well With

- [Student Deploy Kit](https://github.com/aolingge/student-deploy-kit)
- Spring Boot + Nginx VPS projects
- Vue / React static site deployments
- Docker Compose demos

## Contributing

Good first contributions:

- Add checks for Caddy.
- Add checks for common cloud metadata.
- Add Ubuntu and Debian examples.
- Add a PowerShell version for Windows Server.
- Improve JSON report format.

Run validation:

```bash
bash test/validate.sh
```

## License

MIT


## Quality Gate

Use this project as a repeatable gate before an AI agent marks work as done:

- [Quality gate guide](docs/quality-gates.md)
- [Copy-ready GitHub Actions example](examples/github-action.yml)

