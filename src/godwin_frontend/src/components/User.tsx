import { _SERVICE, PolarizationArray, Ballot } from "./../../declarations/godwin_backend/godwin_backend.did";
import { ActorContext } from "../ActorContext"
import { Principal } from "@dfinity/principal";
import PolarizationComponent from "./votes/Polarization";

import { useEffect, useState, useContext } from "react";

import { useNavigate } from "react-router-dom";

// @todo: change the state of the buttons based on the interest for the logged user for this question
// @todo: fix
const UserComponent = () => {

  const [convictions, setConvictions] = useState<PolarizationArray>([]);
  const [votes, setVotes] = useState<[bigint, bigint][]>([]);
  const [votes2, setVotes2] = useState<[Ballot | undefined][]>([]);
	const {actor, isAuthenticated, logout} = useContext(ActorContext);

  const navigate = useNavigate();

	const refreshUser = async () => {
    //let principal = await Actor.agentOf(actor)?.getPrincipal();
    // @todo
    let principal = Principal.fromText("crxri-e7kai-wzyt5-uqxrb-kqy");
    if (principal !== undefined){
      let queryConvictions = await actor.getUserConvictions(principal);
      if (queryConvictions['ok'] !== undefined) {
        setConvictions(queryConvictions['ok']);
      };
      let queryVotes = await actor.getUserVotes(principal);
      let votes = queryVotes['ok'];
      if (votes !== undefined) {
        setVotes(queryVotes['ok']);
        for (let i = 0; i < votes.length; i++) {
          let ballot = await actor.getOpinionBallot(principal, votes[i][0], votes[i][1]);
          if (ballot['ok'] !== undefined) {
            setVotes2([...votes2, ballot['ok']]);
          } else {
            setVotes2([]);
          }
        };
      }
    }
	}

  const getVote = () => {
    return "@todo";
  };

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
      <div>Votes:
        <ul className="list-none">
        {
          votes.map((vote, index) => (
            <li className="list-none" key={index}>
              Vote on question {vote[0].toString()}: {vote[1].toString()} : {getVote()}
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
