import MainQuestions from "./MainQuestions";
import { ActorContext, Sub } from "../ActorContext"

import { useContext } from "react";

import { useParams } from "react-router-dom";

import { useEffect, useState } from "react";

const MainQuestionsWrapper = () => {

  const { subgodwin } = useParams();
  const { subs } = useContext(ActorContext);
  const [sub, setSub] = useState<Sub | undefined>(undefined);

  useEffect(() => {
    if (subgodwin !== undefined) {
      setSub(subs.get(subgodwin));
    }
  }, [subgodwin, subs]);
  
  return (
    ( sub === undefined ?
      <div>@todo: loading...</div> :
      <MainQuestions sub={sub}/>
    )
  );

}

export default MainQuestionsWrapper;