"use client";

import Image from "next/image";

import ConnectWallet from "./components/ConnectWallet";
import { useAccount } from "wagmi";
import { Alchemy, Network } from "alchemy-sdk";
import { useEffect, useState } from "react";
import RLP from "rlp";
import level from "level-mem";
import { BaseTrie as Trie } from "merkle-patricia-tree";
import { serializeTransaction, toHex } from "viem";
import { Button, Typography } from "@alembic/ui";
import { useContractWrite, useContractRead } from "wagmi";
import { shortenEthAddress } from "./lib/utils/utils";
import { ethers } from "ethers";

export default function Home() {
  const [currentOwner, setCurrentOwner] = useState(
    shortenEthAddress("0x5098197f5A517391Fe67A3E22bD9C3760EFA4909")
  );
  const [firstTransactionDate, setFirstTransactionDate] = useState("");
  const { isConnected, address } = useAccount();

  useEffect(() => {
    const getTxDuringEthDenver = async () => {
      const config = {
        apiKey: "CHSK86m4Q9RWyWaW6N_RB-IXHQZ663My",
        network: Network.ETH_SEPOLIA,
      };
      const alchemy = new Alchemy(config);

      const fromBlock = 5346200; // Feb-23-2024 08:35:36 AM +UTC
      const toBlock = 5387881; // Feb-29-2024 01:51:00 PM +UTC

      /* @ts-ignore */
      const firstTxdata = await alchemy.core.getAssetTransfers({
        fromBlock: fromBlock,
        toBlock: toBlock,
        fromAddress: address,
        category: ["external", "internal", "erc20", "erc721", "erc1155"],
        excludeZeroValue: false,
        maxCount: "0x1",
        order: "asc",
      });

      if (firstTxdata.transfers.length == 0) return; // todo manage the NO TX Case

      /* @ts-ignore */
      const lastTxdata = await alchemy.core.getAssetTransfers({
        fromBlock: fromBlock,
        toBlock: toBlock,
        fromAddress: address,
        category: ["external", "internal", "erc20", "erc721", "erc1155"],
        excludeZeroValue: false,
        maxCount: "0x1",
        order: "desc",
      });

      const provider = new ethers.AlchemyProvider(
        "sepolia",
        "CHSK86m4Q9RWyWaW6N_RB-IXHQZ663My"
      );
      const firstBlock = await provider.send("eth_getBlockByNumber", [
        firstTxdata.transfers[0].blockNum,
        true,
      ]);

      const lastBlock = await provider.send("eth_getBlockByNumber", [
        lastTxdata.transfers[0].blockNum,
        true,
      ]);

      const firstTransaction = firstBlock.transactions.find(
        (v: any) => v.hash === firstTxdata.transfers[0].hash
      );

      const lastTransaction = lastBlock.transactions.find(
        (v: any) => v.hash === lastTxdata.transfers[0].hash
      );

      const blocks = [firstBlock, lastBlock];
      const proofs = [];

      console.log("--Start Proof Computation--");

      for (const block of blocks) {
        const userTx = proofs.length == 0 ? firstTransaction : lastTransaction;

        console.log(
          `processing block: ${block.number} for txHash: ${userTx.hash}`
        );
        const db = level();
        const trie = new Trie(db);

        for (const tx of block.transactions) {
          const key = toHex(RLP.encode(parseInt(tx.transactionIndex, 16)));

          tx.data = tx.input;
          tx.type = parseInt(tx.type, 16);
          tx.gasLimit = tx.gas;

          tx.signature = ethers.Signature.from({
            r: tx.r,
            s: tx.s,
            v: tx.v,
          });

          const value = ethers.Transaction.from(tx).serialized;
          //console.log("txHash:", transaction.hash);
          //  console.log("value:", value);
          await trie.put(
            Buffer.from(key.slice(2), "hex"),
            Buffer.from(value.slice(2), "hex")
          );
        }

        const sKey = toHex(RLP.encode(userTx.transactionIndex));

        const proof = await Trie.createProof(
          trie,
          Buffer.from(sKey.slice(2), "hex")
        );

        const value = await Trie.verifyProof(
          trie.root,
          Buffer.from(sKey.slice(2), "hex"),
          proof
        );

        proofs.push([Buffer.from(sKey.slice(2), "hex"), proof]);

        console.log("block", block.hash, parseInt(block.number, 16));
        console.log("user tx", userTx.hash);
        console.log("PROOF");
        /*         console.log(proof.map(toHex)); */
      }

      console.log("--End Proof Computation--");

      //let date = new Date(Number(block.timestamp) * 1000);
      //setFirstTransactionDate("First tx: " + date.toDateString());
    };

    isConnected ? getTxDuringEthDenver() : setFirstTransactionDate("");
  }, [isConnected]); // Only re-run the effect if count changes

  /*  const { write } = useContractWrite({
    abi,
    address: "0x6b175474e89094c44da98b954eedeac495271d0f",
    functionName: "claim",
    args: [],
  });

  const {
    data: owner,
    isError,
    isLoading,
    refetch,
  } = useContractRead({
    address: "0xecb504d39723b0be0e3a9aa33d646642d1051ee1",
    abi,
    functionName: "ownerOf",
  }); */

  const claimNft = () => {
    //write();
  };

  /*
  const getNftOwner = () => {
    refetch();
    setCurrentOwner(owner);
  };
 */

  return (
    <main className="flex min-h-screen  flex-col items-center justify-between p-12">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex">
        <div className="flex justify-between">
          <Typography content={"Storylus"} variant="h2" />
        </div>

        <div className="fixed bottom-0 left-0 flex h-48 w-full items-end justify-center bg-gradient-to-t from-white via-white dark:from-black dark:via-black lg:static lg:h-auto lg:w-auto lg:bg-none">
          <a
            className="pointer-events-none flex place-items-center gap-2 p-8 lg:pointer-events-auto lg:p-0"
            href="https://github.com/cometh-hq/optimistic-eth-history-prover"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Image
              src={"/social/github.svg"}
              alt={"Github"}
              width={50}
              height={50}
            />
          </a>
        </div>
      </div>

      <div className="relative flex place-items-center before:absolute before:h-[300px] before:w-full sm:before:w-[480px] before:-translate-x-1/2 before:rounded-full before:bg-gradient-radial before:from-white before:to-transparent before:blur-2xl before:content-[''] after:absolute after:-z-20 after:h-[180px] after:w-full sm:after:w-[240px] after:translate-x-1/3 after:bg-gradient-conic after:from-sky-200 after:via-blue-200 after:blur-2xl after:content-[''] before:dark:bg-gradient-to-br before:dark:from-transparent before:dark:to-blue-700 before:dark:opacity-10 after:dark:from-sky-900 after:dark:via-[#0141ff] after:dark:opacity-40 before:lg:h-[360px] z-[-1]">
        <Image
          className="relative dark:drop-shadow-[0_0_0.3rem_#ffffff70] dark:invert"
          src="/logo.png"
          alt="logo"
          width={180}
          height={37}
          priority
        />
        <div>
          <div className="mb-4">
            <Typography content={"Current Owner:"} variant="h6" />
            <Typography
              content={`${currentOwner}`}
              variant="p"
              className="mb-2"
            />
          </div>

          <div>
            <Typography content={"Number of Txs:"} variant="h6" />
            <Typography content={"15"} variant="p" className="mb-2" />
          </div>
        </div>
      </div>
      <div className="flex-col justify-center items-center">
        <h2 className="mb-3 mt-3 text-xl">{firstTransactionDate}</h2>
        <ConnectWallet />

        {isConnected && (
          <div className=" flex items-center  justify-center rounded-lg p-2">
            <Button
              onClick={() => {
                claimNft();
              }}
              isPrimary={true}
              isGlass={false}
              isSecondary={false}
            >
              <Typography content="Claim OG NFT" />
            </Button>
          </div>
        )}
      </div>

      {/*       <Ranking /> */}
    </main>
  );
}
