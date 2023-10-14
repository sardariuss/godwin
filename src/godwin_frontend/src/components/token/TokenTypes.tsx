export enum TransactionKind {
  Mint,
  Burn,
  Transfer
}

export type Transaction = {
  kind: TransactionKind,
  amount: bigint,
  index: bigint,
  timestamp: bigint,
}

export enum LedgerType {
  BTC,
  GWC,
}

export enum LedgerUnit {
  ORIGINAL,
  E8S,
}