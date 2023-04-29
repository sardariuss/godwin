import { _SERVICE, Category, Polarization, Ballot } from "./../../declarations/godwin_backend/godwin_backend.did";
import { Account } from "./../../declarations/godwin_master/godwin_master.did";
import { ActorContext } from "../ActorContext"
import { Principal } from "@dfinity/principal";
import { IcrcAccount, encodeIcrcAccount } from "@dfinity/ledger";
import { arrayOfNumberToUint8Array, fromNullable } from "@dfinity/utils";
import Copy from "./Copy";

import { useEffect, useState, useContext } from "react";

import CONSTANTS from "../Constants";

import { ChartTypeEnum, toMap, toPolarizationInfo } from "../utils";

import PolarizationBar from "./base/PolarizationBar";

import { useParams } from "react-router-dom";

const UserComponent = () => {

  const {user} = useParams<string>();
  const {subs, isAuthenticated, authClient, master, token, logout} = useContext(ActorContext);

  const [principal, setPrincipal] = useState<Principal | undefined>(undefined);
  const [isLoggedUser, setIsLoggedUser] = useState<boolean>(false);

  const [userName, setUserName] = useState<string | undefined>(undefined);
  
  const [account, setAccount] = useState<Account | undefined>(undefined);

  const [balance, setBalance] = useState<bigint | undefined>(undefined);

  const [convictions, setConvictions] = useState<Map<Category, Polarization>>(new Map<Category, Polarization>());
  const [ballots, setBallots] = useState<Map<Category, [string, Ballot, number][]>>(new Map<Category, [string, Ballot, number][]>());
  const [categoryWeights, setCategoryWeights] = useState<Map<Category, number>>(new Map<Category, number>());
  const [categoryMax, setCategoryMax] = useState<number | undefined>(undefined);

	const refreshUser = async () => {
    if (user === undefined) {
      setPrincipal(undefined);
      setIsLoggedUser(false);
    } else {
      let principal = Principal.fromText(user);
      setPrincipal(principal);
      setIsLoggedUser(authClient?.getIdentity().getPrincipal().compareTo(principal) === "eq")
    }
  }

  const refreshUserName = async () => {
    if (principal === undefined) {
      setUserName(undefined);
    } else {
      let user_name = fromNullable(await master.getUserName(principal));
      setUserName(user_name === undefined ? CONSTANTS.DEFAULT_USER_NAME : user_name);
    }
  }

  const refreshConvictions = async () => {
    if (principal === undefined) {
      setConvictions(new Map<Category, Polarization>());
      setBallots(new Map<Category, [string, Ballot, number][]>());
      setCategoryWeights(new Map<Category, number>());
      setCategoryMax(undefined);
      return;
    }
   
    // @todo
    let sub = subs.get("classic6");
    if (sub === undefined){
      return;
    }

    let queryConvictions = await sub.actor.getUserConvictions(principal);
    
    if (queryConvictions[0] !== undefined) {
      setConvictions(toMap(queryConvictions[0]));
    }

    let queryOpinions = await sub.actor.getUserOpinions(principal);

    if (queryOpinions[0] !== undefined) {
      let weighted_ballots = new Map<Category, [string, Ballot, number][]>();
      let category_weights = new Map<Category, number>();

      for (let i = 0; i < queryOpinions[0].length; i++){
        let [vote_id, categorization, opinion] = queryOpinions[0][i];
        categorization.forEach(([category, polarization]) => {
          let weight = (polarization.right - polarization.left) / (polarization.left + polarization.center + polarization.right);
          category_weights.set(category, (category_weights.get(category) ?? 0) + Math.abs(weight));
          let array : [string, Ballot, number][] = weighted_ballots.get(category) ?? [];
          array.push([vote_id.toString(), opinion, weight]);
          weighted_ballots.set(category, array);
        });
      }
      setBallots(weighted_ballots);
      setCategoryWeights(category_weights);
      setCategoryMax(Math.max(...Array.from(category_weights.values())));
    }
	}

  const refreshAccount = async () => {
    if (principal === undefined || !isLoggedUser) {
      setAccount(undefined);
    } else {
      let account = await master.getUserAccount(principal);
      setAccount(account);
    }
  }

  const refreshBalance = async () => {
    if (account === undefined) {
      setBalance(undefined);
    } else {
      let balance = await token.icrc1_balance_of(account);
      setBalance(balance);
    }
  }

  const subaccountAsUint8Array = (subaccount: Uint8Array | number[] | undefined) : Uint8Array | undefined => {
    if (subaccount === undefined) {
      return undefined;
    // @todo: not sure if this is useful
    } else if (subaccount as Uint8Array) {
    return subaccount as Uint8Array;
    } else {
      return arrayOfNumberToUint8Array(subaccount as number[]);
    }
  };

  const getEncodedAccount = (account: Account) : string => {
    let icrc_account : IcrcAccount = {
      owner: account.owner,
      subaccount: subaccountAsUint8Array(fromNullable(account.subaccount))
    };
    return encodeIcrcAccount(icrc_account);
  }

  // @todo: use a timer to not update the name at each character change
  const editUserName = (name: string) => {
    master.setUserName(name);
  }

  const airdrop = () => {
    // @todo: temporary airdrop
    master.airdrop().then((result) => {;
      refreshBalance();
    });
  }

	useEffect(() => {
		refreshUser();
  }, []);

  useEffect(() => {
		refreshUser();
  }, [subs, isAuthenticated, user]);

  useEffect(() => {
    refreshConvictions();
    refreshAccount();
    refreshUserName();
  }, [principal, isLoggedUser]);

  useEffect(() => {
    refreshBalance();
  }, [account]);

	return (
    <div className="flex flex-col items-center">
    {
      principal === undefined ? 
        <div>Undefined user</div> : 
        <div className="flex flex-col border border-slate-700 my-5 w-1/3 text-gray-900 dark:text-white">
          <div className="grid grid-cols-5">
            <div className="col-start-2 col-span-3 flex flex-row justify-center">
              <svg className="w-32" xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960" fill="white"><path d="M232.001 802.923q59.923-38.461 118.922-58.961 59-20.5 129.077-20.5t129.384 20.5q59.308 20.5 119.231 58.961 43.615-50.538 64.807-106.692Q814.615 640.077 814.615 576q0-141.538-96.538-238.077Q621.538 241.385 480 241.385t-238.077 96.538Q145.385 434.462 145.385 576q0 64.077 21.5 120.231 21.5 56.154 65.116 106.692Zm247.813-204.231q-53.968 0-90.775-36.994-36.808-36.993-36.808-90.961 0-53.967 36.994-90.775 36.993-36.807 90.961-36.807 53.968 0 90.775 36.993 36.808 36.994 36.808 90.961 0 53.968-36.994 90.775-36.993 36.808-90.961 36.808Zm-.219 357.307q-78.915 0-148.39-29.77-69.475-29.769-120.878-81.576-51.403-51.808-80.864-120.802-29.462-68.994-29.462-148.351 0-78.972 29.77-148.159 29.769-69.186 81.576-120.494 51.808-51.307 120.802-81.076 68.994-29.77 148.351-29.77 78.972 0 148.159 29.77 69.186 29.769 120.494 81.076 51.307 51.308 81.076 120.654 29.77 69.345 29.77 148.233 0 79.272-29.77 148.192-29.769 68.919-81.076 120.727-51.308 51.807-120.783 81.576-69.474 29.77-148.775 29.77Z"/></svg>
              <div className="flex flex-col justify-evenly">
                {
                  // @todo: should have a minimum length, and a visual indicator if min/max is reached
                  userName !== undefined ?
                  <input className="input appearance-none" defaultValue={ userName } disabled={!isLoggedUser} onChange={(e) => editUserName(e.target.value)} maxLength={30}/>
                  :
                  <></>
                }
                {
                  account !== undefined ? 
                  <div className="flex flex-row gap-x-2">
                    <div>
                    { "Account" }
                    </div>
                    <div>
                      <Copy text={getEncodedAccount(account)}></Copy>
                    </div>
                  </div>
                   :
                  <div>
                  </div>
                }
                {
                  balance !== undefined ?
                  <div className="flex flex-row gap-x-2">
                    <div>
                    { "Balance" }
                    </div>
                    <div>
                      { balance.toString() }
                    </div>
                  </div>
                  :
                  <></>
                }
                 {
                  // @todo: should have a minimum length, and a visual indicator if min/max is reached
                  isLoggedUser ?
                  <button type="button" onClick={(e) => airdrop()} className="w-1/2 text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-blue-300 dark:focus:ring-blue-800 font-medium rounded-lg text-sm py-2.5 text-center">Airdrop</button>
                  :
                  <></>
                }
              </div>
            </div>
            <div className="col-start-5 flex justify-end self-end">
              { 
                isLoggedUser ?
                  <div onClick={logout} className="flex w-8 hover:cursor-pointer mr-2">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960" fill="white"><path d="M201.54 936q-23.529 0-40.61-17.082-17.082-17.081-17.082-40.61V293.694q0-23.529 17.082-40.611 17.081-17.082 40.61-17.082h276.384v45.384H201.54q-4.616 0-8.462 3.846-3.847 3.847-3.847 8.463v584.614q0 4.616 3.847 8.462 3.846 3.846 8.462 3.846h276.384V936H201.54Zm462.921-197.693-32.999-32.23 97.384-97.384H375.769v-45.384h351.847l-97.385-97.384 32.615-32.615 153.306 153.498-151.691 151.499Z"/></svg>
                  </div> : 
                  <></> 
              }
            </div>
          </div>
          <div className="border-y border-slate-700">
            <div className="bg-gradient-to-r from-purple-700 from-10% via-indigo-800 via-30% to-sky-600 to-90% dark:text-white font-medium border-t border-gray-600 pt-2 pb-1 text-center">
              {subs.get("classic6")?.name}
            </div>
            <div className="flex flex-col w-full">
              <ol className="w-full">
              {
                [...Array.from(convictions.entries())].map((elem, index) => (
                  (
                    <li key={elem[0]}>
                      <PolarizationBar 
                        name={elem[0]}
                        showName={true}
                        polarizationInfo={toPolarizationInfo(subs.get("classic6")?.categories[index][1], CONSTANTS.CATEGORIZATION_INFO.center)}
                        polarizationValue={elem[1]}
                        polarizationWeight={(categoryWeights.get(elem[0]) ?? 0) / (categoryMax ?? 1)}
                        ballots={ballots.get(elem[0]) ?? []}
                        chartType={ChartTypeEnum.Bar}>
                      </PolarizationBar>
                    </li>
                  )
                ))
              }
              </ol>
            </div>
          </div>
          { /*
          <div>Votes:
            <ul className="list-none">
            {
              votes.map((vote, index) => (
                <li className="list-none" key={index}>
                  Vote on question {vote[0].toString()}: {vote[1].toString()} : {getVote()}
                </li>
              ))
            }
            </ul>
          </div>
          */ }
        </div>
    }
    </div>
	);
};

export default UserComponent;
