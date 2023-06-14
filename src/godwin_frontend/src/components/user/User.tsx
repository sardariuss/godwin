import Convictions                         from "./Convictions";
import {VoterHistory}                      from "./VoterHistory";
import {VoterQuestions}                    from "./VoterQuestions";
import Copy                                from "../Copy";
import { MainTabButton }                   from "../MainTabButton";
import SubNameBanner                       from "../SubNameBanner";
import Balance                             from "../base/Balance";
import CONSTANTS                           from "../../Constants";
import { getEncodedAccount }               from "../../utils/LedgerUtils";
import { ActorContext }                    from "../../ActorContext"
import { Account }                         from "../../../declarations/godwin_master/godwin_master.did";

import { useEffect, useState, useContext } from "react";
import { useParams }                       from "react-router-dom";

import { Principal }                       from "@dfinity/principal";
import { fromNullable }                    from "@dfinity/utils";

export enum UserFilter {
  CONVICTIONS,
  VOTES,
  QUESTIONS
};

const filters = [UserFilter.CONVICTIONS, UserFilter.VOTES, UserFilter.QUESTIONS];

const filterToText = (filter: UserFilter) => {
  switch (filter) {
    case UserFilter.CONVICTIONS:
      return "Convictions";
    case UserFilter.QUESTIONS:
      return "Questions";
    case UserFilter.VOTES:
      return "Votes";
  }
}

const UserComponent = () => {

  const {user} = useParams<string>();
  const {subs, isAuthenticated, authClient, master, logout, balance, refreshBalance} = useContext(ActorContext);

  const [principal, setPrincipal] = useState<Principal | undefined>(undefined);
  const [isLoggedUser, setIsLoggedUser] = useState<boolean>(false);
  const [userName, setUserName] = useState<string | undefined>(undefined);
  const [account, setAccount] = useState<Account | undefined>(undefined);

  const [currentUserFilter, setCurrentUserFilter] = useState<UserFilter>(UserFilter.CONVICTIONS);

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

  const refreshAccount = async () => {
    if (principal === undefined) {
      setAccount(undefined);
    } else {
      let account = await master.getUserAccount(principal);
      setAccount(account);
    }
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
  }, [subs, isAuthenticated, user]);

  useEffect(() => {
    refreshAccount();
    refreshUserName();
  }, [principal, isLoggedUser]);

  useEffect(() => {
    if (isAuthenticated) {
      refreshBalance();
    }
  }, [isAuthenticated]);

	return (
    <div className="flex flex-col items-center">
    {
      principal === undefined ? 
        <div>Undefined user</div> : 
        <div className="flex flex-col border dark:border-gray-700 my-5 w-1/3 text-gray-900 dark:text-white">
          <div className="grid grid-cols-5">
            <div className="col-start-2 col-span-3 flex flex-row justify-center dark:fill-white">
              <svg className="w-32" xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M232.001 802.923q59.923-38.461 118.922-58.961 59-20.5 129.077-20.5t129.384 20.5q59.308 20.5 119.231 58.961 43.615-50.538 64.807-106.692Q814.615 640.077 814.615 576q0-141.538-96.538-238.077Q621.538 241.385 480 241.385t-238.077 96.538Q145.385 434.462 145.385 576q0 64.077 21.5 120.231 21.5 56.154 65.116 106.692Zm247.813-204.231q-53.968 0-90.775-36.994-36.808-36.993-36.808-90.961 0-53.967 36.994-90.775 36.993-36.807 90.961-36.807 53.968 0 90.775 36.993 36.808 36.994 36.808 90.961 0 53.968-36.994 90.775-36.993 36.808-90.961 36.808Zm-.219 357.307q-78.915 0-148.39-29.77-69.475-29.769-120.878-81.576-51.403-51.808-80.864-120.802-29.462-68.994-29.462-148.351 0-78.972 29.77-148.159 29.769-69.186 81.576-120.494 51.808-51.307 120.802-81.076 68.994-29.77 148.351-29.77 78.972 0 148.159 29.77 69.186 29.769 120.494 81.076 51.307 51.308 81.076 120.654 29.77 69.345 29.77 148.233 0 79.272-29.77 148.192-29.769 68.919-81.076 120.727-51.308 51.807-120.783 81.576-69.474 29.77-148.775 29.77Z"/></svg>
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
                  isLoggedUser ? 
                  <div className="flex flex-row gap-x-2">
                    <div>
                      { "Balance: " }
                    </div>
                    <Balance amount={balance}/>
                  </div> : <></>
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
                  <button onClick={logout} className="flex w-8 hover:cursor-pointer mr-2 button-svg">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M201.54 936q-23.529 0-40.61-17.082-17.082-17.081-17.082-40.61V293.694q0-23.529 17.082-40.611 17.081-17.082 40.61-17.082h276.384v45.384H201.54q-4.616 0-8.462 3.846-3.847 3.847-3.847 8.463v584.614q0 4.616 3.847 8.462 3.846 3.846 8.462 3.846h276.384V936H201.54Zm462.921-197.693-32.999-32.23 97.384-97.384H375.769v-45.384h351.847l-97.385-97.384 32.615-32.615 153.306 153.498-151.691 151.499Z"/></svg>
                  </button> : 
                  <></> 
              }
            </div>
          </div>
          <ol>
          {
            [...Array.from(subs.entries())].map(([name, sub]) => (
              <li key={name}>
                <div className="flex flex-col w-full border-y dark:border-gray-700">
                  <SubNameBanner sub={sub}/>
                  <div className="border-b dark:border-gray-700">
                    <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center">
                    {
                      filters.map((filter, index) => (
                        <li key={index} className="w-1/3">
                          <MainTabButton label={filterToText(filter)} isCurrent={filter == currentUserFilter} setIsCurrent={() => setCurrentUserFilter(filter)}/>
                        </li>
                      ))
                    }
                    </ul>
                  </div>
                  {
                    currentUserFilter === UserFilter.CONVICTIONS ?
                      <Convictions sub={sub} principal={principal}/> :
                    currentUserFilter === UserFilter.VOTES ?
                      <VoterHistory sub={sub} principal={principal}/> :
                    currentUserFilter === UserFilter.QUESTIONS ?
                      <VoterQuestions sub={sub} principal={principal}/> :
                    <></>
                  }
                </div>
              </li>
            ))
          }
          </ol>
        </div>
    }
    </div>
	);
};

export default UserComponent;
