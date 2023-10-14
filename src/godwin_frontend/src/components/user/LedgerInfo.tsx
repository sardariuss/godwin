import NumberInput                                                               from "../NumberInput";
import TextInput                                                                 from "../TextInput";
import { TabButton }                                                             from "../TabButton";
import SubmitButton                                                              from "../SubmitButton";
import CopyIcon                                                                  from "../icons/CopyIcon";
import SvgButton                                                                 from "../base/SvgButton"
import Balance                                                                   from "../base/Balance";
import { LedgerType, LedgerUnit }                                                from "../token/TokenTypes";
import { ActorContext }                                                          from "../../ActorContext"
import { getEncodedAccount, getDecodedAccount, ledgerToString, toIdlLedgerType } from "../../utils/LedgerUtils";
import { Account, TransferResult }                                               from "./../../../declarations/godwin_master/godwin_master.did";

import { useContext, useState, useEffect }                                       from "react";
import { Principal } from "@dfinity/principal";

enum TabType {
  SEND,
  RECEIVE,
};

// @btc: create btc account from principal
const LedgerInfo = () => {

  const {btcBalance, gwcBalance, userAccount, ck_btc, token, master} = useContext(ActorContext);

  const [selectedLedger, setSelectedLedger] = useState<LedgerType | undefined>(undefined      );
  const [selectedTab,    setSelectedTab   ] = useState<TabType | undefined>   (TabType.RECEIVE);
  const [amount,         setAmount        ] = useState<number | undefined>    (undefined      );
  const [destination,    setDestination   ] = useState<string | undefined>    (undefined      );
  const [fee,            setFee           ] = useState<bigint | undefined>    (undefined      );

  const refreshFee = async () => {
    if (selectedLedger === LedgerType.BTC)
      setFee(await ck_btc?.icrc1_fee());
    else if (selectedLedger === LedgerType.GWC)
      setFee(await token?.icrc1_fee());
    else
      setFee(undefined);
  }

  const validateBalance = (balance: number) => {
    if (fee === undefined){
      throw new Error("Fee is undefined");
    }
    if (BigInt(balance * 100000000) <= fee){
      throw new Error("Invalid amount");
    }
  }

  const validateAccount = (account: string) : Account => {
    if (account === undefined || account.length === 0){
      throw new Error("Invalid account");
    }
    let decoded_account = getDecodedAccount(account);
    if (decoded_account === undefined){
      throw new Error("Invalid account");
    }
    return decoded_account;
  }

  const transfer = () : Promise<TransferResult> => {
    if (master === undefined)
      throw new Error("Master is undefined");
    if (selectedLedger === undefined)
      throw new Error("No ledger selected");
    if (amount === undefined)
      throw new Error("Amount is undefined");
    if (destination === undefined)
      throw new Error("Destination is undefined");
    validateBalance(amount);
    let to = validateAccount(destination);
    return master.cashOut(to, BigInt(amount), toIdlLedgerType(selectedLedger));
  }

  const getRandomAccount = async() => {
    if (master === undefined)
      throw new Error("Master is undefined");
    let account = await master.getUserAccount(Principal.fromText("5ljih-4dxwm-iycf6-llpzi-fja"));
    console.log(getEncodedAccount(account));
  }

  useEffect(() => {
    getRandomAccount();
    refreshFee();
  }, [selectedLedger]);

	return (
    <div>
      {
        userAccount === null || userAccount === undefined ? <></> :
        <div className="w-full flex flex-col">
          <div className="w-full flex flex-row">
            <div className={`block w-1/2 flex flex-col items-center text-black dark:text-white hover:bg-gray-200 hover:bg-gray-300 dark:hover:bg-slate-700 p-1 hover:cursor-pointer ${selectedLedger === LedgerType.BTC ? "font-bold" : ""}`}
              onClick={(e) => setSelectedLedger(selectedLedger !== LedgerType.BTC ? LedgerType.BTC : undefined)}>
              <Balance amount={ btcBalance !== null ? btcBalance : undefined } ledger_type={LedgerType.BTC} default_unit={LedgerUnit.ORIGINAL}/>
            </div>
            <div className={`block w-1/2 flex flex-col items-center text-black dark:text-white hover:bg-gray-200 hover:bg-gray-300 dark:hover:bg-slate-700 p-1 hover:cursor-pointer ${selectedLedger === LedgerType.GWC ? "font-bold" : ""}`}
              onClick={(e) => setSelectedLedger(selectedLedger !== LedgerType.GWC ? LedgerType.GWC : undefined)}>
              <Balance amount={ gwcBalance !== null ? gwcBalance : undefined } ledger_type={LedgerType.GWC} default_unit={LedgerUnit.ORIGINAL}/>
            </div>
          </div>
          {
            selectedLedger === undefined ? <></> : 
            <div className="w-full flex flex-col items-center">
              <div className="w-full flex flex-row">
                <div className="w-1/2">
                  <TabButton isCurrent={selectedTab === TabType.RECEIVE} setIsCurrent={() => { setSelectedTab(TabType.RECEIVE) }}>
                    <span>{`Receive ${ledgerToString(selectedLedger)}`}</span>
                  </TabButton>
                </div>
                <div className="w-1/2">
                  <TabButton isCurrent={selectedTab === TabType.SEND} setIsCurrent={() => { setSelectedTab(TabType.SEND) }}>
                    <span>{`Send ${ledgerToString(selectedLedger)}`}</span>
                  </TabButton>
                </div>
              </div>
              {
                selectedTab === TabType.RECEIVE ?
                  <div className="flex flex-row w-2/3 items-center py-1 gap-x-2 text-sm">
                    <div id="address">Address</div>
                    <div className="break-all">
                      {getEncodedAccount(userAccount)}
                    </div>
                    <div className="shrink-0 w-5 h-5">
                      <SvgButton onClick={(e) => navigator.clipboard.writeText(getEncodedAccount(userAccount))} disabled={false} hidden={false}>
                        <CopyIcon/>
                      </SvgButton>
                    </div>
                  </div> 
                : selectedTab === TabType.SEND ?
                  <div className="flex flex-col w-2/3 items-center space-y-3 pt-3">
                    <NumberInput 
                      id="send_amount"
                      label="Amount"
                      input={amount}
                      onInputChange={(amount) => {setAmount(amount * 100000000) }}
                      validate={(balance) => { try { validateBalance(balance); return Promise.resolve(undefined); } catch (e: any) { return Promise.resolve(e.toString()); } }}
                      precision={8}
                    />
                    <TextInput   
                      id="send_destination" 
                      label="Destination" 
                      input={destination} 
                      onInputChange={setDestination}
                      validate={(account) => { try { validateAccount(account); return Promise.resolve(undefined); } catch (e: any) { return Promise.resolve(e.toString()); } }}
                    />
                    <div className="flex flex-row space-x-1 text-sm">
                      <span>Fee (deduced from amount):</span>
                      <Balance amount={fee} ledger_type={selectedLedger} default_unit={LedgerUnit.E8S} allow_conversion={true}/>
                    </div>
                    <SubmitButton submit={transfer}>
                      <div className="text-xs flex flex-col justify-center items-center">
                        <span>{`Send ${ledgerToString(selectedLedger)}`}</span>
                      </div>
                    </SubmitButton>
                  </div> 
                : <></>
              }
            </div>
          }
        </div>
      }
    </div>
	);
};

export default LedgerInfo;
