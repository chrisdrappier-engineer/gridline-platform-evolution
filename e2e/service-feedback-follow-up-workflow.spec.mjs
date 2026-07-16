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

async function openRequestFromTable(page, title) {
  await page.getByRole("searchbox", { name: "Search" }).fill(title);
  const requestRow = page.getByRole("row", { name: new RegExp(title) });
  await expect(requestRow).toBeVisible();
  const requestLink = requestRow.getByRole("link", { name: title, exact: true });
  await requestLink.focus();
  await requestLink.press("Enter");
  await expect(page.getByRole("heading", { name: title })).toBeVisible();
}

async function createMagnoliaRequest(page, title) {
  await page.getByRole("link", { name: "View Sites" }).click();
  await expect(page.getByRole("heading", { name: "Sites" })).toBeVisible();
  await page.getByRole("searchbox", { name: "Search" }).fill("Magnolia Midtown Atlanta");
  await page.getByRole("link", { name: "Magnolia Midtown Atlanta", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Magnolia Midtown Atlanta" })).toBeVisible();

  await page.getByRole("link", { name: "Create Service Request" }).click();
  await expect(page.getByRole("heading", { name: "New Service Request" })).toBeVisible();
  await page.getByLabel("Service Provider").selectOption({ label: "Gridline Internal Dispatch Team" });
  await page.getByLabel("Title").fill(title);
  await page.getByLabel("Priority").selectOption("normal");
  await page.getByLabel("Description").fill("Created to verify feedback and follow-up request workflow.");
  await page.getByRole("button", { name: "Create Request" }).click();
  await expect(page.getByRole("heading", { name: title })).toBeVisible();
}

test("facility feedback can trigger dispatcher follow-up request", async ({ page }) => {
  const title = `Feedback follow-up request ${Date.now()}`;
  const followUpTitle = `Follow-up from feedback ${Date.now()}`;

  await signIn(page, "dispatcher@gridline.test", "Dispatcher Dashboard");
  await createMagnoliaRequest(page, title);

  await page.getByLabel("Actions Taken").fill("Completed the initial service and restored normal operation.");
  await page.getByLabel("Follow-Up Requirements").fill("Facility manager should confirm if finish work is needed.");
  await page.getByLabel("Mark provider work complete").check();
  await page.getByRole("button", { name: "Record Provider Update" }).click();
  await expect(page.getByText("Provider work marked complete.")).toBeVisible();
  await expect(page.locator(".status-resolved", { hasText: "Resolved" })).toBeVisible();

  await signOut(page);
  await signIn(page, "facility.manager@magnoliaproperty.test", "Facility Manager Dashboard");
  await page.getByRole("link", { name: "View Facility Requests" }).click();
  await expect(page.getByRole("heading", { name: "Service Requests" })).toBeVisible();
  await openRequestFromTable(page, title);

  await page.getByLabel("Rating").selectOption("3");
  await page.getByLabel("Follow-up work needed").check();
  await page.getByLabel("Completion feedback").fill("Primary issue is resolved, but a follow-up request is needed for finish inspection.");
  await page.getByRole("button", { name: "Submit Feedback" }).click();
  await expect(page.getByText("Service feedback submitted.")).toBeVisible();
  await expect(page.locator(".detail-list dd", { hasText: "3 - Satisfactory" })).toBeVisible();
  await expect(page.getByText("Follow-Up Needed")).toBeVisible();

  await signOut(page);
  await signIn(page, "dispatcher@gridline.test", "Dispatcher Dashboard");
  await page.getByRole("link", { name: "View Requests" }).click();
  await expect(page.getByRole("heading", { name: "Service Requests" })).toBeVisible();
  await openRequestFromTable(page, title);

  await page.getByRole("link", { name: "Create Follow-Up Request" }).click();
  await expect(page.getByRole("heading", { name: "New Service Request" })).toBeVisible();
  await expect(page.getByRole("heading", { name: new RegExp(`Follow-up to ${title}`) })).toBeVisible();
  await page.getByLabel("Title").fill(followUpTitle);
  await page.getByLabel("Description").fill("Follow-up created from completion feedback.");
  await page.getByRole("button", { name: "Create Request" }).click();
  await expect(page.getByRole("heading", { name: followUpTitle })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Related Requests" })).toBeVisible();
  await expect(page.getByRole("link", { name: title })).toBeVisible();
});
