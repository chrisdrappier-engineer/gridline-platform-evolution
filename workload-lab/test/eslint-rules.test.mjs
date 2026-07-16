import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import test from "node:test";

test("ESLint bans uncontrolled Math.random calls", () => {
  const result = spawnSync(
    "node_modules/.bin/node",
    [
      "node_modules/eslint/bin/eslint.js",
      "--no-ignore",
      "workload-lab/test/fixtures/eslint/disallowed-random.fixture.mjs"
    ],
    { encoding: "utf8" }
  );

  assert.notEqual(result.status, 0);
  assert.match(result.stdout, /Use deterministic workload seed helpers instead of Math\.random\(\)/);
});
