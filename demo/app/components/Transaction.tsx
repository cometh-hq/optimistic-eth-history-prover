"use client";

import { Icons } from "../lib/ui/components";
import React from "react";
import { PlusIcon } from "@radix-ui/react-icons";

import { useProof } from "wagmi";

export function Transaction() {
  function TransactionButton() {
    const {
      data: proof,
      isError,
      isPending,
      refetch,
    } = useProof({
      address: "0x4200000000000000000000000000000000000016",
      storageKeys: [
        "0x4a932049252365b3eedbc5190e18949f2ec11f39d3bef2d259764799a1b27d99",
      ],
    });

    const getProof = () => {
      refetch();
      console.log({ proof });
    };

    return (
      <button
        className="mt-1 flex h-11 py-2 px-4 gap-2 flex-none items-center justify-center rounded-lg bg-gray-100 hover:bg-gray-200"
        onClick={async () => getProof()}
      >
        {isPending ? (
          <Icons.spinner className="h-4 w-4 animate-spin" />
        ) : (
          <>
            <PlusIcon width={16} height={16} />
          </>
        )}{" "}
        Get Proof
      </button>
    );
  }

  return (
    <div className="relative flex items-center gap-x-6 rounded-lg p-4">
      <TransactionButton />
    </div>
  );
}
