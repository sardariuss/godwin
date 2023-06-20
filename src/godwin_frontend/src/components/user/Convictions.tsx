import { VoterHistory }                                                                             from "./VoterHistory";
import ChartTypeToggle                                                                              from "../base/ChartTypeToggle";
import PolarizationBar                                                                              from "../base/PolarizationBar";
import { Sub }                                                                                      from "../../ActorContext";
import CONSTANTS                                                                                    from "../../Constants";
import { ChartTypeEnum, toPolarizationInfo, toPolarization, mul, addPolarization, toMap, VoteKind } from "../../utils";
import { Category, Polarization, Ballot }                                                           from "../../../declarations/godwin_backend/godwin_backend.did";

import { Principal }                                                                                from "@dfinity/principal";
import { useEffect, useState }                                                                      from "react";

type ConvictionsProps = {
  principal: Principal;
  sub: Sub;
};

const Convictions = ({principal, sub} : ConvictionsProps) => {

  const [chartType, setChartType] = useState<ChartTypeEnum>(ChartTypeEnum.Bar);
  const [polarizationMap, setPolarizationMap] = useState<Map<Category, Polarization>>(new Map<Category, Polarization>());
  const [ballotsMap, setBallotsMap] = useState<Map<Category, [string, Ballot, number][]>>(new Map<Category, [string, Ballot, number][]>());
  const [voteNumber, setVoteNumber] = useState<number>(0);
  const [genuineNumber, setGenuineNumber] = useState<number>(0);

  const refreshConvictions = async () => {
    console.log("Refreshing convictions");

    if (principal === undefined) {
      setPolarizationMap(new Map<Category, Polarization>());
      setBallotsMap(new Map<Category, [string, Ballot, number][]>());
      setVoteNumber(0);
      setGenuineNumber(0);
      return;
    }

    let queryConvictions = await sub.actor.getVoterConvictions(principal);

    if (queryConvictions.length === 0) {
      return;
    };

    let weighted_ballots = new Map<Category, [string, Ballot, number][]>();
    let map_polarizations = new Map<Category, Polarization>();

    var genuine_number = 0;

    for (let i = 0; i < queryConvictions.length; i++){
      // Get the opinion and category weight from the query
      let [vote_id, [opinion, categorization, is_genuine]] = queryConvictions[i];

      genuine_number += is_genuine ? 1 : 0;

      sub.categories.forEach(([category, info]) => {
        let weight = toMap(categorization).get(category) ?? 0;
        // Add the weighted ballot to the ballots array
        let array : [string, Ballot, number][] = weighted_ballots.get(category) ?? [];
        array.push([vote_id.toString(), opinion, weight]);
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
    setGenuineNumber(genuine_number);
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
              { voteNumber.toString() + " votes" }
            </div>
            <ChartTypeToggle 
              chartType={chartType}
              setChartType={setChartType}
            />
            <div className=" place-self-center">
            { voteNumber > 0 ? (genuineNumber / voteNumber * 100).toFixed(0) + "% genuine" : ""}
            </div>
          </div>
        </div>
        <VoterHistory sub={sub} principal={principal} voteKind={VoteKind.OPINION}/>
      </div>
    </div>
	);
};

export default Convictions;
