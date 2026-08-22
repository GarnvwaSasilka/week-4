# Service Map — Week 4 Lab

Target host: local lab environment (VirtualBox Host-Only network)

| Port | Service | What it does |
|------|---------|---------------|
| 9000 | Medusa backend | Storefront API |
| 3001 | Auth server | Issues OAuth authorization codes and access tokens |
| 3002 | Broken auth / SSO service | Validates session tokens — contains seeded access control flaw |
| 5432 | PostgreSQL | Database |
| 6379 | Redis | Cache |

## Recon command used

```bash
nmap -sV -p 9000,3001,3002,5432,6379 <host-ip>
```

## Result summary

All five ports returned **open**, with full service/version banners exposed (Node.js Express, PostgreSQL 9.6+, Redis 7.4.11) — no authentication required to view them.
