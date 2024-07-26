#! /usr/bin/env node

const { execSync } = require('child_process');
const ttf2woff2 = require('ttf2woff2');
const fs = require('fs');

// Thanks to https://www.fiveoutofnine.com/blog/on-chain-font for the tip!

const charsToKeep = Array.from(new Set("OCWebsite web3://0x0123456789abcdef:ghijklmnopqrstuvwxyz-"));
const unicodes = charsToKeep.map(char => `U+${char.charCodeAt(0).toString(16).padStart(4, '0').toUpperCase()}`).join(',')

// Run the pyftsubset command to generate a subset of the font
const command = 'pyftsubset ../assets/IBMPlexMono-Regular.ttf --unicodes=' + unicodes + ' --output-file=../assets/IBMPlexMono-Regular-subset.ttf';
try {
  execSync(command);
  console.log(`Font subset generated successfully.`);
} catch (error) {
  console.error(`Error: ${error.message}`);
}

// Use ttf2woff2 to convert the subset to WOFF2
const ttfData = fs.readFileSync('../assets/IBMPlexMono-Regular-subset.ttf');
const woff2Data = ttf2woff2(ttfData);
fs.writeFileSync('../assets/IBMPlexMono-Regular-subset.woff2', woff2Data);
console.log(`Font subset converted to WOFF2 successfully.`);