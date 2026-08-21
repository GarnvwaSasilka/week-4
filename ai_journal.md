# AI Journal Entry — Class 2: API Attack Surface

## Prompt
What are the 5 most dangerous API endpoints in a typical e-commerce backend and why?

## AI Response Summary
1. User/account object access — dangerous if the API doesn't verify the requester
   owns the object being accessed (e.g. /users/{id}, /orders/{id}).
2. Password reset / auth token endpoints — vulnerable to weak tokens, no rate
   limiting, or user enumeration if not properly secured.
3. Admin/internal endpoints — dangerous if role checks are missing or can be
   bypassed, exposing sensitive store management functions.
4. Checkout/order creation — can be abused to manipulate pricing, discounts,
   or bypass normal purchase flow logic.
5. Payment/refund endpoints — high risk if authorization isn't tied to the
   correct object owner, allowing refunds or payment actions on other users' orders.

## OWASP API Security Top 10 Verification

| Endpoint Risk                     | OWASP Match                                        | Why |
|-----------------------------------|-----------------------------------------------------|-----|
| User/account object access        | API1: Broken Object Level Authorization (BOLA)      | No ownership check on object IDs |
| Password reset / auth tokens      | API2: Broken Authentication                         | Weak tokens, no rate limiting, enumeration risk |
| Admin/internal endpoints          | API5: Broken Function Level Authorization           | Role checks missing/bypassed on sensitive endpoints |
| Checkout/order creation           | API6: Unrestricted Access to Sensitive Business Flows | Abuse of purchase/discount workflow |
| Payment/refund endpoints          | API1: Broken Object Level Authorization (BOLA)      | Refunding an order that isn't yours = object-level auth failure |

 #Reflection
This exercise mapped my own /store/products, /store/orders, and /admin/products
probing (Steps 4–7) onto real-world OWASP risk categories. The /admin/products
endpoint returning 401 Unauthorized lines up directly with API5, since Medusa
correctly blocks unauthenticated access to admin functions.
