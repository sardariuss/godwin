import { Sub }                        from "../ActorContext"
import { durationToShortString }      from "../utils";
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

  const refresh = () => {
    sub.actor.getSubInfo().then((info) => {
      let { selection_parameters, momentum } = info;
      setNumVotesOpened    (momentum.num_votes_opened                    );
      setSelectionPeriod   (selection_parameters.selection_period        );
      setLastPickDate      (fromNullable(momentum.last_pick)?.date       );
      setLastPickTotalVotes(fromNullable(momentum.last_pick)?.total_votes);
    });
  };

  useEffect(() => {
    refresh();
  }, [sub]);

  return (
    <span className="flex flex-row gap-x-1">
      <span> { numVotesOpened?.toString() + " lifetime votes"                                                           } </span>
      <span>{" · "}</span>
      <span> { "selection every " + (selectionPeriod !== undefined ? durationToShortString(selectionPeriod) : "")       } </span>
      <span>{" · "}</span>
      <span> { "last vote " + (lastPickDate !== undefined ? timeAgo(new Date(Number(lastPickDate) / 1000000)) : "none") } </span>
      <span>{" · "}</span>
      <span> { (lastPickTotalVotes !== undefined ? lastPickTotalVotes.toString() : "0") + " current users"              } </span>
    </span>
  )
}

export default Momentum;