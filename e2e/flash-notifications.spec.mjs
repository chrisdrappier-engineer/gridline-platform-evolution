import { expect, test } from "@playwright/test";

async function signInAsDispatcher(page) {
  await page.goto("/login");
  await page.getByLabel("Email").fill("dispatcher@gridline.test");
  await page.getByLabel("Password").fill("gridline");
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.getByRole("heading", { name: "Dispatcher Dashboard" })).toBeVisible();
}

test("flash notification can be dismissed immediately", async ({ page }) => {
  await signInAsDispatcher(page);

  const flash = page.getByRole("status").filter({ hasText: "Signed in as Dana Dispatcher." });
  await expect(flash).toBeVisible();

  await flash.getByRole("button", { name: "Dismiss notification" }).click();
  await expect(flash).toBeHidden();
});

test("flash notification disappears after ten seconds", async ({ page }) => {
  await page.clock.install();
  await signInAsDispatcher(page);

  const flash = page.getByRole("status").filter({ hasText: "Signed in as Dana Dispatcher." });
  await expect(flash).toBeVisible();

  await page.clock.fastForward(10_000);
  await expect(flash).toBeHidden();
});
