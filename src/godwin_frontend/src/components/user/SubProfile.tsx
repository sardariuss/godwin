import UserInfo                                   from "./UserInfo";
import Convictions                                from "./Convictions";
import { VoterHistory }                           from "./VoterHistory";
import { OpenedVotes }                            from "./OpenedVotes";
import { MainTabButton }                          from "../MainTabButton";
import SubBanner                                  from "../SubBanner";
import { VoteKind }                               from "../../utils";
import { ActorContext, Sub }                      from "../../ActorContext"
import CONSTANTS                                  from "../../Constants";

import React, { useEffect, useState, useContext } from "react";
import { useParams }                              from "react-router-dom";

import { Principal }                              from "@dfinity/principal";

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

const SubProfile = () => {

  const {user, subgodwin} = useParams<string>();
  const {subs, authClient} = useContext(ActorContext);

  const [principal,         setPrincipal        ] = useState<Principal | undefined>(undefined);
  const [sub,               setSub              ] = useState<Sub | undefined>      (undefined);
  const [isLoggedUser,      setIsLoggedUser     ] = useState<boolean>              (false    );

  const [currentUserFilter, setCurrentUserFilter] = useState<UserFilter>           (UserFilter.CONVICTIONS);

	const refreshPrincipal = async () => {
    if (user === undefined) {
      setPrincipal(undefined);
      setIsLoggedUser(false);
    } else {
      let principal = Principal.fromText(user);
      setPrincipal(principal);
      setIsLoggedUser(authClient?.getIdentity().getPrincipal().compareTo(principal) === "eq");
    }
  }

  const refreshSub = () => {
    if (subgodwin !== undefined) {
      let sub = subs.get(subgodwin);
      if (sub !== undefined) {
        setSub(sub);
        return;
      }
    }
    setSub(undefined);
  }

  useEffect(() => {
    refreshPrincipal();
		refreshSub();
  }, [subs]);

	return (
    (
      sub === undefined ?  
        <div className="flex flex-col items-center w-full text-black dark:text-white">
          { CONSTANTS.SUB_DOES_NOT_EXIST }
        </div> : 
        <div className="flex flex-col items-center w-full">
          <SubBanner sub={sub}/>
          {
            principal === undefined ? 
              <div className="flex flex-col items-center w-full text-black dark:text-white">
                {CONSTANTS.USER_DOES_NOT_EXIST}
              </div> : 
              <div className="flex flex-col sticky xl:top-18 lg:top-16 md:top-14 top-14 border dark:border-gray-700 text-gray-900 dark:text-white xl:w-1/3 lg:w-2/3 md:w-2/3 sm:w-full w-full bg-white dark:bg-slate-900 z-20">
                <UserInfo principal={principal}/>
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
          }
          {
            principal === undefined ? 
              <div className="flex flex-col items-center w-full text-black dark:text-white">
                {CONSTANTS.USER_DOES_NOT_EXIST}
              </div> : 
              <div className="flex flex-col w-full border-x dark:border-gray-700 dark:border-gray-700 text-gray-900 dark:text-white xl:w-1/3 lg:w-2/3 md:w-2/3 sm:w-full w-full">
                {
                  currentUserFilter === UserFilter.CONVICTIONS ?
                    <Convictions sub={sub} principal={principal} isLoggedUser={isLoggedUser}/> :
                  currentUserFilter === UserFilter.INTERESTS ?
                    <VoterHistory sub={sub} principal={principal} isLoggedUser={isLoggedUser} voteKind={VoteKind.INTEREST}/> :
                  currentUserFilter === UserFilter.CATEGORIZATIONS ?
                    <VoterHistory sub={sub} principal={principal} isLoggedUser={isLoggedUser} voteKind={VoteKind.CATEGORIZATION}/> :
                  currentUserFilter === UserFilter.QUESTIONS ? 
                    <OpenedVotes sub={sub} principal={principal}/> :
                  <></>
                }
              </div>
            }
        </div>
      )
  );
};

export default SubProfile;
