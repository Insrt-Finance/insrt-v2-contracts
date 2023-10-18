// process-deployment.js
const { readFileSync } = require("fs");

const filePath = process.argv[2]; // Get the file path from the command line arguments

if (!filePath) {
  console.error("No file path provided.");
  process.exit(1);
}

try {
  // Read the JSON file
  const data = readFileSync(filePath, "utf8");

  // Parse the JSON
  const jsonData = JSON.parse(data);

  // Initialize an object to keep track of contracts
  const contracts = {};

  // Loop through transactions to gather contract data
  jsonData.transactions.forEach((transaction) => {
    if (!contracts[transaction.contractName]) {
      contracts[transaction.contractName] = {
        address: transaction.contractAddress,
        isDiamond: false,
      };
    }

    if (transaction.transactionType === "CALL") {
      contracts[transaction.contractName].isDiamond = true;
    }
  });

  // Log the contract information
  for (const [name, info] of Object.entries(contracts)) {
    const type = info.isDiamond ? "Diamond" : "Facet";
    console.log(`\nContract Name: ${name} (${type})`);
    console.log(`Contract Address: ${info.address}`);
  }
} catch (e) {
  console.error(`Error reading or parsing file at ${filePath}: ${e.message}`);
  process.exit(1);
}
