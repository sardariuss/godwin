import Convictions                         from "./Convictions";
import { VoterHistory }                    from "./VoterHistory";
import { AuthorQuestions }                 from "./AuthorQuestions";
import UserName                            from "./UserName";
import CopyIcon                            from "../icons/CopyIcon";
import SvgButton                           from "../base/SvgButton"
import LogoutIcon                          from "../icons/LogoutIcon";
import { MainTabButton }                   from "../MainTabButton";
import SubNameBanner                       from "../SubNameBanner";
import { getEncodedAccount }               from "../../utils/LedgerUtils";
import { VoteKind }                        from "../../utils";
import { ActorContext }                    from "../../ActorContext"
import { Account }                         from "../../../declarations/godwin_master/godwin_master.did";

import { useEffect, useState, useContext } from "react";
import { useParams }                       from "react-router-dom";

import { Principal }                       from "@dfinity/principal";

export enum UserFilter {
  CONVICTIONS,
  INTERESTS,
  CATEGORIZATIONS,
  QUESTIONS
};

const filters = [UserFilter.CONVICTIONS, UserFilter.INTERESTS, UserFilter.CATEGORIZATIONS, UserFilter.QUESTIONS];

const filterToText = (filter: UserFilter) => {
  switch (filter) {
    case UserFilter.CONVICTIONS:
      return "Convictions";
    case UserFilter.INTERESTS:
      return "Interests";
    case UserFilter.CATEGORIZATIONS:
      return "Categorizations";
    case UserFilter.QUESTIONS:
      return "Questions";
  }
}

const UserComponent = () => {

  const {user} = useParams<string>();
  const {subs, isAuthenticated, authClient, master, logout, refreshBalance} = useContext(ActorContext);

  const [principal,         setPrincipal        ] = useState<Principal | undefined>(undefined             );
  const [isLoggedUser,      setIsLoggedUser     ] = useState<boolean>              (false                 );
  const [account,           setAccount          ] = useState<Account | undefined>  (undefined             );

  const [currentUserFilter, setCurrentUserFilter] = useState<UserFilter>           (UserFilter.CONVICTIONS);

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

  const refreshAccount = async () => {
    if (principal === undefined) {
      setAccount(undefined);
    } else {
      let account = await master.getUserAccount(principal);
      setAccount(account);
    }
  }

  const airdrop = () => {
    // @todo: temporary airdrop
    master.airdrop().then(() => {;
      refreshBalance();
    });
  }

  useEffect(() => {
		refreshUser();
  }, [subs, isAuthenticated, user]);

  useEffect(() => {
    refreshAccount();
  }, [principal]);

	return (
    <div className="flex flex-col items-center">
    {
      principal === undefined ? 
        <div>Undefined user</div> : 
        <div className="flex flex-col border dark:border-gray-700 my-5 w-1/3 text-gray-900 dark:text-white">
          <div className="grid grid-cols-5">
            <div className="col-start-2 col-span-3 flex flex-row justify-center dark:fill-white">
              <div className="flex w-32 h-32">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M232.001 802.923q59.923-38.461 118.922-58.961 59-20.5 129.077-20.5t129.384 20.5q59.308 20.5 119.231 58.961 43.615-50.538 64.807-106.692Q814.615 640.077 814.615 576q0-141.538-96.538-238.077Q621.538 241.385 480 241.385t-238.077 96.538Q145.385 434.462 145.385 576q0 64.077 21.5 120.231 21.5 56.154 65.116 106.692Zm247.813-204.231q-53.968 0-90.775-36.994-36.808-36.993-36.808-90.961 0-53.967 36.994-90.775 36.993-36.807 90.961-36.807 53.968 0 90.775 36.993 36.808 36.994 36.808 90.961 0 53.968-36.994 90.775-36.993 36.808-90.961 36.808Zm-.219 357.307q-78.915 0-148.39-29.77-69.475-29.769-120.878-81.576-51.403-51.808-80.864-120.802-29.462-68.994-29.462-148.351 0-78.972 29.77-148.159 29.769-69.186 81.576-120.494 51.808-51.307 120.802-81.076 68.994-29.77 148.351-29.77 78.972 0 148.159 29.77 69.186 29.769 120.494 81.076 51.307 51.308 81.076 120.654 29.77 69.345 29.77 148.233 0 79.272-29.77 148.192-29.769 68.919-81.076 120.727-51.308 51.807-120.783 81.576-69.474 29.77-148.775 29.77Z"/></svg>
              </div>
              <div className="flex flex-col mt-1 justify-evenly">
                <UserName principal={principal} isLoggedUser={isLoggedUser}/>
                {
                  account !== undefined ? 
                  <div className="flex flex-row gap-x-1 items-center">
                    <div>
                    { "Account" }
                    </div>
                    <div className="w-5 h-5">
                      <SvgButton onClick={(e) => navigator.clipboard.writeText(getEncodedAccount(account))} disabled={false} hidden={false}>
                        <CopyIcon/>
                      </SvgButton>
                    </div>
                  </div> : <></>
                }
                {
                  // @todo: should have a minimum length, and a visual indicator if min/max is reached
                  isLoggedUser ?
                  <button 
                    type="button" 
                    onClick={(e) => airdrop()} 
                    className="w-20 text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-blue-300 dark:focus:ring-blue-800 font-medium rounded-lg text-sm py-2.5 text-center">
                      Airdrop
                  </button> : <></>
                }
              </div>
            </div>
            <div className="col-start-5 flex justify-end self-end">
              { 
                isLoggedUser ?
                <div className="mr-2 w-8 h-8">
                  <SvgButton onClick={(e) => { logout(); }}>
                    <LogoutIcon/>
                  </SvgButton>
                </div> : 
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
                        <li key={index} className="w-1/4">
                          <MainTabButton label={filterToText(filter)} isCurrent={filter == currentUserFilter} setIsCurrent={() => setCurrentUserFilter(filter)}/>
                        </li>
                      ))
                    }
                    </ul>
                  </div>
                  {
                    currentUserFilter === UserFilter.CONVICTIONS ?
                      <Convictions sub={sub} principal={principal}/> :
                    currentUserFilter === UserFilter.INTERESTS ?
                      <VoterHistory sub={sub} principal={principal} voteKind={VoteKind.INTEREST}/> :
                    currentUserFilter === UserFilter.CATEGORIZATIONS ?
                      <VoterHistory sub={sub} principal={principal} voteKind={VoteKind.CATEGORIZATION}/> :
                    currentUserFilter === UserFilter.QUESTIONS ? 
                      <AuthorQuestions sub={sub} principal={principal}/> :
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
