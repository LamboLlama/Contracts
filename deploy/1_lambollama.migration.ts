import { Deployer, Logger } from "@solarity/hardhat-migrate";
import { artifacts } from "hardhat";

const LamboLlama = artifacts.require("LamboLlama");
const EndpointMock = artifacts.require("EndpointMock");

const delegateAdr = "0x0000000000000000000000000000000000000001";

export = async (deployer: Deployer, logger: Logger) => {
  const endpoint = await deployer.deploy(EndpointMock);
  const ll = await deployer.deploy(LamboLlama, delegateAdr, delegateAdr, 100, 100, 100, delegateAdr, endpoint.address);

  logger.logContracts(["LamboLlama", ll.address]);
};
