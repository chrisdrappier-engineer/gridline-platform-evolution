import { expect, test } from "@playwright/test";

const password = "gridline";

async function signIn(page, email, dashboardHeading) {
  await page.goto("/login");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: dashboardHeading })).toBeVisible();
}

async function navigateViaMenu(page, linkName, headingName) {
  const navigation = page.getByRole("navigation", { name: "Primary navigation" });

  if (!(await navigation.isVisible())) {
    await page.getByRole("button", { name: "Menu" }).click();
    await expect(navigation).toBeVisible();
  }

  await navigation.getByRole("link", { name: linkName }).click();
  await expect(page.getByRole("heading", { name: headingName, exact: true })).toBeVisible();
}

async function expectSharedTableControls(page, { frameId, search, filters = [] }) {
  const frame = page.locator(`turbo-frame#${frameId}`);
  await expect(frame).toBeVisible();
  await expect(frame.getByRole("searchbox", { name: "Search" })).toBeVisible();
  await expect(frame.getByRole("combobox", { name: "Per Page" })).toBeVisible();
  await expect(frame.getByRole("link", { name: "Clear" })).toBeVisible();

  for (const filter of filters) {
    await expect(frame.getByRole("combobox", { name: filter })).toBeVisible();
  }

  if (search) {
    await frame.getByRole("searchbox", { name: "Search" }).fill(search);
    await expect(frame.locator("tbody")).toContainText(search);
  }
}

test("sites table supports search, filters, sorting, pagination, and normal row navigation", async ({ page }) => {
  await signIn(page, "dispatcher@gridline.test", "Dispatcher Dashboard");

  await navigateViaMenu(page, "Sites", "Sites");

  const frame = page.locator("turbo-frame#customer_sites_table");
  await expectSharedTableControls(page, {
    frameId: "customer_sites_table",
    filters: ["Status"]
  });

  await frame.getByRole("combobox", { name: "Per Page" }).selectOption("10");
  await expect(frame.getByText(/1-10 of/)).toBeVisible();

  await frame.getByRole("link", { name: "Customer" }).click();
  await expect(frame.locator("a.sort-link.active")).toContainText("Customer");

  await frame.getByRole("combobox", { name: "Status" }).selectOption({ label: "Inactive" });
  await expect(frame.locator("tbody tr").first()).toContainText("Inactive");

  await frame.getByRole("link", { name: "Clear" }).click();
  await expect(frame.getByRole("searchbox", { name: "Search" })).toHaveValue("");
  await frame.getByRole("searchbox", { name: "Search" }).fill("Magnolia Midtown Atlanta");
  await frame.getByRole("link", { name: "Magnolia Midtown Atlanta", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Magnolia Midtown Atlanta" })).toBeVisible();
});

test("migrated operations tables expose the shared table controls", async ({ page }) => {
  await signIn(page, "dispatcher@gridline.test", "Dispatcher Dashboard");

  await navigateViaMenu(page, "Customers", "Customers");
  await expectSharedTableControls(page, {
    frameId: "customers_table",
    search: "Magnolia Property Group",
    filters: ["Status"]
  });

  await navigateViaMenu(page, "Service Providers", "Service Providers");
  await expectSharedTableControls(page, {
    frameId: "service_providers_table",
    search: "Gridline Internal Dispatch Team",
    filters: ["Type", "Status"]
  });

  await navigateViaMenu(page, "Requests", "Service Requests");
  await expectSharedTableControls(page, {
    frameId: "service_requests_table",
    search: "Lobby HVAC failure",
    filters: ["Status", "Priority", "Site", "Dispatcher"]
  });
});

test("migrated admin tables expose the shared table controls while permission matrix remains static", async ({ page }) => {
  await signIn(page, "admin@gridline.test", "Admin Dashboard");

  await navigateViaMenu(page, "Users", "Users");
  await expectSharedTableControls(page, {
    frameId: "users_table",
    search: "Dana Dispatcher",
    filters: ["Legacy Role", "Status"]
  });

  await navigateViaMenu(page, "Role Assignments", "Role Assignments");
  await expectSharedTableControls(page, {
    frameId: "role_assignments_table",
    search: "Dana Dispatcher",
    filters: ["Role", "Scope"]
  });

  await navigateViaMenu(page, "Permission Matrix", "Permission Matrix");
  await expect(page.locator("turbo-frame#role_permissions_table")).toHaveCount(0);
  await expect(page.locator(".permission-matrix")).toBeVisible();
});
