import UserInfo                                   from "./UserInfo";
import LinkSubProfile                             from "./LinkSubProfile";
import LedgerInfo                                 from "./LedgerInfo";
import { ActorContext }                           from "../../ActorContext"
import CONSTANTS                                  from "../../Constants";

import React, { useEffect, useState, useContext } from "react";
import { useParams       }                        from "react-router-dom";

import { Principal }                              from "@dfinity/principal";

const UserComponent = () => {

  const {user} = useParams<string>();
  
  const {subs} = useContext(ActorContext);

  const [principal, setPrincipal] = useState<Principal | undefined>(undefined);

	const refreshPrincipal = async () => {
    if (user === undefined) {
      setPrincipal(undefined);
    } else {
      let principal = Principal.fromText(user);
      setPrincipal(principal);
    }
  }

  useEffect(() => {
		refreshPrincipal();
  }, [user]);

	return (
    <div className="flex flex-col items-center">
    {
      principal === undefined ? 
        <div className="flex flex-col items-center w-full text-black dark:text-white">
          {CONSTANTS.USER_DOES_NOT_EXIST}
        </div> : 
        <div className="flex flex-col border dark:border-gray-700 text-gray-900 dark:text-white xl:w-1/3 lg:w-2/3 md:w-2/3 sm:w-full w-full">
          <UserInfo principal={principal}/>
          <LedgerInfo/>
          <ol className="flex flex-col text-black dark:text-white">
            {
              [...Array.from(subs.entries())].map((sub) => (
                <li key={sub[0]}>
                  <LinkSubProfile sub={sub} principal={principal}/>
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
