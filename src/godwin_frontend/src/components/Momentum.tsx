import { Sub }                        from "../ActorContext"
import { durationToString }           from "../utils";
import { timeAgo }                    from "../utils/DateUtils";
import { Duration }                   from "../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect } from "react"
import { fromNullable }               from "@dfinity/utils";

type MomentumProps = {
  sub: Sub;
}

const Momentum = ({sub} : MomentumProps) => {

  const [numVotesOpened,     setNumVotesOpened    ] = useState<bigint   | undefined>(undefined);
  const [selectionPeriod,    setSelectionPeriod   ] = useState<Duration | undefined>(undefined);
  const [lastPickDate,       setLastPickDate      ] = useState<bigint   | undefined>(undefined);
  const [lastPickTotalVotes, setLastPickTotalVotes] = useState<bigint   | undefined>(undefined);

  const refreshSelectionScore= () => {
    sub.actor.getSelectionParametersAndMomentum().then(([params, momentum]) => {
      setNumVotesOpened    (momentum.num_votes_opened                    );
      setSelectionPeriod   (params.selection_period                      );
      setLastPickDate      (fromNullable(momentum.last_pick)?.date       );
      setLastPickTotalVotes(fromNullable(momentum.last_pick)?.total_votes);
    });
  };

  useEffect(() => {
    refreshSelectionScore();
  }, [sub]);

  return (
    <div className="grid grid-cols-4 gap-5">
      <div> { "lifetime votes: " + numVotesOpened?.toString() } </div>
      <div> { "selection: every " + (selectionPeriod !== undefined ? durationToString(selectionPeriod) : "") } </div>
      <div> { "last vote: " + (lastPickDate !== undefined ? timeAgo(new Date(Number(lastPickDate) / 1000000)) : "none") } </div>
      <div> { "number voters: " + (lastPickTotalVotes !== undefined ? lastPickTotalVotes.toString() : "0") } </div>
    </div>
  )
}

export default Momentum;