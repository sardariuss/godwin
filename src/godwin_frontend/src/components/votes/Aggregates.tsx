import { _SERVICE, InterestAggregate, Polarization, CategoryPolarizationTrie} from "./../../../declarations/godwin_backend/godwin_backend.did";
import ActorContext from "../../ActorContext"

import React, { useContext, useState } from "react";
import { ActorSubclass } from "@dfinity/agent";

type Props = {
  question_id: number,
  interest_aggregate: InterestAggregate,
  opinion_aggregate: Polarization,
  categorization_aggregate: CategoryPolarizationTrie
};

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

const Aggregates = ({question_id, interest_aggregate, opinion_aggregate, categorization_aggregate}: Props) => {

	const {actor, logged_in} = useContext(ActorContext) as ActorContextValues;
  
	return (
    <></>
	);
};

export default Aggregates;
