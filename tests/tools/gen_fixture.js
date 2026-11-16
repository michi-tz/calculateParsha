// @hebcal/core is ESM-only; this shim runs the ESM generator.
import('./gen_fixture.mjs').catch((e) => { console.error(e); process.exit(1); });
