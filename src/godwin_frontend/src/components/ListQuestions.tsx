
import QuestionComponent from "./Question";
import { OrderBy, Direction, ScanLimitResult, _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";
import ActorContext from "../ActorContext"

import { useEffect, useState, useContext } from "react";
import { ActorSubclass } from "@dfinity/agent";

type Results = {
  ids: bigint[],
  next : bigint | undefined,
}

const fromQuery = (query_result: ScanLimitResult) => {
  let ids = Array.from(query_result.keys);
  let [next] = query_result.next;
  return { ids, next };
}

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

type ListQuestionsInput = {
  order_by: OrderBy,
  query_direction: Direction
}

const ListQuestions = ({order_by, query_direction}: ListQuestionsInput) => {

  const {actor} = useContext(ActorContext) as ActorContextValues;
  const [results, setResults] = useState<Results>({ ids : [], next: undefined});
  const [categories, setCategories] = useState<string[]>([]);
  const [trigger_next, setTriggerNext] = useState<boolean>(false);
	
  const refreshQuestions = async () => {
    let query_result : ScanLimitResult = await actor.getQuestions(order_by, query_direction, BigInt(10), []);
    setResults(fromQuery(query_result));
  };

  const refreshCategories = async () => {
    let query_categories : Array<string> = await actor.getCategories();
    setCategories(Array.from(query_categories));
  };

  const getNextQuestions = async () => {
    if (results.next !== undefined){
      let query_result : ScanLimitResult = await actor.getQuestions(order_by, query_direction, BigInt(10), [results.next]);
      let ids : bigint[] = [...new Set([...results.ids, ...Array.from(query_result.keys)])];
      let [next] = query_result.next;
      setResults({ ids, next });
    }
  };

  const atEnd = () => {
    var c = [document.scrollingElement.scrollHeight, document.body.scrollHeight, document.body.offsetHeight].sort(function(a,b){return b-a}) // select longest candidate for scrollable length
    return (window.innerHeight + window.scrollY + 2 >= c[0]) // compare with scroll position + some give
  }

  const scrolling = () => {
    if (atEnd()) {
      setTriggerNext(true);
    }
  }

  useEffect(() => {
    refreshCategories();
    refreshQuestions();
    window.addEventListener('scroll', scrolling, {passive: true});
    return () => {
      window.removeEventListener('scroll', scrolling);
    };
  }, []);

  useEffect(() => {
    if (trigger_next){
      setTriggerNext(false);
      getNextQuestions();
    };
  }, [trigger_next]);

	return (
		<div className="border border-none mx-96 my-16 justify-center">
      {[...results.ids].map(id => (
        <li className="list-none" key={Number(id)}> 
          <QuestionComponent question_id={id} categories={categories}> </QuestionComponent>
        </li>
      ))}
    </div>
	);
};

export default ListQuestions;
