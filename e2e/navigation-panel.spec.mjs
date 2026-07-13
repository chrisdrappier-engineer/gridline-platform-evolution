import { expect, test } from "@playwright/test";

async function signInAsDispatcher(page) {
  await page.goto("/login");
  await page.getByLabel("Email").fill("dispatcher@gridline.test");
  await page.getByLabel("Password").fill("gridline");
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Dispatcher Dashboard" })).toBeVisible();
}

test("navigation panel stays open across route changes until closed", async ({ page }) => {
  await signInAsDispatcher(page);

  await page.getByRole("button", { name: "Menu" }).click();
  const navigation = page.getByRole("navigation", { name: "Primary navigation" });
  await expect(navigation).toBeVisible();

  await navigation.getByRole("link", { name: "Customers" }).click();
  await expect(page.getByRole("heading", { name: "Customers" })).toBeVisible();
  await expect(navigation).toBeVisible();

  await page.getByRole("button", { name: "Menu" }).click();
  await expect(navigation).toBeHidden();
});

test("signed-out login page is not constrained by the navigation layout", async ({ page }) => {
  await signInAsDispatcher(page);
  await page.getByRole("button", { name: "Menu" }).click();
  await expect(page.getByRole("navigation", { name: "Primary navigation" })).toBeVisible();

  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page.getByRole("heading", { name: "Sign in to Gridline Operations" })).toBeVisible();

  const headingWidth = await page
    .getByRole("heading", { name: "Sign in to Gridline Operations" })
    .evaluate((element) => element.getBoundingClientRect().width);
  expect(headingWidth).toBeGreaterThan(300);
});
