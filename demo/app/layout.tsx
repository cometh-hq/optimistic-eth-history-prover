"use client";

import { Inter } from "next/font/google";
import "./globals.css";

import { WagmiConfig, configureChains, createConfig } from "wagmi";
import { arbitrumSepolia } from "viem/chains";
import { createWeb3Modal } from "@web3modal/wagmi/react";
import { InjectedConnector } from "wagmi/connectors/injected";

import { publicProvider } from "wagmi/providers/public";

const projectId = "a7fa331cdb83855d6b7256e41d06551f";

const chains = [arbitrumSepolia];

const inter = Inter({
  subsets: ["latin"],
});

const { publicClient } = configureChains(chains, [publicProvider()]);

const wagmiConfig = createConfig({
  connectors: [
    new InjectedConnector({ chains, options: { shimDisconnect: true } }),
  ],
  publicClient,
});

// 3. Create modal
createWeb3Modal({
  wagmiConfig,
  projectId,
  chains,
  themeVariables: {
    "--w3m-accent": "#1a2f4b",
  },
});

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <WagmiConfig config={wagmiConfig}>{children}</WagmiConfig>
      </body>
    </html>
  );
}
