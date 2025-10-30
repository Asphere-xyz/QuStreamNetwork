import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("QuStreamRequestManagerModule", (m) => {
    const contractOwner = m.getParameter("CONTRACT_OWNER");
    const qustreamFeeOwner = m.getParameter("QUSTREAM_FEE_OWNER");
    const encryptionNodeFeeOwner = m.getParameter("ENCRYPTION_NODE_FEE_OWNER");
    const masterNode = m.getParameter("MASTER_NODE");
    const userFee = m.getParameter("USER_FEE");
    const qustreamFeePercentage = m.getParameter("QUSTREAM_FEE_PERCENTAGE");

    const quStreamRequestManager = m.contract("QuStreamRequestManager", [
        contractOwner,
        qustreamFeeOwner,
        encryptionNodeFeeOwner,
        masterNode,
        userFee,
        qustreamFeePercentage,
    ]);

    return { quStreamRequestManager };
});
