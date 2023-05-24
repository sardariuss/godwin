import { IcrcAccount, encodeIcrcAccount } from "@dfinity/ledger";
import { arrayOfNumberToUint8Array, fromNullable } from "@dfinity/utils";
import { Account } from "./../../declarations/godwin_master/godwin_master.did";

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