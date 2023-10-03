import Welcome                          from "./Welcome";
import { ActorContext, Sub }            from "../ActorContext";

import { fromNullable }                 from "@dfinity/utils";
import { Link }                         from "react-router-dom";
import React, { useEffect, useContext } from "react";

function ListSubs() {
  
  const {subs, refreshSubs, isAuthenticated} = useContext(ActorContext);

  useEffect(() => {
    if (refreshSubs !== undefined){
      refreshSubs();
    }
  }, []);

  const orderSubsByTotalVotes = (sub_1: [string, Sub], sub_2: [string, Sub]) : number => {
    let total_1 : bigint = sub_1[1].info.momentum.last_pick[0]?.total_votes || BigInt(0);
    let total_2 : bigint = sub_2[1].info.momentum.last_pick[0]?.total_votes || BigInt(0);
    return Number(total_2 - total_1);
  }

  return (
    <div>
      {
        isAuthenticated ? 
          <div className="w-full xl:p-10 lg:p-8 sm:p-6 p-4">
            <ol className="grid xl:grid-cols-4 lg:grid-cols-3 sm:grid-cols-2 grid-flow-row xl:gap-8 lg:gap-6 sm:gap-4 gap-3 w-full">
              {
                [...Array.from(subs.entries()).sort(orderSubsByTotalVotes)].map((sub) => (
                  <li key={sub[0]}>
                    <Link to={"/g/" + sub[0]}>
                      <div className="block w-full xl:lg:p-6 p-4 bg-slate-100 border rounded-lg shadow hover:bg-slate-200 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700">
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
          </div> :
          <Welcome/>
      }
    </div>
  );
}

export default ListSubs;