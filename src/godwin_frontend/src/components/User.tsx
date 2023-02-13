import { _SERVICE, PolarizationArray, Ballot } from "./../../declarations/godwin_backend/godwin_backend.did";
import { ActorContext } from "../ActorContext"
import PolarizationComponent from "./votes/Polarization";

import { useEffect, useState, useContext } from "react";
import { Actor } from "@dfinity/agent";

import { useNavigate } from "react-router-dom";

// @todo: change the state of the buttons based on the interest for the logged user for this question
const UserComponent = () => {

  const [convictions, setConvictions] = useState<PolarizationArray>([]);
  const [votes, setVotes] = useState<Ballot[]>([]); // @todo
	const {actor, isAuthenticated, logout} = useContext(ActorContext);

  const navigate = useNavigate();

	const refreshUser = async () => {
    let principal = await Actor.agentOf(actor)?.getPrincipal();
    if (principal !== undefined){
      let queryConvictions = await actor.getUserConvictions(principal);
      if (queryConvictions['ok'] !== undefined) {
        setConvictions(queryConvictions['ok']);
      };
      let queryVotes = await actor.getUserVotes(principal);
      if (queryVotes['ok'] !== undefined) {
        setVotes(queryVotes['ok']);
      }
    }
	}

	useEffect(() => {
		refreshUser();
  }, []);

  useEffect(() => {
		refreshUser();
  }, [isAuthenticated]);

	return (
		<div className="border border-none mx-96 my-16 justify-center text-gray-900 dark:text-white">
      <div>Convictions:
        <ul className="list-none">
        {
          convictions.map(([category, polarization]) => (
            <li className="list-none" key={category}>
              <div>{category}</div>
              <PolarizationComponent polarization={polarization}/>
            </li>
          ))
        }
        </ul>
      </div>
      <div>
        { isAuthenticated ? 
          <button type="button" onClick={logout} className="text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-blue-300 dark:focus:ring-blue-800 font-medium rounded-lg text-sm px-5 py-2.5 text-center mr-2 mb-2">
            Log out
          </button> : 
          <>
          </> 
        }
      </div>
		</div>
	);
};

export default UserComponent;
