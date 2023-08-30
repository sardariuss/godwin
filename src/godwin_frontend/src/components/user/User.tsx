import UserInfo                                   from "./UserInfo";
import { ActorContext }                           from "../../ActorContext"
import CONSTANTS                                  from "../../Constants";

import React, { useEffect, useState, useContext } from "react";
import { useParams, Link }                        from "react-router-dom";

import { Principal }                              from "@dfinity/principal";
import { fromNullable }                           from "@dfinity/utils";

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
          <ol className="flex flex-col text-black dark:text-white">
            {
              [...Array.from(subs.entries())].map((sub, index) => (
                <li key={sub[0]}>
                  <Link to={ "/g/" + sub[0] + "/user/" + user }>
                    <div className={`block w-full flex flex-col hover:bg-slate-50 hover:dark:bg-slate-850 px-5 w-full ${index < (subs.size - 1) ? "border-b dark:border-gray-700" : "" }` }>
                      <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{sub[1].info.name}</h5>
                      <p className="font-normal text-gray-700 dark:text-gray-400">{sub[1].info.categories.size.toString() + " dimension" + (sub[1].info.categories.size > 1 ? "s" : "")}</p>
                      <p className="font-normal text-gray-700 dark:text-gray-400"> { sub[1].info.momentum.num_votes_opened.toString() + " lifetime votes"} </p>
                      <p className="font-normal text-gray-700 dark:text-gray-400"> { fromNullable(sub[1].info.momentum.last_pick)?.total_votes.toString() + " users"} </p>
                    </div>
                  </Link>
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
