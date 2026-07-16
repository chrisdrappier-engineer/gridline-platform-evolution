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

async function createRequestForMagnoliaSite(page, title) {
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
  await page.getByLabel("Description").fill("Created to verify note visibility and evidence uploads.");
  await page.getByRole("button", { name: "Create Request" }).click();
  await expect(page.getByRole("heading", { name: title })).toBeVisible();
}

async function openRequestFromFacilityDashboard(page, title) {
  await page.getByRole("link", { name: "View Facility Requests" }).click();
  await expect(page.getByRole("heading", { name: "Service Requests" })).toBeVisible();
  await page.getByRole("searchbox", { name: "Search" }).fill(title);
  const requestRow = page.getByRole("row", { name: new RegExp(title) });
  await expect(requestRow).toBeVisible();
  const requestLink = requestRow.getByRole("link", { name: title, exact: true });
  await requestLink.focus();
  await requestLink.press("Enter");
  await expect(page.getByRole("heading", { name: title })).toBeVisible();
}

async function addNoteWithEvidence(page, { type, visibility, body, evidenceCategory, filePath }) {
  await page.getByLabel("Type").selectOption(type);
  await page.getByLabel("Visibility").selectOption(visibility);
  await page.getByLabel("Note").fill(body);
  await page.getByLabel("Evidence category").selectOption(evidenceCategory);
  await page.getByLabel("Evidence files").setInputFiles(filePath);
  await page.getByRole("button", { name: "Add Note" }).click();
  await expect(page.getByText("Service request note added.")).toBeVisible();
}

test("notes and evidence files follow role visibility rules", async ({ page }) => {
  const title = `Evidence visibility request ${Date.now()}`;
  const internalNote = `Internal dispatcher evidence note ${Date.now()}`;
  const customerNote = `Customer visible evidence note ${Date.now()}`;

  await signIn(page, "dispatcher@gridline.test", "Dispatcher Dashboard");
  await createRequestForMagnoliaSite(page, title);

  await addNoteWithEvidence(page, {
    type: "intake",
    visibility: "internal",
    body: internalNote,
    evidenceCategory: "diagnostic_report",
    filePath: "app/db/demo_files/diagnostic-report.txt"
  });

  const dispatcherNote = page.locator(".note-card", { hasText: internalNote });
  await expect(dispatcherNote).toBeVisible();
  await expect(dispatcherNote.getByText("diagnostic-report.txt")).toBeVisible();

  await signOut(page);
  await signIn(page, "facility.manager@magnoliaproperty.test", "Facility Manager Dashboard");
  await openRequestFromFacilityDashboard(page, title);

  await expect(page.locator(".note-card", { hasText: internalNote })).toHaveCount(0);
  await expect(page.getByText("diagnostic-report.txt")).toHaveCount(0);

  await addNoteWithEvidence(page, {
    type: "customer_update",
    visibility: "customer_visible",
    body: customerNote,
    evidenceCategory: "approval_document",
    filePath: "app/db/demo_files/approval-document.pdf"
  });

  const facilityManagerNote = page.locator(".note-card", { hasText: customerNote });
  await expect(facilityManagerNote).toBeVisible();
  await expect(facilityManagerNote.getByText("approval-document.pdf")).toBeVisible();
});
