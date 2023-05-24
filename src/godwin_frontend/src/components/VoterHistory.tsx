import { useState } from "react";
import { Sub } from "./../ActorContext";

import { Principal } from "@dfinity/principal";

import { VoteKind, VoteKinds, voteKindToString } from "../utils";

import { TabButton } from "./TabButton";
import { ListBallots } from "./ListBallots";

type VoterHistoryProps = {
  principal: Principal;
  sub: Sub;
};

export const VoterHistory = ({principal, sub}: VoterHistoryProps) => {

  const [voteKind, setVoteKind] = useState<VoteKind>(VoteKind.INTEREST);

  return (
    <div className="flex flex-col w-full">
      <div className="border-b dark:border-gray-700">
        <ul className="flex flex-wrap text-sm dark:text-gray-400 font-medium text-center">
        {
          VoteKinds.map((type, index) => (
            <li key={index} className="w-1/3">
              <TabButton label={voteKindToString(type)} isCurrent={type === voteKind} setIsCurrent={() => setVoteKind(type)}/>
            </li>
          ))
        }
        </ul>
      </div>
      {
        <ListBallots sub={sub} principal={principal} vote_kind={voteKind} /> 
      }
    </div>
  );
};