# Basiq — real Australian open banking, in about 25 minutes

Basiq is the CDR/open-banking aggregator for AU/NZ banks. It has a free
sandbox with fake-but-realistic personas, which is exactly what a hackathon
demo needs. Owner: **whoever takes the Data lane.**

## 1. Get a key

1. Sign up at <https://dashboard.basiq.io/>.
2. Create an application (leave it on API version 3.0).
3. Developers tab → generate an API key. Copy it once — it is shown once.
4. Put it in `backend/.env`:

   ```
   BASIQ_API_KEY=<the long base64 string>
   ```

   `.env` is gitignored. **Do not paste the key into Slack or a slide.**

## 2. The auth flow (two different tokens — this is the part people get wrong)

| Step | Scope | Who uses it |
|---|---|---|
| `POST /token` with `Authorization: Basic <API_KEY>`, `basiq-version: 3.0`, body `scope=SERVER_ACCESS` | server | your backend, for every data call |
| `POST /token` with body `scope=CLIENT_ACCESS&userId=<id>` | client | handed to the browser to open the consent UI |

Tokens expire after **60 minutes**. `bank.py` refreshes at 55.

## 3. Connect a test bank

```
POST /users                     -> { "id": "<userId>" }   (save this)
POST /token scope=CLIENT_ACCESS&userId=<userId>
open https://consent.basiq.io/home?token=<client token>
```

In the consent UI pick **Hooli (AU00000)** — the open-banking test bank.

**Sandbox logins** (from Basiq's testing reference):

| Persona | Username | Password | Story |
|---|---|---|---|
| Wentworth-Smith | `Wentworth-Smith` | `whislter` | joint account, mortgage, credit card |
| Whistler | `Whistler` | `ShowBox` | single salary, BNPL, transfers |
| Gilfoyle | `Gilfoyle` | `PiedPiper` | benefits income, rising BNPL |
| jared | `jared` | `django` | weekly volatile income, car loan |
| ashMann | `ashMann` | `hooli2024` | salary + rental, risk flags |

For the **open-banking** flow Hooli asks for a member number + OTP instead:
member `374829`, OTP `227470`.

**Pick `Whistler` for the demo.** Single income + BNPL + subscriptions is the
closest persona to a student, and it makes the subscription-sweep mission fire.

Error personas if you want to test failure states: `bighead/password` (locked),
`erlich/aviato` (needs user action), `jianYang/nothotdog` (service down).

Sandbox connections are capped at **500 per account** — plenty, but don't loop.

## 4. Pull the data

```
GET https://au-api.basiq.io/users/{userId}/accounts
GET https://au-api.basiq.io/users/{userId}/transactions?filter=transaction.postDate.gt('2026-07-29')&limit=500
Authorization: Bearer <server token>
```

Both are already implemented in `backend/bank.py::BasiqProvider`. Once
`BASIQ_API_KEY` and `BASIQ_USER_ID` are in `.env`, `/api/health` will report
`"provider": "basiq"` and every endpoint switches over with no other change.

## 5. The fallback that saves the pitch

`main.py` wraps every provider call in `_safe()`. If Basiq times out, rate
limits, or the venue wifi drops, it **silently falls back to the seeded mock
provider** and the demo keeps running. Nobody in the audience can tell.

Before you present:

```bash
curl localhost:8000/api/health          # confirm which provider is live
unset BASIQ_API_KEY && uvicorn main:app # rehearse the offline path once
```

Rehearse the demo at least once with the laptop's wifi **off**. If it still
works, you cannot be embarrassed on stage.

## Judge questions you should have an answer for

- *"Are you accredited under CDR?"* — No. Basiq is the accredited data
  recipient; we are a client of theirs, which is the standard path for a
  startup at this stage. Production would need us to become an ADR or operate
  under Basiq's sponsorship/TA arrangement.
- *"Do you move money?"* — No. We read transactions and recommend. Nothing in
  the codebase can initiate a payment. That was a deliberate call (see the
  ethics note in the pitch).
- *"What about consent?"* — Basiq's consent UI handles it, and consent is
  time-limited and revocable by the user.

Sources: [Basiq quickstart](https://api.basiq.io/docs/quickstart-code-free),
[Basiq testing reference](https://api.basiq.io/reference/testing),
[Basiq accounts API](https://api.basiq.io/reference/getaccounts),
[Basiq CDR compliance](https://api.basiq.io/docs/cdr-compliance)
