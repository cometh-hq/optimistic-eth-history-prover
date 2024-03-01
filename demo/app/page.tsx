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
    <main className="flex min-h-screen  flex-col items-center justify-start text-center p-10">
      <div className="flex flex-col justify-center items-center ">
        <Image
          className="mb-2"
          src="/EthDenver.png"
          alt="EthDenver"
          width={120}
          height={120}
        />
      </div>
      <Typography content={"Storylus Demo"} variant="h2" className="mb-4" />

      <Typography
        content={"Are you the most active dev on Sepolia during Eth Denver?"}
        variant="p"
        className="mb-6"
      />

      <div className=" flex place-items-center before:lg:h-[260px]  mb-6">
        <div className="flex flex-col items-center justify-center mr-4">
          <Image
            className="relative mb-4 outline: 1px solid #1a2f4b"
            src="/nft/storylus-demo-nft.png"
            alt="storylus-demo-nft"
            width={250}
            height={100}
            priority
            style={{
              border: "0.25px solid #825dc8",
            }}
          />
          <ConnectWallet />
          {isConnected && (
            <div className=" flex items-center justify-center rounded-lg p-2">
              <Button
                onClick={() => {
                  claimNft();
                }}
                isPrimary={true}
                isGlass={false}
                isSecondary={false}
              >
                <Typography content="Capture this unique NFT !" />
              </Button>
            </div>
          )}
        </div>
        <div>
          <div className=" mb-4">
            <Image
              className="relative "
              src="/qrcode.png"
              alt="qrcode"
              width={80}
              height={50}
              priority
            />
          </div>

          <div className=" text-left">
            <Typography content={`Score to beat: ${"65 txs"}`} variant="p" />
            <Typography
              content={`NFT Owner: ${shortenEthAddress(
                "0x39946fd82c9c86c9a61bceed86fbdd284590bdd9"
              )}`}
              variant="p"
              className="mb-2"
            />
          </div>
        </div>
      </div>
      <div className="w-full md:w-1/2 flex flex-col justify-center items-center text-center mt-4">
        <div className="flex  mb-6 text-center justify-center items-center">
          <Typography
            content={
              "The NFT is transferred only if an address proves on-chain that it has made more transactions than the current owner between feb 23 - 10am (Block 5348475) to feb 29 - 8am (Block 5387881)"
            }
            variant="p"
          />
        </div>
        <div className="flex text-center justify-center items-center">
          <a
            className="pointer-events-none flex place-items-center gap-2 p-8 lg:pointer-events-auto lg:p-0"
            href="https://github.com/cometh-hq/optimistic-eth-history-prover"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Image
              src={"/social/github.svg"}
              alt={"Github"}
              width={30}
              height={30}
            />

            <Typography
              content={"How does it work? Check the codebase"}
              variant="p"
              className="underline"
            />
          </a>
        </div>
      </div>
    </main>
  );
}
