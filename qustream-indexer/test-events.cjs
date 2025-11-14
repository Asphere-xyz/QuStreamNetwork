const { ethers } = require("ethers");

const RPC_URL = "http://localhost:8800";
const GRAPHQL_URL = "http://localhost:4350/graphql";
const USER_PRIVATE_KEY =
  "0x8075991ce870b93a8870eca0c0f91913d12f47948ca0fd25b49c6fa7cdbeee8b";
const MASTER_NODE_PRIVATE_KEY =
  "0x39539ab1876910bbf3a223d84a29e28f1cb4e2e456503e7e91ed39b2e7223d68";
const CONTRACT_ADDRESS = "0xc01Ee7f10EA4aF4673cFff62710E1D7792aBa8f3";

const contractABI = [
  "event RequestRegistered(uint256 indexed id, address indexed sender, string userID, string qBlock)",
  "event RequestStatusUpdated(uint256 indexed id, uint8 status)",
  "function registerRequest(string calldata userID, string calldata qBlock) external payable returns (uint256)",
  "function processRequest(uint256 id, uint8 status) external",
  "function _masterNode() external view returns (address)",
  "function _nextRequestId() external view returns (uint256)",
];

async function queryIndexerData(requestId) {
  const query = `
    query GetRequestData {
      quStreamRequests(first: 100) {
        edges {
          node {
            id
            requestId
            sender
            userId
            qBlock
            status
            createdAtBlock
            createdAtTimestamp
            processedAtBlock
            processedAtTimestamp
          }
        }
      }
      quStreamStats(first: 1) {
        edges {
          node {
            totalRequests
            totalSuccessful
            totalFailed
            totalPending
            lastUpdatedBlock
          }
        }
      }
    }
  `;

  try {
    const response = await fetch(GRAPHQL_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        query,
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result = await response.json();

    if (result.errors) {
      console.error("GraphQL errors:", result.errors);
      return null;
    }

    // Filter by requestId in JavaScript
    const requestIdStr = requestId.toString();
    if (result.data?.quStreamRequests?.edges) {
      const matchingRequest = result.data.quStreamRequests.edges.find(
        (edge) => edge.node.requestId === requestIdStr
      );
      if (matchingRequest) {
        result.data.quStreamRequests.edges = [matchingRequest];
      } else {
        result.data.quStreamRequests.edges = [];
      }
    }

    return result.data;
  } catch (error) {
    console.error("Error querying indexer:", error.message);
    return null;
  }
}

async function displayIndexerData(requestId) {
  console.log("\n3. Querying indexer data...");
  console.log("Waiting for indexer to process events (5 seconds)...");
  await new Promise((resolve) => setTimeout(resolve, 5000));

  const data = await queryIndexerData(requestId);

  if (!data) {
    console.log(
      "⚠️  Could not fetch indexer data. Make sure the indexer is running."
    );
    return;
  }

  const request = data.quStreamRequests?.edges?.[0]?.node;
  const stats = data.quStreamStats?.edges?.[0]?.node;

  if (request) {
    console.log("\n📊 Indexed Request Data:");
    console.log("=".repeat(50));
    console.log(`ID: ${request.id}`);
    console.log(`Request ID: ${request.requestId}`);
    console.log(`Sender: ${request.sender}`);
    console.log(`User ID: ${request.userId}`);
    console.log(`QBlock: ${request.qBlock}`);
    console.log(`Status: ${request.status}`);
    console.log(`Created at Block: ${request.createdAtBlock}`);
    console.log(`Created at: ${request.createdAtTimestamp}`);
    if (request.processedAtBlock) {
      console.log(`Processed at Block: ${request.processedAtBlock}`);
      console.log(`Processed at: ${request.processedAtTimestamp}`);
    }
  } else {
    console.log(`⚠️  Request ${requestId} not found in indexer yet.`);
  }

  if (stats) {
    console.log("\n📈 QuStream Statistics:");
    console.log("=".repeat(50));
    console.log(`Total Requests: ${stats.totalRequests}`);
    console.log(`Successful: ${stats.totalSuccessful}`);
    console.log(`Failed: ${stats.totalFailed}`);
    console.log(`Pending: ${stats.totalPending}`);
    console.log(`Last Updated Block: ${stats.lastUpdatedBlock}`);
  }
}

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);

  const code = await provider.getCode(CONTRACT_ADDRESS);
  if (code === "0x") {
    console.error(`❌ No contract found at ${CONTRACT_ADDRESS}`);
    console.error("Please deploy the contract first!");
    process.exit(1);
  }

  const userWallet = new ethers.Wallet(USER_PRIVATE_KEY, provider);
  const masterWallet = new ethers.Wallet(MASTER_NODE_PRIVATE_KEY, provider);

  const contractAsUser = new ethers.Contract(
    CONTRACT_ADDRESS,
    contractABI,
    userWallet
  );
  const contractAsMaster = new ethers.Contract(
    CONTRACT_ADDRESS,
    contractABI,
    masterWallet
  );

  console.log("Testing QuStream Contract Events");
  console.log("=".repeat(50));
  console.log(`Contract: ${CONTRACT_ADDRESS}`);
  console.log(`User Wallet: ${userWallet.address}`);
  console.log(`Master Wallet: ${masterWallet.address}`);

  const masterNode = await contractAsUser._masterNode();
  console.log(`Contract Master Node: ${masterNode}`);
  console.log("");

  console.log("1. Registering request...");
  const tx1 = await contractAsUser.registerRequest(
    "test-user-123",
    "qblock-data-xyz"
  );
  console.log(`TX Hash: ${tx1.hash}`);
  const receipt1 = await tx1.wait();
  console.log(`Status: ${receipt1.status === 1 ? "Success" : "Failed"}`);
  console.log(`Block: ${receipt1.blockNumber}`);

  const logs1 = await provider.getLogs({
    address: CONTRACT_ADDRESS,
    fromBlock: receipt1.blockNumber,
    toBlock: receipt1.blockNumber,
  });
  console.log(`Logs found: ${logs1.length}`);

  const registerEvent = logs1.find((log) => {
    try {
      const parsed = contractAsUser.interface.parseLog(log);
      return parsed && parsed.name === "RequestRegistered";
    } catch {
      return false;
    }
  });

  if (!registerEvent) {
    console.log("❌ RequestRegistered event not found!");
    return;
  }

  const parsed = contractAsUser.interface.parseLog(registerEvent);
  const requestId = parsed.args.id;
  console.log(`✓ RequestRegistered`);
  console.log(`  ID: ${requestId}`);
  console.log(`  Sender: ${parsed.args.sender}`);
  console.log(`  UserID: ${parsed.args.userID}`);
  console.log(`  QBlock: ${parsed.args.qBlock}`);

  console.log("\n2. Processing request...");
  const tx2 = await contractAsMaster.processRequest(requestId, 1);
  console.log(`TX Hash: ${tx2.hash}`);
  const receipt2 = await tx2.wait();
  console.log(`Status: ${receipt2.status === 1 ? "Success" : "Failed"}`);
  console.log(`Block: ${receipt2.blockNumber}`);

  const logs2 = await provider.getLogs({
    address: CONTRACT_ADDRESS,
    fromBlock: receipt2.blockNumber,
    toBlock: receipt2.blockNumber,
  });

  const statusEvent = logs2.find((log) => {
    try {
      const parsed = contractAsMaster.interface.parseLog(log);
      return parsed && parsed.name === "RequestStatusUpdated";
    } catch {
      return false;
    }
  });

  if (statusEvent) {
    const parsedStatus = contractAsMaster.interface.parseLog(statusEvent);
    console.log(`✓ RequestStatusUpdated`);
    console.log(`  ID: ${parsedStatus.args.id}`);
    console.log(
      `  Status: ${["Pending", "Success", "Fail"][parsedStatus.args.status]}`
    );
  } else {
    console.log("❌ RequestStatusUpdated event not found!");
  }

  await displayIndexerData(requestId);

  console.log("\n" + "=".repeat(50));
  console.log("Test complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\nError:", error.message);
    process.exit(1);
  });

