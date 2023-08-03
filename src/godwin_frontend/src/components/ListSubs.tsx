import { ActorContext }                 from "../ActorContext";

import { Link }                         from "react-router-dom";
import React, { useEffect, useContext } from "react";

function ListSubs() {
  
  const {subs, refreshSubs} = useContext(ActorContext);

  useEffect(() => {
    if (refreshSubs !== undefined){
      refreshSubs();
    }
  }, []);

  return (
		<>
      <div className="w-full">
        <ol className="grid grid-cols-4 gap-4 mx-10 my-12">
          {
            [...Array.from(subs.entries())].map((sub) => (
              <li key={sub[0]}>
                <Link to={"/g/" + sub[0]}>
                  <div className="block max-w-sm p-6 bg-slate-100 border rounded-lg shadow hover:bg-slate-200 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700">
                    <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{sub[1].info.name}</h5>
                    <p className="font-normal text-gray-700 dark:text-gray-400">{sub[1].info.categories.size.toString() + " dimension" + (sub[1].info.categories.size > 1 ? "s" : "")}</p>
                  </div>
                </Link>
              </li>
            ))
          }
        </ol>
      </div>
    </>
  );
}

export default ListSubs;