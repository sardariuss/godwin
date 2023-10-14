import { LedgerType, LedgerUnit }                              from "../components/token/TokenTypes";
import { Account, LedgerType as IdlLedgerType }                from "./../../declarations/godwin_master/godwin_master.did";

import { IcrcAccount, encodeIcrcAccount, decodeIcrcAccount }   from "@dfinity/ledger";
import { arrayOfNumberToUint8Array, fromNullable, toNullable } from "@dfinity/utils";
import { Principal }                                           from "@dfinity/principal";

export const subaccountAsUint8Array = (subaccount: Uint8Array | number[] | undefined) : Uint8Array | undefined => {
  if (subaccount === undefined) {
    return undefined;
  // @todo: not sure if this is useful
  } else if (subaccount as Uint8Array) {
  return subaccount as Uint8Array;
  } else {
    return arrayOfNumberToUint8Array(subaccount as number[]);
  }
};

export const getEncodedAccount = (account: Account) : string => {
  let icrc_account : IcrcAccount = {
    owner: account.owner,
    subaccount: subaccountAsUint8Array(fromNullable(account.subaccount))
  };
  return encodeIcrcAccount(icrc_account);
}

export const getDecodedAccount = (encoded_account: string) : Account | undefined => {
  try {
    let icrc_account = decodeIcrcAccount(encoded_account);
    return {
      owner: icrc_account.owner,
      subaccount: toNullable(icrc_account.subaccount)
    };
  } catch (e) {
    return undefined;
  }
}

export const principalToSubaccount = (principal: Principal) : Uint8Array => {
  // Convert the principal to a Uint8Array
  let byte_array = principal.toUint8Array();
  // Add zeros until 32 bytes
  let subaccount = new Uint8Array(32);
  subaccount.set(byte_array);
  return subaccount;
}

export const ledgerToString = (ledger: LedgerType) : string => {
  switch (ledger) {
    case LedgerType.BTC: return "BTC";
    case LedgerType.GWC: return "GWC";
  }
}

export const ledgerToTokenUnit = (ledger: LedgerType, unit: LedgerUnit) : string => {
  switch (ledger) {
    case LedgerType.BTC: return unit === LedgerUnit.ORIGINAL ? "BTC" : "sat";
    case LedgerType.GWC: return unit === LedgerUnit.ORIGINAL ? "GWC" : "sig";
  }
}

export const balanceToString = (balance: bigint | undefined, unit: LedgerUnit) : string => {
  var actual_balance = 0.0;
  if (balance !== undefined) {
    let divisor = unit === LedgerUnit.ORIGINAL ? 100000000 : 1;
    actual_balance = Number(balance) / divisor;
  }
  if (unit === LedgerUnit.ORIGINAL){
    return actual_balance.toFixed(5);
  } else {
    return actual_balance.toFixed(0);
  }
}

export const toIdlLedgerType = (ledger: LedgerType) : IdlLedgerType => {
  switch (ledger) {
    case LedgerType.BTC: return { 'BTC' : null };
    case LedgerType.GWC: return { 'GWC' : null };
  }
}
