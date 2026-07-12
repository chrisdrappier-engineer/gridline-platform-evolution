import { expect, test } from "@playwright/test";
import { pauseForReview } from "./support/pause-for-review.mjs";

const password = "gridline";

const users = [
  {
    email: "dispatcher@gridline.test",
    dashboard: "Dispatcher Dashboard",
    visibleText: "New Queue"
  },
  {
    email: "facility.manager@magnoliaproperty.test",
    dashboard: "Facility Manager Dashboard",
    visibleText: "Managed Facilities"
  },
  {
    email: "customer.contact@magnoliaproperty.test",
    dashboard: "Customer Contact Dashboard",
    visibleText: "Customers"
  },
  {
    email: "provider.user@coastalcoldchain.test",
    dashboard: "Service Provider Dashboard",
    visibleText: "My Providers"
  },
  {
    email: "admin@gridline.test",
    dashboard: "Admin Dashboard",
    visibleText: "Recent Role Assignments"
  }
];

async function signIn(page, email) {
  await page.goto("/login");
  await pauseForReview(page);
  await page.getByLabel("Email").fill(email);
  await pauseForReview(page);
  await page.getByLabel("Password").fill(password);
  await pauseForReview(page);
  await page.getByRole("button", { name: "Sign in" }).click();
}

for (const user of users) {
  test(`${user.email} lands on the role-specific dashboard`, async ({ page }) => {
    await signIn(page, user.email);

    await expect(page).toHaveURL(/\/dashboard$/);
    await expect(page.getByRole("heading", { name: user.dashboard })).toBeVisible();
    await expect(page.getByText(user.visibleText)).toBeVisible();
    await pauseForReview(page);
  });
}
