import { User, _SERVICE, CategoryPolarizationArray} from "./../../declarations/godwin_backend/godwin_backend.did";
import ActorContext from "../ActorContext"
import PolarizationComponent from "./votes/Polarization";

import { useEffect, useState, useContext } from "react";
import { ActorSubclass, Actor, lookup_path } from "@dfinity/agent";

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

// @todo: change the state of the buttons based on the interest for the logged user for this question
const UserComponent = () => {

	const [user, setUser] = useState<User | undefined>();
  const [convictions_array, setConvictionsArray] = useState<CategoryPolarizationArray>([]);
	const {actor, logged_in} = useContext(ActorContext) as ActorContextValues;

	const refreshUser = async () => {
    let principal = await Actor.agentOf(actor)?.getPrincipal();
    if (principal !== undefined){
      let query_user = await actor.findUser(principal);
		  setUser(query_user[0]);
    }
	}

  const toArray = async () => {
    if (user !== undefined) {
      const array = await actor.polarizationTrieToArray(user.convictions);
      setConvictionsArray(array);
    }
  }

	useEffect(() => {
		refreshUser();
  }, []);

  useEffect(() => {
		refreshUser();
  }, [logged_in]);

  useEffect(() => {
    toArray();
  }, [user]);

	return (
		<div className="border border-none mx-96 my-16 justify-center text-gray-900 dark:text-white">
      <div>Principal: {user?.principal.toString()}</div>
      <div>User name: {user?.name[0]}</div>
      <div>Convictions:
        <ul className="list-none">
        {
          convictions_array.map(([category, polarization]) => (
            <li className="list-none" key={category}>
              <div>{category}</div>
              <PolarizationComponent polarization={polarization}/>
            </li>
          ))
        }
        </ul>
      </div>
		</div>
	);
};

export default UserComponent;
