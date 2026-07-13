import { expect, test } from "@playwright/test";

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
    visibleText: "Facility Views"
  },
  {
    email: "customer.contact@magnoliaproperty.test",
    dashboard: "Customer Contact Dashboard",
    visibleText: "Account Views"
  },
  {
    email: "provider.user@coastalcoldchain.test",
    dashboard: "Service Provider Dashboard",
    visibleText: "Provider Views"
  },
  {
    email: "admin@gridline.test",
    dashboard: "Admin Dashboard",
    visibleText: "Administration Views"
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
  });
}
