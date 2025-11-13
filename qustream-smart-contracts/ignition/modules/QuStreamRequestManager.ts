import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("QuStreamRequestManagerModule", (m) => {
    const contractOwner = m.getParameter("CONTRACT_OWNER");
    const masterNode = m.getParameter("MASTER_NODE");

    const quStreamRequestManager = m.contract("QuStreamRequestManager", [
        contractOwner,
        masterNode,
    ]);

    return { quStreamRequestManager };
});
