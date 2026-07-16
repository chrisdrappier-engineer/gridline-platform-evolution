import { expect, test } from "@playwright/test";

const password = "gridline";

const users = [
  {
    email: "dispatcher@gridline.test",
    dashboard: "Dispatcher Dashboard",
    visibleText: "Operations Reporting"
  },
  {
    email: "facility.manager@magnoliaproperty.test",
    dashboard: "Facility Manager Dashboard",
    visibleText: "Facility Reporting"
  },
  {
    email: "customer.contact@magnoliaproperty.test",
    dashboard: "Customer Contact Dashboard",
    visibleText: "Account Reporting"
  },
  {
    email: "provider.user@coastalcoldchain.test",
    dashboard: "Service Provider Dashboard",
    visibleText: "Provider Views"
  },
  {
    email: "admin@gridline.test",
    dashboard: "Admin Dashboard",
    visibleText: "Management Reporting"
  }
];

async function signIn(page, email) {
  await page.goto("/login");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
}

for (const user of users) {
  test(`${user.email} lands on the role-specific dashboard`, async ({ page }) => {
    await signIn(page, user.email);

    await expect(page).toHaveURL(/\/dashboard$/);
    await expect(page.getByRole("heading", { name: user.dashboard })).toBeVisible();
    await expect(page.getByText(user.visibleText)).toBeVisible();
    await expect(page.getByText("Calculated live from authorized operational records").first()).toBeVisible();
  });
}
