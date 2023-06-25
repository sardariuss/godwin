import Spinner                 from "./Spinner";
import { Sub }                 from "../ActorContext"

import { useState, useEffect } from "react"

type MomentumProps = {
  sub: Sub;
}

const Momentum = ({sub} : MomentumProps) => {

  const [selectionScore, setSelectionScore] = useState<number | undefined>(undefined);

  const refreshSelectionScore= () => {
    sub.actor.getSelectionScore().then((score) => {
      setSelectionScore(score);
    });
  };

  useEffect(() => {
    refreshSelectionScore();
  }, [sub]);

  return (
    <div>
    { 
      selectionScore !== undefined ? 
      <div className="font-normal text-gray-700 dark:text-gray-400">
        { "selection score: " + selectionScore.toFixed(1) }
      </div> : 
      <div className="w-5 h-5">
        <Spinner/>
      </div>
    }
    </div>
  )
}

export default Momentum;