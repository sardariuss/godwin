import QuestionsMain from "./MainQuestions";
import { Filter } from "./MainQuestions";
import { ActorContext } from "../ActorContext"

import { _SERVICE, Category, CategoryInfo } from "../../declarations/godwin_backend/godwin_backend.did";
import { ActorSubclass } from "@dfinity/agent";

import { useContext } from "react";

import { useParams } from "react-router-dom";

import { useEffect, useState } from "react";

const MainQuestionsWrapper = () => {

  const { subgodwin } = useParams();
  const { subs } = useContext(ActorContext);
  const [actor, setActor] = useState<ActorSubclass<_SERVICE> | undefined>();
  const [categories, setCategories] = useState<Map<Category, CategoryInfo>>(new Map<Category, CategoryInfo>());

  const getCategories = async () => {
    if (actor !== undefined){
      const array = await actor.getCategories();
      let map = new Map<Category, CategoryInfo>();
      array.forEach((category) => {
        map.set(category[0], category[1]);
      })
      setCategories(map);
    }
  }

  useEffect(() => {
    getCategories();
  }, [actor]);

  useEffect(() => {
    if (subgodwin !== undefined) {
      setActor(subs.get(subgodwin));
    }
  }, [subgodwin, subs]);
  
  return (
    ( actor === undefined ?
      <div>@todo: loading...</div> :
      <QuestionsMain actor={actor} categories={categories} filter={Filter.CANDIDATE} />
    )
  );

}

export default MainQuestionsWrapper;