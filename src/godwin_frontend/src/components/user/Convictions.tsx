import { VoterHistory }                                                                             from "./VoterHistory";
import ChartTypeToggle                                                                              from "../base/ChartTypeToggle";
import PolarizationBar, { BallotPoint }                                                             from "../base/PolarizationBar";
import { Sub }                                                                                      from "../../ActorContext";
import CONSTANTS                                                                                    from "../../Constants";
import { ChartTypeEnum, toPolarizationInfo, toPolarization, mul, addPolarization, toMap, VoteKind } from "../../utils";
import { Category, Polarization }                                                                   from "../../../declarations/godwin_sub/godwin_sub.did";

import { Principal }                                                                                from "@dfinity/principal";
import { useEffect, useState }                                                                      from "react";

type ConvictionsProps = {
  principal: Principal;
  sub: Sub;
};

const Convictions = ({principal, sub} : ConvictionsProps) => {

  const [chartType,       setChartType      ] = useState<ChartTypeEnum>               (ChartTypeEnum.Bar                 );
  const [polarizationMap, setPolarizationMap] = useState<Map<Category, Polarization>> (new Map<Category, Polarization> ());
  const [ballotsMap,      setBallotsMap     ] = useState<Map<Category, BallotPoint[]>>(new Map<Category, BallotPoint[]>());
  const [voteNumber,      setVoteNumber     ] = useState<number>                      (0                                 );
  const [genuineRatio,    setGenuineRatio   ] = useState<number>                      (0                                 );

  const refreshConvictions = async () => {

    if (principal === undefined) {
      setPolarizationMap(new Map<Category, Polarization>());
      setBallotsMap(new Map<Category, BallotPoint[]>());
      setVoteNumber(0);
      setGenuineRatio(0);
      return;
    }

    let queryConvictions = await sub.actor.getVoterConvictions(principal);

    if (queryConvictions.length === 0) {
      return;
    };

    let weighted_ballots = new Map<Category, BallotPoint[]>();
    let map_polarizations = new Map<Category, Polarization>();

    var total_genuine = 0;
    var total_decay = 0;

    for (let i = 0; i < queryConvictions.length; i++){
      // Get the opinion and category weight from the query
      let [vote_id, [opinion, categorization, decay, is_genuine]] = queryConvictions[i];

      total_genuine += is_genuine ? decay : 0;
      total_decay += decay;

      sub.categories.forEach(([category, info]) => {
        let weight = toMap(categorization).get(category) ?? 0;
        // Add the weighted ballot to the ballots array
        let array : BallotPoint[] = weighted_ballots.get(category) ?? [];
        array.push({
          label: "Vote " + vote_id.toString() + ", cursor " + opinion.answer.toString() + ", decay " + decay.toString(),
          cursor: opinion.answer,
          coef: weight * decay,
          date: opinion.date
        });
        weighted_ballots.set(category, array);
        // Compute the polarization
        let old_polarization = map_polarizations.get(category) ?? {left: 0, center: 0, right: 0};
        let new_polarization = addPolarization(old_polarization, mul(toPolarization(opinion.answer), weight));
        map_polarizations.set(category, new_polarization);
      });
    }

    setPolarizationMap(map_polarizations);
    setBallotsMap(weighted_ballots);
    setVoteNumber(queryConvictions.length);
    setGenuineRatio(total_genuine / total_decay);
  }

  useEffect(() => {
    refreshConvictions();
  }, [principal, sub]);

	return (
    <div>
      <div className="flex flex-col w-full">
        <div className="flex flex-col w-full border-b dark:border-gray-700 py-1">
          <div className="flex flex-col w-full">
            <ol className="w-full">
            {
              [...Array.from(polarizationMap.entries())].map((elem, index) => (
                (
                  <li key={elem[0]}>
                    <PolarizationBar 
                      name={elem[0]}
                      showName={true}
                      polarizationInfo={toPolarizationInfo(sub.categories[index][1], CONSTANTS.CATEGORIZATION_INFO.center)}
                      polarizationValue={elem[1]}
                      ballots={ballotsMap.get(elem[0]) ?? []}
                      chartType={chartType}>
                    </PolarizationBar>
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
            <div className=" place-self-center">
            { voteNumber > 0 ? (genuineRatio / voteNumber * 100).toFixed(0) + "% genuine" : ""}
            </div>
          </div>
        </div>
        <VoterHistory sub={sub} principal={principal} voteKind={VoteKind.OPINION}/>
      </div>
    </div>
	);
};

export default Convictions;
