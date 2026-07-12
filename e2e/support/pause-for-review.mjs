const reviewPauseMs = Number.parseInt(process.env.E2E_REVIEW_PAUSE_MS || "1000", 10);

export async function pauseForReview(page) {
  if (reviewPauseMs > 0) {
    await page.waitForTimeout(reviewPauseMs);
  }
}
