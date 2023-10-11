import { Transaction, TransactionKind } from "./TokenTypes";
import { Transaction as IdlTransaction } from "../../../declarations/godwin_token/godwin_token.did";
import { RedistributeBtcError, MintError, TransferError } from "../../../declarations/godwin_sub/godwin_sub.did";

import { fromNullable } from "@dfinity/utils";
import { Mint } from "../../../declarations/godwin_master/godwin_master.did";

export const frome9s = (e9s: bigint) : number => {
  return Number(e9s) / 1000000000;
}

export const transactionKindToString = (kind: TransactionKind) : string => {
  switch (kind) {
    case TransactionKind.Mint:     return "Mint";
    case TransactionKind.Burn:     return "Burn";
    case TransactionKind.Transfer: return "Transfer";
  }
}

export const transactionFromIdlType = (tx: IdlTransaction) : Transaction => {
  let kind : TransactionKind;
  let amount : bigint;
  let mint = fromNullable(tx.mint);
  let burn = fromNullable(tx.burn);
  let transfer = fromNullable(tx.transfer);
  if (mint !== undefined){
    kind = TransactionKind.Mint;
    amount = mint.amount;
  } else if (burn !== undefined){
    kind = TransactionKind.Burn;
    amount = burn.amount;
  } else if (transfer !== undefined){
    kind = TransactionKind.Transfer;
    amount = transfer.amount;
  } else {
    throw new Error("Invalid transaction");
  }
  return { kind, amount, index: tx.index, timestamp: tx.timestamp };
}

// @todo complete the strings
export const RedistributeBtcErrorToString = (err: RedistributeBtcError) : string => {
  if(err['GenericError']           !== undefined) return 'GenericError';       // { 'message' : string, 'error_code' : bigint }}
  if(err['TemporarilyUnavailable'] !== undefined) return 'TemporarilyUnavailable';
  if(err['BadBurn']                !== undefined) return 'BadBurn';            // { 'min_burn_amount' : Balance } }
  if(err['Duplicate']              !== undefined) return 'Duplicate';          // { 'duplicate_of' : TxIndex } }
  if(err['BadFee']                 !== undefined) return 'BadFee';             // { 'expected_fee' : Balance } }
  if(err['CreatedInFuture']        !== undefined) return 'CreatedInFuture';    // { 'ledger_time' : Timestamp } }
  if(err['TooOld']                 !== undefined) return 'TooOld';
  if(err['CanisterCallError']      !== undefined) return 'CanisterCallError';  // { ErrorCode }
  if(err['InsufficientFunds']      !== undefined) return 'InsufficientFunds';  // { 'balance' : Balance } 
  if(err['InvalidSumShares']       !== undefined) return 'InvalidSumShares';   
//    {
//      'owed' : Balance__1,
//      'subaccount' : Subaccount,
//      'total_owed' : Balance__1,
//      'balance_without_fees' : Balance__1,
//    }
  if(err['InsufficientFees']       !== undefined) return 'InsufficientFees';   
//    {
//      'balance' : Balance__1,
//      'sum_fees' : Balance__1,
//      'subaccount' : Subaccount,
//      'share' : number,
//    }
  throw new Error("Invalid reap account error");
}

// @todo complete the strings
export const mintErrorToString = (err: MintError) : string => {
  if(err['GenericError']           !== undefined) return 'GenericError';       // { 'message' : string, 'error_code' : bigint }}
  if(err['TemporarilyUnavailable'] !== undefined) return 'TemporarilyUnavailable';
  if(err['BadBurn']                !== undefined) return 'BadBurn';            // { 'min_burn_amount' : Balance } }
  if(err['Duplicate']              !== undefined) return 'Duplicate';          // { 'duplicate_of' : TxIndex } }
  if(err['BadFee']                 !== undefined) return 'BadFee';             // { 'expected_fee' : Balance } }
  if(err['SingleMintLost']         !== undefined) return 'SingleMintLost';     // { 'amount' : Balance__1 }
  if(err['CreatedInFuture']        !== undefined) return 'CreatedInFuture';    // { 'ledger_time' : Timestamp } }
  if(err['TooOld']                 !== undefined) return 'TooOld';
  if(err['CanisterCallError']      !== undefined) return 'CanisterCallError';  // { ErrorCode }
  if(err['InsufficientFunds']      !== undefined) return 'InsufficientFunds';  // { 'balance' : Balance }
  if(err['SingleMintError']        !== undefined) return 'SingleMintError: ' + singleMintErrorToString(err['SingleMintError']['args'], err['SingleMintError']['error']);
  throw new Error("Invalid reap account error");
}

export const singleMintErrorToString = (args: Mint, error: TransferError) : string => {
  return mintToString(args) + "\n" + transferErrorToString(error);
}

export const mintToString = (mint: Mint) : string => {
  return "amount: " + mint.amount.toString() + "\ncreated_at_time: " + mint.created_at_time.toString() + "\nmemo: " + mint.memo.toString() + "\nto: " + mint.to.toString();
}

export const transferErrorToString = (err: TransferError) : string => {
  if(err['GenericError']           !== undefined) return 'GenericError';       // { 'message' : string, 'error_code' : bigint }}
  if(err['TemporarilyUnavailable'] !== undefined) return 'TemporarilyUnavailable';
  if(err['BadBurn']                !== undefined) return 'BadBurn';            // { 'min_burn_amount' : Balance } }
  if(err['Duplicate']              !== undefined) return 'Duplicate';          // { 'duplicate_of' : TxIndex } }
  if(err['BadFee']                 !== undefined) return 'BadFee';             // { 'expected_fee' : Balance } }
  if(err['CreatedInFuture']        !== undefined) return 'CreatedInFuture';    // { 'ledger_time' : Timestamp } }
  if(err['TooOld']                 !== undefined) return 'TooOld';
  if(err['InsufficientFunds']      !== undefined) return 'InsufficientFunds';  // { 'balance' : Balance }
  throw new Error("Invalid reap account error");
}

export const subErrorToString = (err: any, main_error: string, sub_error: string) : string => {
  return sub_error + " = " + err[main_error][sub_error].toString();
}