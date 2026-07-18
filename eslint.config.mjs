const commonGlobals = {
  clearTimeout: "readonly",
  clearInterval: "readonly",
  console: "readonly",
  process: "readonly",
  setTimeout: "readonly",
  setInterval: "readonly",
  URL: "readonly"
};

export default [
  {
    ignores: ["workload-lab/test/fixtures/eslint/**"]
  },
  {
    files: ["workload-lab/**/*.mjs"],
    ignores: ["workload-lab/archive/**"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: commonGlobals
    },
    rules: {
      "array-callback-return": "error",
      eqeqeq: ["error", "always"],
      "no-constant-binary-expression": "error",
      "no-duplicate-imports": "error",
      "no-else-return": "error",
      "no-implicit-coercion": "error",
      "no-restricted-syntax": [
        "error",
        {
          selector: "CallExpression[callee.object.name='Math'][callee.property.name='random']",
          message: "Use deterministic workload seed helpers instead of Math.random()."
        }
      ],
      "no-template-curly-in-string": "error",
      "no-undef": "error",
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "prefer-const": "error"
    }
  },
  {
    files: ["workload-lab/scenarios/**/*.mjs"],
    languageOptions: {
      globals: {
        ...commonGlobals,
        __ENV: "readonly",
        __ITER: "readonly",
        __VU: "readonly",
        open: "readonly"
      }
    }
  },
  {
    files: ["workload-lab/dashboard/app.mjs"],
    languageOptions: {
      globals: {
        ...commonGlobals,
        document: "readonly",
        EventSource: "readonly",
        fetch: "readonly",
        window: "readonly",
        Intl: "readonly"
      }
    }
  }
];
