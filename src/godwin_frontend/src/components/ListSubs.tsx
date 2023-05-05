import { ActorContext } from "../ActorContext";
import { Link } from "react-router-dom";

import { useEffect, useContext } from "react";

function ListSubs() {
  
  const {subs, setSubsFetched} = useContext(ActorContext);

  useEffect(() => {
    // @todo: is it to refresh the subs list?
    if (setSubsFetched !== undefined){
      setSubsFetched(false);
    }
  }, []);

  return (
		<>
      <div className="w-full">
        <ol className="grid grid-cols-4 gap-4 mx-10 my-12">
          {
            [...Array.from(subs.entries())].map((elem) => (
              <li key={elem[0]}>
                <Link to={"/g/" + elem[0]}>
                  <div className="block max-w-sm p-6 bg-slate-100 border rounded-lg shadow hover:bg-slate-200 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700">
                    <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{elem[1].name}</h5>
                    <p className="font-normal text-gray-700 dark:text-gray-400">{elem[1].categories.length.toString() + " dimension" + (elem[1].categories.length > 1 ? "s" : "")}</p>
                    <p className="font-normal text-gray-700 dark:text-gray-400">512 active users</p>
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