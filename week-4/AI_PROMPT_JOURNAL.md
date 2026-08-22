# AI Prompt Journal — Week 4 Class 1

**Prompt used:**
> What defensive control would have prevented each attack I ran today? Map each attack to one OWASP control.

## AI Response

### 1. Recon (nmap)
- **Control:** Network segmentation / firewall rules (OWASP A05 — Security Misconfiguration)
- **Why:** Services like Postgres and Redis shouldn't be reachable from outside their internal network at all. Limiting exposed ports reduces what an attacker can see in the first place.

### 2. Code interception (Burp Suite catching the OAuth code)
- **Control:** HTTPS/TLS everywhere (OWASP — Transport Layer Protection)
- **Why:** The exchange happened over plain HTTP, so anyone sitting between the browser and server could read it. TLS encrypts that traffic so intercepted packets are useless.

### 3. Code replay / session hijack
- **Control:** PKCE (Proof Key for Code Exchange), code binding to the original client, and short code expiry (OWASP A07 — Identification and Authentication Failures)
- **Why:** PKCE means even if someone steals the authorization code, they can't exchange it for a token without a secret only the original app has. Short expiry limits the attack window too.

### 4. SSO bypass (trusting `user_id` from the request body)
- **Control:** Trust only verified token claims, never client-supplied identity fields (OWASP A07 — Identification and Authentication Failures)
- **Why:** The server should always pull "who is this user" from the cryptographically signed JWT payload, never from a value the client can type into a request. This was the exact bug exploited in Phase 4.

## Verification Note
All four attacks above were run and verified live against my own local lab stack on 21 August 2026, so these mappings reflect what actually happened rather than theoretical risks.
