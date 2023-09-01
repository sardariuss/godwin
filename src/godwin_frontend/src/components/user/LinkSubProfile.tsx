import { VoteKind, voteKindToCandidVariant } from "../../utils";
import { Sub }                               from "../../ActorContext";

import React, { useEffect, useState }        from "react";
import { Link }                              from "react-router-dom";

import { Principal }                         from "@dfinity/principal";

type LinkSubProfileProps = {
  principal: Principal;
  sub: [string, Sub];
};

const LinkSubProfile = ({sub, principal} : LinkSubProfileProps) => {

  const [numberVotes, setNumberVotes] = useState<bigint | undefined>(undefined);

  useEffect(() => {
    if (numberVotes === undefined){
      sub[1].actor.getNumberVotes(voteKindToCandidVariant(VoteKind.OPINION), principal).then((number) => {
          setNumberVotes(number);
      });
    }
  }, [sub, principal]);

	return (
    (
      numberVotes !== undefined ?
      <Link to={ "/g/" + sub[0] + "/user/" + principal.toString() }>
        <div className={`block w-full flex flex-row justify-between hover:bg-slate-50 hover:dark:bg-slate-850 px-5 w-full border-b dark:border-gray-700 items-center`}>
          <div className="text-lg font-bold tracking-tight text-gray-900 dark:text-white">{sub[1].info.name}</div>
          <div className="text-sm text-gray-700 dark:text-gray-400">{ numberVotes.toString() + " votes"}</div>
        </div>
      </Link> : <></>
    )
  );
};

export default LinkSubProfile;
