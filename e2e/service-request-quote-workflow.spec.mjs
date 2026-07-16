import { expect, test } from "@playwright/test";

const password = "gridline";

async function signIn(page, email, dashboardHeading) {
  await page.goto("/login");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: dashboardHeading })).toBeVisible();
}

async function signOut(page) {
  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page.getByRole("heading", { name: /Sign in/i })).toBeVisible();
}

test("dispatcher submits quote and facility manager approves it", async ({ page }) => {
  await signIn(page, "dispatcher@gridline.test", "Dispatcher Dashboard");

  await page.getByRole("link", { name: "View Sites" }).click();
  await expect(page.getByRole("heading", { name: "Sites" })).toBeVisible();
  await page.getByRole("searchbox", { name: "Search" }).fill("Magnolia Midtown Atlanta");
  await page.getByRole("link", { name: "Magnolia Midtown Atlanta", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Magnolia Midtown Atlanta" })).toBeVisible();

  await page.getByRole("link", { name: "Create Service Request" }).click();
  await expect(page.getByRole("heading", { name: "New Service Request" })).toBeVisible();

  const title = `Quote approval smoke request ${Date.now()}`;
  await page.getByLabel("Service Provider").selectOption({ label: "Gridline Internal Dispatch Team" });
  await page.getByLabel("Title").fill(title);
  await page.getByLabel("Priority").selectOption("normal");
  await page.getByLabel("Description").fill("Created to verify quote approval workflow.");
  await page.getByRole("button", { name: "Create Request" }).click();

  await expect(page.getByRole("heading", { name: title })).toBeVisible();
  await page.getByLabel("Quoted Amount").fill("950.00");
  await page.getByLabel("Quote Description").fill("Replace controller and damaged wiring discovered during intake.");
  await page.getByRole("button", { name: "Submit Quote" }).click();
  await expect(page.getByText("Approval is required before work proceeds.")).toBeVisible();
  await expect(page.getByText("Pending approval")).toBeVisible();

  await signOut(page);
  await signIn(page, "facility.manager@magnoliaproperty.test", "Facility Manager Dashboard");

  await page.getByRole("link", { name: "View Facility Requests" }).click();
  await expect(page.getByRole("heading", { name: "Service Requests" })).toBeVisible();
  await page.getByRole("searchbox", { name: "Search" }).fill(title);
  const requestRow = page.getByRole("row", { name: new RegExp(title) });
  await expect(requestRow).toBeVisible();
  const requestLink = requestRow.getByRole("link", { name: title, exact: true });
  await requestLink.focus();
  await requestLink.press("Enter");
  await expect(page.getByRole("heading", { name: title })).toBeVisible();

  await expect(page.getByText("Pending approval")).toBeVisible();
  await page.getByRole("button", { name: "Approve Quote" }).click();
  await expect(page.getByText("Quote approved.")).toBeVisible();
  await expect(page.locator(".status-approved", { hasText: "Approved" })).toBeVisible();
});
