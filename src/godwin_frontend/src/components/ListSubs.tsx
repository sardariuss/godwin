import { ActorContext } from "../ActorContext";
import { Link } from "react-router-dom";

import { useEffect, useState, useContext } from "react";

type SubInfo = {
  name: string;
  num_dimensions: number;
};

function ListSubs() {
  
  const {subs, subsFetched, setSubsFetched} = useContext(ActorContext);

  const [names, setNames] = useState<Map<string, SubInfo>>(new Map());

  const fetchNames = async () => {
    let map = new Map<string, SubInfo>();
    for (const [id, actor] of subs.entries()) {
      let name = await actor.getName();
      let categories = await actor.getCategories();
      let num_dimensions = categories.length;
      map.set(id, {name, num_dimensions});
    }
    setNames(map);
	};

  useEffect(() => {
    if (subsFetched){
      fetchNames();
    }
  }, [subsFetched]);

  useEffect(() => {
    if (setSubsFetched !== undefined){
      setSubsFetched(false);
    }
  }, []);

  return (
		<>
      <div className="w-full mx-10 my-24">
        <ol className="grid grid-cols-4 gap-4">
          {
            [...Array.from(names.entries())].map((elem) => (
              <li key={elem[0]}>
                <Link to={"/g/" + elem[0]}>
                  <div className="block max-w-sm p-6 bg-white border border-gray-200 rounded-lg shadow hover:bg-gray-100 dark:bg-gray-800 dark:border-gray-700 dark:hover:bg-gray-700">
                    <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{elem[1].name}</h5>
                    <p className="font-normal text-gray-700 dark:text-gray-400">{elem[1].num_dimensions.toString() + " dimension" + (elem[1].num_dimensions > 1 ? "s" : "")}</p>
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