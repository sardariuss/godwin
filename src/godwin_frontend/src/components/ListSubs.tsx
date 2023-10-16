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
        <li key="create_new" className="flex flex-row w-full items-center justify-center">
          <Link className="group/new block w-full flex flex-row items-center justify-center xl:lg:py-14 p-12 xl:lg:px-6 px-4 border dark:border-gray-700 shadow rounded-lg bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:bg-gradient-to-br" to={"/newsub"}>
            <div className="fill-gray-200 group-hover/new:fill-white w-12 h-12">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M440-280h80v-160h160v-80H520v-160h-80v160H280v80h160v160Zm40 200q-83 0-156-31.5T197-197q-54-54-85.5-127T80-480q0-83 31.5-156T197-763q54-54 127-85.5T480-880q83 0 156 31.5T763-763q54 54 85.5 127T880-480q0 83-31.5 156T763-197q-54 54-127 85.5T480-80Zm0-80q134 0 227-93t93-227q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93Zm0-320Z"/></svg>
            </div>
            <span className="text-gray-200 group-hover/new:text-white text-xl">Create new sub</span>
          </Link>
        </li>
      </ol>
    </div>
  );
}

export default ListSubs;