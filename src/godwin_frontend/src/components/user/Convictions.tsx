import { VoterHistory }                                                                             from "./VoterHistory";
import ChartTypeToggle                                                                              from "../base/ChartTypeToggle";
import PolarizationBar, { BallotPoint }                                                             from "../base/PolarizationBar";
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

      let weighted_ballots = new Map<Category, BallotPoint[]>();
      let map_polarizations = new Map<Category, Polarization>();

      var total_true_weights = 0;
      var total_late_weights = 0;

      for (let i = 0; i < queryConvictions.length; i++){
        // Get the BallotConvictionInput for each vote
        let [vote_id, { cursor, date, categorization, vote_decay, late_ballot_decay }] = queryConvictions[i];

        let decay = (fromNullable(late_ballot_decay) ?? 1) * vote_decay;
        total_true_weights += decay;
        total_late_weights += fromNullable(late_ballot_decay) !== undefined ? decay : 0;

        [...Array.from(sub.info.categories)].forEach(([category, _]) => {
          let weight = toMap(categorization).get(category) ?? 0;
          // Add the weighted ballot to the ballots array
          let array : BallotPoint[] = weighted_ballots.get(category) ?? [];
          // Compute the decay
          array.push({
            label: "Vote " + vote_id.toString() + ", cursor " + cursor.toFixed(CONSTANTS.CURSOR_DECIMALS) + ", decay " + decay.toFixed(CONSTANTS.DECAY_DECIMALS),
            cursor,
            coef: weight * decay,
            date
          });
          weighted_ballots.set(category, array);
          // Compute the polarization
          let old_polarization = map_polarizations.get(category) ?? {left: 0, center: 0, right: 0};
          let new_polarization = addPolarization(old_polarization, mul(toPolarization(cursor), weight));
          map_polarizations.set(category, new_polarization);
        });
      }

      setPolarizationMap(map_polarizations);
      setBallotsMap(weighted_ballots);
      setVoteNumber(queryConvictions.length);
      setGenuineRatio((total_true_weights - total_late_weights) / total_true_weights);
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
                  <li key={category} style={{
                    filter: `sepia(` + CONSTANTS.SICK_FILTER.SEPIA_PERCENT * (1 - genuineRatio) + `%) 
                            hue-rotate(` + CONSTANTS.SICK_FILTER.HUE_ROTATE_DEG * (1 - genuineRatio) + `deg)`
                    }}>
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
            <div className="place-self-center">
            { voteNumber > 0 ? (genuineRatio * 100).toFixed(0) + "% genuine" : ""}
            </div>
          </div>
        </div>
      }
      <VoterHistory sub={sub} principal={principal} isLoggedUser={isLoggedUser} voteKind={VoteKind.OPINION} onOpinionChange={refreshConvictions} />
    </div>
	);
};

export default Convictions;
