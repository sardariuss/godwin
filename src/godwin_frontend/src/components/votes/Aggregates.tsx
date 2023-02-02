import { _SERVICE, Appeal, Polarization, PolarizationArray} from "./../../../declarations/godwin_backend/godwin_backend.did";

import PolarizationComponent from "./Polarization";

import ActorContext from "../../ActorContext"

import { useEffect, useState, useContext } from "react";
import { ActorSubclass } from "@dfinity/agent";

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

type Props = {
  interest_aggregate: Appeal | undefined,
  opinion_aggregate: Polarization | undefined,
  categorization_aggregate: PolarizationArray | undefined
};

const Aggregates = ({interest_aggregate, opinion_aggregate, categorization_aggregate}: Props) => {

  const {actor} = useContext(ActorContext) as ActorContextValues;

	return (
    <>
    <div className="flex flex-col items-center space-x-1">
      {
        interest_aggregate !== undefined ? 
        <div>{ "score: " + interest_aggregate.score } </div> : <></>
      }
      {
        opinion_aggregate !== undefined ?
          <div>opinion:
          <PolarizationComponent polarization={opinion_aggregate}/>
          </div> : <></>
      }
      {
        categorization_aggregate !== undefined ?
          categorization_aggregate.length != 0 ?
          <div>categorization:
            <ul className="list-none">
            {
              categorization_aggregate.map(([category, polarization]) => (
                <li className="list-none" key={category}>
                  <div>{category}</div>
                  <PolarizationComponent polarization={polarization}/>
                </li>
              ))
            }
            </ul>
          </div> : <></> :
        <></>
      }
    </div>
    </>
	);
};

export default Aggregates;
