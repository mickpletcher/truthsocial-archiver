import { spawnSync } from 'node:child_process';

const allowedAdvisories = new Map([
  [
    'GHSA-5p2g-fcmc-qvqq',
    'image-size has no patched npm release; Electron Forge uses it only while building macOS disk images from repository-controlled inputs.'
  ],
  [
    'GHSA-jmr9-qjv8-65gv',
    'extract-zip has no patched npm release; Electron Packager uses it to unpack the pinned Electron distribution during trusted builds.'
  ],
  [
    'GHSA-w3rx-r6r6-pgpr',
    'image-size has no patched npm release; Electron Forge uses it only while building macOS disk images from repository-controlled inputs.'
  ]
]);

const npmCli = process.env.npm_execpath;
const command = npmCli ? process.execPath : process.platform === 'win32' ? 'npm.cmd' : 'npm';
const args = npmCli ? [npmCli, 'audit', '--json'] : ['audit', '--json'];
const result = spawnSync(command, args, {
  encoding: 'utf8',
  maxBuffer: 20 * 1024 * 1024
});

if (result.error || !result.stdout) {
  process.stderr.write(`${result.error?.message || result.stderr || 'npm audit returned no output.'}\n`);
  process.exit(1);
}

let audit;
try {
  audit = JSON.parse(result.stdout);
}
catch {
  process.stderr.write('npm audit returned invalid JSON.\n');
  process.exit(1);
}

if (audit.error) {
  process.stderr.write(`${audit.error.summary || audit.error.message || 'npm audit failed.'}\n`);
  process.exit(1);
}

const findings = new Map();
for (const vulnerability of Object.values(audit.vulnerabilities || {})) {
  for (const advisory of vulnerability.via || []) {
    if (typeof advisory === 'string' || !['high', 'critical'].includes(advisory.severity)) {
      continue;
    }

    const id = advisory.url?.split('/').pop();
    if (id) {
      findings.set(id, advisory);
    }
  }
}

const blocking = [...findings.entries()].filter(([id]) => !allowedAdvisories.has(id));
const staleAllowlist = [...allowedAdvisories.keys()].filter(id => !findings.has(id));

for (const [id, advisory] of findings) {
  if (allowedAdvisories.has(id)) {
    process.stdout.write(`Allowed upstream advisory ${id}: ${advisory.title}\n`);
    process.stdout.write(`${allowedAdvisories.get(id)}\n`);
  }
}

if (blocking.length) {
  for (const [id, advisory] of blocking) {
    process.stderr.write(`Blocking ${advisory.severity} advisory ${id}: ${advisory.title}\n`);
  }
  process.exit(1);
}

if (staleAllowlist.length) {
  process.stderr.write(`Remove resolved audit allowlist entries: ${staleAllowlist.join(', ')}\n`);
  process.exit(1);
}

const totals = audit.metadata?.vulnerabilities || {};
process.stdout.write(
  `Dependency audit accepted ${findings.size} documented upstream advisories and found no other high or critical advisories. ` +
  `npm reported ${totals.total || 0} affected dependency paths.\n`
);
