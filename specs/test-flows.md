# Test flows

One entry per user flow, with one test file per flow. Update this index in the same change as the tests.

## 1. Sign in
- **Test file:** `e2e/sign-in.spec.ts`
- **Steps:**
  1. Open the sign-in page.
  2. Submit valid credentials.
  3. Land on the dashboard.
- **Variants:** wrong password (error state); Chinese language; 320px viewport.

## Rules (unit)
| Rule | Test file |
|---|---|
| Pricing | `src/domain/pricing.test.ts` |
