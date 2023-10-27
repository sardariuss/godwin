import { VoterHistory }                                                                             from "./VoterHistory";
import ChartTypeToggle                                                                              from "../base/ChartTypeToggle";
import PolarizationBar, { BallotPoint }                                                             from "../base/PolarizationBar";
import CertifiedIcon                                                                                from "../icons/CertifiedIcon";
import { Sub }                                                                                      from "../../ActorContext";
import CONSTANTS                                                                                    from "../../Constants";
import { ChartTypeEnum, toPolarizationInfo, toPolarization, mul, addPolarization, toMap, VoteKind } from "../../utils";
import { Category, Polarization }                                                                   from "../../../declarations/godwin_sub/godwin_sub.did";

import { fromNullable }                                                                             from "@dfinity/utils";
import { Principal }                                                                                from "@dfinity/principal";
import React, { useEffect, useState }                                                               from "react";

type ConvictionsProps = {
  sub: Sub;
  principal: Principal;
  isLoggedUser: boolean;
};

const Convictions = ({sub, principal, isLoggedUser} : ConvictionsProps) => {

  const [chartType,       setChartType      ] = useState<ChartTypeEnum>               (ChartTypeEnum.Bar                 );
  const [polarizationMap, setPolarizationMap] = useState<Map<Category, Polarization>> (new Map<Category, Polarization> ());
  const [ballotsMap,      setBallotsMap     ] = useState<Map<Category, BallotPoint[]>>(new Map<Category, BallotPoint[]>());
  const [voteNumber,      setVoteNumber     ] = useState<number>                      (0                                 );
  const [genuineRatio,    setGenuineRatio   ] = useState<number>                      (0                                 );

  const refreshConvictions = () => {

    if (principal === undefined) {
      setPolarizationMap(new Map<Category, Polarization>());
      setBallotsMap(new Map<Category, BallotPoint[]>());
      setVoteNumber(0);
      setGenuineRatio(0);
      return;
    }

    sub.actor.getVoterConvictions(principal).then((queryConvictions) => {

      if (queryConvictions.length === 0) {
        return;
      };

      let map_ballots = new Map<Category, BallotPoint[]>();
      let map_polarizations = new Map<Category, Polarization>();
      var total_vote_decay = 0;
      var total_late_decay = 0;
      
      for (let i = 0; i < queryConvictions.length; i++){
        // Get the { opinion cursor, date, categorization result, vote decay and ballot decay } 
        // associated to each opinion ballot the user gave.
        let [vote_id, { cursor, date, categorization, vote_decay, late_ballot_decay }] = queryConvictions[i];

        // Update the total decays
        // For this user, the decay associated to his ballot is the vote 
        // decay multiplied by the late ballot decay
        let decay = vote_decay * (fromNullable(late_ballot_decay) ?? 1);
        total_vote_decay += decay;
        // Add the decay to the total of late decays if the ballot is late
        total_late_decay += fromNullable(late_ballot_decay) !== undefined ? decay : 0;

        [...Array.from(sub.info.categories)].forEach(([category, _]) => {
          let coef = toMap(categorization).get(category) ?? 0;
          // Add the weighted ballot to the ballots array
          let array : BallotPoint[] = map_ballots.get(category) ?? [];
          array.push({
            label: 
              "Vote " + vote_id.toString() + 
              ", cursor " + cursor.toFixed(CONSTANTS.CURSOR_DECIMALS) + 
              ", coef " + coef.toFixed(CONSTANTS.CURSOR_DECIMALS) +
              ", decay " + decay.toFixed(CONSTANTS.DECAY_DECIMALS),
            cursor,
            coef,
            decay,
            date
          });
          map_ballots.set(category, array);
          // Compute the polarization
          let old_polarization = map_polarizations.get(category) ?? {left: 0, center: 0, right: 0};
          let new_polarization = addPolarization(old_polarization, mul(toPolarization(cursor), coef * decay));
          map_polarizations.set(category, new_polarization);
        });
      }

      setPolarizationMap(map_polarizations);
      setBallotsMap(map_ballots);
      setVoteNumber(queryConvictions.length);
      setGenuineRatio((total_vote_decay - total_late_decay) / total_vote_decay);
    });
  }

  useEffect(() => {
    refreshConvictions();
  }, [principal, sub]);

	return (
    <div className="flex flex-col w-full flex-grow">
      {
        polarizationMap.size === 0 ? <></> :
        <div className="flex flex-col w-full border-b dark:border-gray-700 py-1">
          <div className="flex flex-col w-full">
            <ol className="w-full">
            {
              [...Array.from(polarizationMap.entries())].map(([category, polarization]) => (
                (
                  <li key={category}>
                    <PolarizationBar 
                      name={category}
                      showName={true}
                      polarizationInfo={toPolarizationInfo(sub.info.categories.get(category), CONSTANTS.CATEGORIZATION_INFO.center)}
                      polarizationValue={polarization}
                      ballots={ballotsMap.get(category) ?? []}
                      chartType={chartType}/>
                  </li>
                )
              ))
            }
            </ol>
          </div>
          <div className="grid grid-cols-3 w-full items-center mt-2 text-xs font-light text-gray-400">
            <div className=" place-self-center">
              { voteNumber.toString() + " votes categorized" }
            </div>
            <ChartTypeToggle 
              chartType={chartType}
              setChartType={setChartType}
            />
            <div className="flex flex-row justify-center place-self-center" style={{filter: `grayscale(${1 - genuineRatio})`}}>
              <div className="w-4 h-4 mr-1">
                <CertifiedIcon/>
              </div>
              <span>{ voteNumber > 0 ? (genuineRatio * 100).toFixed(0) + "% genuine" : ""}</span>
            </div>
          </div>
        </div>
      }
      <VoterHistory sub={sub} principal={principal} isLoggedUser={isLoggedUser} voteKind={VoteKind.OPINION} onOpinionChange={refreshConvictions} />
    </div>
	);
};

export default Convictions;
