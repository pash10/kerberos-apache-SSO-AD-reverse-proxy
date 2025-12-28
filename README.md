# Kerberos Apache Reverse Proxy with SSO + AD (SSSD)

This repository contains a **working, minimal** configuration for an **Apache reverse proxy** that:

- Authenticates users via **Kerberos SSO** (GSSAPI / Negotiate)
- Resolves the authenticated user and **AD group membership** using **SSSD**
- Forwards identity to a backend app using HTTP headers (example: `X-User`, `X-User-Groups`)
- Proxies traffic to an internal backend (example: `http://127.0.0.1:5173/`)

This is **not a tutorial** on Kerberos / Apache / SSSD fundamentals.  
It’s a “known-good config pack” you can adapt in a real environment.

---

## Repo structure

### `apache2.conf`
Main Apache configuration (single-file style) containing:
- `VirtualHost` for the proxy port
- `mod_auth_gssapi` Kerberos SSO settings
- `mod_lookup_identity` integration (SSSD/DBus) for group lookup
- Header injection to the backend
- ProxyPass / ProxyPassReverse rules
- Logging (including debug-friendly formats)

**Purpose:** This is the core of the project.

---

### `krb5.conf`
Kerberos client configuration:
- Realm definition(s)
- KDC and admin server endpoints
- DNS behavior flags

**Purpose:** Required for GSSAPI authentication to work correctly inside the container/host.

> Note: Use placeholders for realms/domains in public repos.

---

### `sssd.conf`
SSSD configuration:
- Domain configuration (AD / LDAP provider settings)
- NSS integration for user/group resolution
- IFP/DBus exposure (required by `mod_lookup_identity` in many setups)

**Purpose:** Apache needs SSSD to resolve users + groups reliably.

> Note: Never publish real bind creds, hostnames, or internal domains.

---

### `nsswitch.conf`
NSS configuration:
- Ensures the system uses `sss` (SSSD) for passwd/group lookups

**Purpose:** Enables consistent identity lookup behavior (important for SSSD-backed identity).

---

### `resolv.conf`
DNS resolver configuration

**Purpose:** Kerberos and AD discovery are extremely DNS-sensitive.  
This file is included so the container/host resolves the correct internal domains.

---

### `dockerfile`
Build recipe for the container image.

Typical responsibilities:
- Install Apache + modules (proxy, headers, rewrite, auth_gssapi, lookup_identity)
- Install SSSD + dependencies (including DBus support if needed)
- Copy configs into the image
- Set permissions and entrypoints

**Purpose:** Reproducible build of the environment.

---

### `ker-compose.yaml`
Docker Compose file to run the service.

Typical responsibilities:
- Expose proxy port (example: `15173`)
- Mount configs (if using bind mounts)
- Provide required capabilities / tmpfs / volumes (depends on SSSD + DBus style)
- Define networking and the backend target

**Purpose:** One-command run.

---

## Identity headers forwarded to backend

This setup forwards identity using headers (names can be changed as needed):

- `X-User`: the authenticated username (from `REMOTE_USER`)
- `X-User-Groups`: AD groups resolved via SSSD / lookup_identity

If your backend needs a different format:
- change the header names
- change the delimiter for groups (space vs `:` vs comma)

---

## Gentle setup (high-level)

### 1) Prerequisites you must already have
- A working Kerberos realm / AD environment
- A **keytab** for `HTTP/<hostname>@REALM` (do not commit keytabs)
- DNS that correctly resolves AD/KDC hosts
- Time sync (Kerberos will fail if clocks drift)

### 2) Configure secrets locally (NOT in GitHub)
You will need to provide locally:
- `/etc/krb5.keytab` (or another path referenced in `apache2.conf`)
- Real realm/domain values (replace placeholders)
- Correct DNS resolver configuration for your environment

### 3) Run
Using Compose (example):
```bash
docker compose -f ker-compose.yaml up --build
