import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      { version: "0.4.10" },
      { version: "0.4.15" },
      { version: "0.8.18" },
      { version: "0.8.17" },
    ],
  },
  networks: {
    local: { url: "http://127.0.0.1:8545" },
    hardhat: {
      mining: { auto: true, interval: 1000 },
    },
    gnd_dev: {
      url: process.env.GND_DEV_END_POINT || "",
      accounts: [
        process.env.GND_DEV_PK1 || "",
        process.env.GND_DEV_PK2 || "",
        process.env.GND_DEV_PK3 || "",
      ],
      gasPrice: 800 * 10 ** 9,
    },
    ganache: {
      url: "http://127.0.0.1:7545",
      accounts: [
        process.env.GANACHE_PK1 || "",
        process.env.GANACHE_PK2 || "",
        // process.env.GANACHE_PK3 || "",
      ],
    },
  },
  // paths: { artifacts: "./app/src/artifacts" },
};

const { subtask } = require("hardhat/config");
const { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } = require("hardhat/builtin-tasks/task-names");

// ignore compiling
subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(
  async (_: any, __: any, runSuper: any) => {
    const paths = await runSuper();

    return paths.filter((p: string) => !p.endsWith(".t.sol"));
  }
);

export default config;
