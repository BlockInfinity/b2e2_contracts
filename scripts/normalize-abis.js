'use strict';

const fs = require('fs');
const path = require('path');

const BUILD_DIR = path.join(__dirname, '..', 'build');
const INPUT_DIR = path.join(BUILD_DIR, 'contracts');
const OUTPUT_DIR = path.join(BUILD_DIR, 'contracts_normalized');

function normalizeParam(param) {
  if (!param || typeof param !== 'object') return param;

  // Recursively normalize tuple components
  if (Array.isArray(param.components)) {
    param.components = param.components.map(normalizeParam);
  }

  const internalType = param.internalType;
  if (typeof internalType === 'string') {
    if (internalType.startsWith('contract ')) {
      // Contracts are encoded as addresses in the ABI
      param.type = 'address';
    } else if (internalType.startsWith('enum ')) {
      // Enums are encoded as unsigned integers; default to uint8
      // This matches typical Solidity enum ABI representation when there are few values.
      param.type = 'uint8';
    }
  }

  return param;
}

function normalizeAbi(abi) {
  if (!Array.isArray(abi)) return abi;
  return abi.map((item) => {
    if (!item || typeof item !== 'object') return item;

    if (Array.isArray(item.inputs)) {
      item.inputs = item.inputs.map(normalizeParam);
    }
    if (Array.isArray(item.outputs)) {
      item.outputs = item.outputs.map(normalizeParam);
    }

    return item;
  });
}

function main() {
  if (!fs.existsSync(INPUT_DIR)) {
    console.error(`Input contracts directory does not exist: ${INPUT_DIR}`);
    process.exit(1);
  }

  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  const files = fs.readdirSync(INPUT_DIR).filter((f) => f.endsWith('.json'));

  for (const file of files) {
    const inPath = path.join(INPUT_DIR, file);
    const outPath = path.join(OUTPUT_DIR, file);

    const raw = fs.readFileSync(inPath, 'utf8');
    const artifact = JSON.parse(raw);

    if (Array.isArray(artifact.abi)) {
      artifact.abi = normalizeAbi(artifact.abi);
    }

    fs.writeFileSync(outPath, JSON.stringify(artifact, null, 2));
  }

  console.log(`Normalized ABIs written to ${OUTPUT_DIR}`);
}

main();
