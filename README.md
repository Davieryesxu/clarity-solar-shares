# Solar Panel Shares Smart Contract

A blockchain-based solution for managing shared investments in solar panel installations with automated dividend distribution.

## Features

- Add new solar panels to the system
- Purchase shares in specific panels
- Track energy generation per panel
- View ownership distribution
- Automated earnings calculation and distribution
- Smart dividend claims system
- Real-time earnings tracking
- Configurable earnings rate per kWh

## Purpose

This smart contract enables fractional ownership of solar panels, making green energy investment accessible to more people while ensuring transparent and automated management of shares and earnings. The smart dividend distribution system ensures fair and efficient allocation of earnings based on energy generation.

## How it works

1. System administrator can add new solar panels with specified number of shares and price per share
2. Investors can purchase available shares in specific panels
3. Energy generation is recorded on the blockchain
4. Earnings are automatically calculated based on energy generation and current rates
5. Investors can claim their earnings at any time
6. All transactions, ownership records, and earnings are immutably stored on the blockchain

## Benefits

- Democratizes access to solar investment
- Transparent ownership and earnings distribution
- Automated management of shares and dividends
- Immutable record of energy generation
- Real-time earnings tracking and claims
- Reduced administrative overhead
- Fair and proportional distribution of earnings
- Flexible earnings rate configuration

## Smart Dividend System

The smart dividend distribution system automatically:
- Calculates earnings based on energy generation
- Tracks earnings per kWh in real-time
- Enables proportional distribution based on share ownership
- Prevents double-claiming through blockchain verification
- Provides transparent earnings history

## Technical Details

- Earnings are calculated in micro-STX
- Default rate is set to $0.10 per kWh
- Earnings can be claimed per panel
- System prevents multiple claims for the same generation period
- Real-time tracking of cumulative investor earnings
