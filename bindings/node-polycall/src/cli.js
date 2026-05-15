#!/usr/bin/env node

const pkg = require('../package.json');
const api = require('./index');

function printHelp() {
    console.log(`Usage: polycall <command> [options]

Commands:
  help              Show this help output
  version           Show CLI/package version
  exports           Print the exported library symbols

Options:
  -h, --help        Show this help output
  -v, --version     Show package version`);
}

function main() {
    const [command] = process.argv.slice(2);

    if (!command || command === 'help' || command === '--help' || command === '-h') {
        printHelp();
        return;
    }

    if (command === 'version' || command === '--version' || command === '-v') {
        console.log(pkg.version);
        return;
    }

    if (command === 'exports') {
        console.log(Object.keys(api).join('\n'));
        return;
    }

    console.error(`Unknown command: ${command}`);
    console.error('Run `polycall --help` for usage.');
    process.exitCode = 1;
}

main();
