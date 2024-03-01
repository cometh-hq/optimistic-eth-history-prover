"use client";

import RLP from "rlp";
import { ethers } from "ethers";
import Image from "next/image";

import ConnectWallet from "./components/ConnectWallet";
import { useAccount } from "wagmi";
import { useEffect, useState, useCallback, useMemo } from "react";
import { toHex } from "viem";
import { Button, Typography } from "@alembic/ui";
import { useContractWrite, useContractRead } from "wagmi";
import { shortenEthAddress } from "./lib/utils/utils";
import { getTxHashInBlockRange } from "./lib/utils/alchemy";
import { computeTxMerkleTrie } from "./lib/utils/trie";


const fromBlock = 5348475; // Feb-23-2024 05:00:00 PM +UTC
const toBlock = 5387881; // Feb-29-2024 01:51:00 PM +UTC

const nftAddress = "0x815Ccb32658CA148742208153C4FCEB919762828";
const claimerAddress = "0x2109514fE223CFb6ae1862c1C25EaEb47a14605B";
const historyProverAddress = "0x9DFBC5488CDE99Bfd45a541C7E04988C2c846731";

const provider = new ethers.AlchemyProvider(
  "sepolia",
  "CHSK86m4Q9RWyWaW6N_RB-IXHQZ663My"
);

const arbitrumProvider = new ethers.JsonRpcProvider(
  "https://sepolia-rollup.arbitrum.io/rpc", 421614
);

const stylusProvider = new ethers.JsonRpcProvider(
  "https://stylus-testnet.arbitrum.io/rpc", 23011913
);

export default function Home() {
  const { isConnected, address } = useAccount();
  
  const [loadingInfo, setLoadingInfo] = useState(true);
  const [currentOwner, setCurrentOwner] = useState();
  const [currentMax, setCurrentMax] = useState();

  const [loadingTxs, setLoadingTxs] = useState(false);
  const [firstTx, setFirstTx] = useState();
  const [secondTx, setSecondTx] = useState();

  const [loadingBlocks, setLoadingBlocks] = useState();

  const score = useMemo(() => {
    if (!firstTx || !secondTx) return 0;

    return secondTx.nonce - firstTx.nonce;
  }, [firstTx, secondTx])

  const canClaim = useMemo(() => {
    if (loadingInfo) return false;
    
    return score > currentMax;
  }, [loadingInfo, currentMax, score])

  useEffect(() => {
    if (!address || !address.length) return;
    setLoadingTxs(true);
  }, [address]);

  useEffect(() => {
    if (!loadingInfo) return;

    async function loadContractInfo() {
      const nftOwner32 = await arbitrumProvider.call({
        to: nftAddress,
        // ownerOf(uint256(0))
        data: "0x6352211e0000000000000000000000000000000000000000000000000000000000000000",
      });
      const nftOwner = ethers.AbiCoder.defaultAbiCoder().decode(['address'], nftOwner32);
      setCurrentOwner(nftOwner);

      const currentMax32 = await arbitrumProvider.call({
        to: claimerAddress,
        // maxTxCount()
        data: "0x211c22be",
      });
      const currentMax = ethers.AbiCoder.defaultAbiCoder().decode(['uint256'], currentMax32);
      setCurrentMax(Number(currentMax));

      setLoadingInfo(false);
    }
    loadContractInfo().catch(console.error);
  }, [loadingInfo]);

  useEffect(() => {
    if (!address || !address.length) return;
    if (!loadingTxs) return;

    async function loadTxs() {
      const [first, second] = await Promise.all([
          getTxHashInBlockRange(address, fromBlock, toBlock, 'asc'),
          getTxHashInBlockRange(address, fromBlock, toBlock, 'desc'),
      ]);

      // if first is set, second has to be set as well. So we check only first
      if (!first) {
        setLoadingTxs(false);
        return;
      }

      const [firstTxInfo, secondTxInfo] = await Promise.all([
        provider.getTransaction(first.hash),
        provider.getTransaction(second.hash),
      ]);

      setFirstTx(firstTxInfo);
      setSecondTx(secondTxInfo);
      
      setLoadingTxs(false);
    }
    loadTxs().catch(console.error);
  }, [loadingTxs, address]);

  const claimNft = useCallback(async () => {
      if (!firstTx || !secondTx) return;
      
      const [firstBlock, secondBlock, lastL3Block] = await Promise.all([
          provider.send("eth_getBlockByNumber", [ethers.toBeHex(firstTx.blockNumber), true]),
          provider.send("eth_getBlockByNumber", [ethers.toBeHex(secondTx.blockNumber), true]),
          stylusProvider.getBlock('latest'),
      ]);

      const [firstTrie, secondTrie] = await Promise.all([
        computeTxMerkleTrie(firstBlock),
        computeTxMerkleTrie(secondBlock),
      ]);

      const storageSlot = (blockNumber: number) => {
        return ethers.keccak256(
          ethers.AbiCoder.defaultAbiCoder().encode(['uint256', 'uint256'], [blockNumber, 0])
        );
      }

      const getProof = (blockNumber: number) =>
        stylusProvider.send(
          "eth_getProof",
          [historyProverAddress, [storageSlot(blockNumber)], ethers.toBeHex(lastL3Block.number)], 
        );

      const [firstProof, secondProof] = await Promise.all([
        getProof(firstBlock.number),
        getProof(secondBlock.number),
      ]);

      console.log(firstBlock.number, firstProof);
      console.log(secondBlock.number, secondProof);

  }, [firstTx, secondTx]);

/*
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

    };
  }, [isConnected]); // Only re-run the effect if count changes
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
          <div className=" flex items-center justify-center rounded-lg p-2">
            {isConnected && (loadingInfo || loadingTxs) && (
                <Button
                  isPrimary={true}
                  isGlass={false}
                  isSecondary={false}
                >
                  <Typography content="Loading..." />
                </Button>
            )}
            {isConnected && !loadingInfo && !loadingTxs && !canClaim && (
                <Button
                  isPrimary={true}
                  isGlass={false}
                  isSecondary={false}
                >
                  <Typography content="Sorry! Can't claim" />
                </Button>
            )}
            {isConnected && canClaim && (
                <Button
                  onClick={claimNft}
                  isPrimary={true}
                  isGlass={false}
                  isSecondary={false}
                >
                  <Typography content={`My score is ${score} txs! Capture the NFT !`} />
                </Button>
            )}
          </div>
        </div>
        <div>
          <div className=" mb-4">
            <Image
              className="relative"
              src="/qrcode.png"
              alt="qrcode"
              width={80}
              height={50}
              priority
            />
          </div>

          {loadingInfo ? <p>Loading</p> : 
            <div className=" text-left">
              <Typography content={`Score to beat: ${currentMax} tx`} variant="p" />
              <Typography
                content={`NFT Owner: ${shortenEthAddress(currentOwner)}`}
                variant="p"
                className="mb-2"
              />
            </div>
          }
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
