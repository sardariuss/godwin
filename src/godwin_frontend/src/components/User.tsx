import { _SERVICE, Category, Polarization } from "./../../declarations/godwin_backend/godwin_backend.did";
import { ActorContext } from "../ActorContext"
import { CategoriesContext } from "../CategoriesContext"
import { Principal } from "@dfinity/principal";

import { useEffect, useState, useContext } from "react";

import CONSTANTS from "../Constants";

import { toMap, toPolarizationInfo } from "../utils";

import PolarizationBar from "./base/PolarizationBar";

import { useNavigate } from "react-router-dom";

const UserComponent = () => {

  const {actor, isAuthenticated, logout} = useContext(ActorContext);
  const {categories} = useContext(CategoriesContext);

  const [convictions, setConvictions] = useState<Map<Category, Polarization>>(new Map<Category, Polarization>());

  // @todo: what's that for ?
	const navigate = useNavigate();

	const refreshUser = async () => {
    //let principal = await Actor.agentOf(actor)?.getPrincipal();
    let principal = Principal.fromText("yemm7-ghigm-an6n6-oph44-tpi");
    if (principal !== undefined){
      let queryConvictions = await actor.getUserConvictions(principal);
      if (queryConvictions[0] !== undefined) {
        setConvictions(toMap(queryConvictions[0]));
      }
//      let queryVotes = await actor.getUserVotes(principal);
//      let votes = queryVotes['ok'];
//      if (votes !== undefined) {
//        setVotes(queryVotes['ok']);
//        for (let i = 0; i < votes.length; i++) {
//          let ballot = await actor.getOpinionBallot(principal, votes[i][0], votes[i][1]);
//          if (ballot['ok'] !== undefined) {
//            setVotes([...votes2, ballot['ok']]);
//          } else {
//            setVotes([]);
//          }
//        };
//      }
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
        <ol>
        {
          [...Array.from(categories.entries())].map((elem) => (
            convictions.get(elem[0]) !== undefined ? (
              <li key={elem[0]}>
                <PolarizationBar name={elem[0]} showName={true} polarizationInfo={toPolarizationInfo(elem[1], CONSTANTS.CATEGORIZATION_INFO.center)} polarizationValue={convictions.get(elem[0])}></PolarizationBar>
              </li>
            ) : (
              <li key={elem[0]}>Error: missing category</li>
            )
          ))
        }
        </ol>
      </div>
      { /*
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
      */ }
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
