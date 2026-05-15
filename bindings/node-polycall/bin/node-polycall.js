#!/usr/bin/env node

const path = require('path');
const packageJson = require(path.resolve(__dirname, '..', 'package.json'));

let polycall;
try {
    polycall = require('../src/index.js');
} catch (error) {
    polycall = require('../index.js');
}

const USAGE = `node-polycall ${packageJson.version}

Usage:
  node-polycall [command]
  node-polycall --help
  node-polycall --version

Commands:
  info       Show exported API names and protocol constants summary.

Notes:
  The CLI surface is intentionally minimal and stable for now.
  Use the JavaScript API for advanced workflows.`;

function printUsage() {
    console.log(USAGE);
}

function printVersion() {
    console.log(packageJson.version);
}

function runInfo() {
    const exportNames = Object.keys(polycall).sort();
    const messageTypeCount = polycall.MESSAGE_TYPES ? Object.keys(polycall.MESSAGE_TYPES).length : 0;
    const protocolFlagCount = polycall.PROTOCOL_FLAGS ? Object.keys(polycall.PROTOCOL_FLAGS).length : 0;

    console.log('node-polycall API summary');
    console.log(`Exports (${exportNames.length}): ${exportNames.join(', ')}`);
    console.log(`MESSAGE_TYPES: ${messageTypeCount}`);
    console.log(`PROTOCOL_FLAGS: ${protocolFlagCount}`);
}

function main(argv) {
    const args = argv.slice(2);
    const [command] = args;

    if (!command || command === 'info') {
        runInfo();
        return 0;
    }

    if (command === '--help' || command === '-h' || command === 'help') {
        printUsage();
        return 0;
    }

    if (command === '--version' || command === '-v' || command === 'version') {
        printVersion();
        return 0;
    }

    console.error(`Unknown command: ${command}`);
    console.error('Run `node-polycall --help` for usage.');
    return 1;
}

process.exitCode = main(process.argv);
const pkg = require('../package.json');

console.log(`${pkg.name} v${pkg.version}`);
console.log('CLI scaffolding is set up. Add command handlers in bin/node-polycall.js.');
