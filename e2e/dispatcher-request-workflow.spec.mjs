import { expect, test } from "@playwright/test";

async function signInAsDispatcher(page) {
  await page.goto("/login");
  await page.getByLabel("Email").fill("dispatcher@gridline.test");
  await page.getByLabel("Password").fill("gridline");
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Dispatcher Dashboard" })).toBeVisible();
}

test("dispatcher can open a site and create a request with site context", async ({ page }) => {
  await signInAsDispatcher(page);

  await page.getByRole("link", { name: "Magnolia Midtown Atlanta", exact: true }).first().click();
  await expect(page.getByRole("heading", { name: "Magnolia Midtown Atlanta" })).toBeVisible();

  await page.getByRole("link", { name: "Create Service Request" }).click();
  await expect(page.getByRole("heading", { name: "New Service Request" })).toBeVisible();
  const selectedSiteContext = page.getByLabel("Selected site context");
  await expect(selectedSiteContext.getByText("Selected Site")).toBeVisible();
  await expect(selectedSiteContext.getByText("Magnolia Property Group - Magnolia Midtown Atlanta")).toBeVisible();

  const title = `Headed smoke test request ${Date.now()}`;
  await page.getByLabel("Service Provider").selectOption({ label: "Gridline Internal Dispatch Team" });
  await page.getByLabel("Title").fill(title);
  await page.getByLabel("Priority").selectOption("high");
  await page.getByLabel("Description").fill("Created by the headed Playwright smoke suite.");
  await page.getByRole("button", { name: "Create Request" }).click();

  await expect(page.getByRole("heading", { name: title })).toBeVisible();
  await expect(page.getByText("High")).toBeVisible();
});
